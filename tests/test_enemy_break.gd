extends Node

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	var map := MapData.new()
	map.width = 8
	map.height = 3
	for x in map.width:
		for y in map.height:
			map.ground[Vector2i(x, y)] = &"grass_floor"
	map.cells[Vector2i(4, 1)] = &"rock"
	map.cells[Vector2i(4, 0)] = &"rock"
	map.cells[Vector2i(4, 2)] = &"rock"
	var world: GameWorld = WORLD_SCENE.instantiate()
	add_child(world)
	world.build(map)

	var bait := Node2D.new()
	world.add_child(bait)
	bait.global_position = world.cell_center(Vector2i(7, 1))
	var brute := _spawn(world, bait, load("res://data/enemies/brute.tres"), Vector2i(2, 1))
	var zombie := _spawn(world, bait, load("res://data/enemies/zombie.tres"), Vector2i(2, 0))
	for i in 600:
		await get_tree().physics_frame
	_check(world.get_block(Vector2i(4, 1)) == null, "a brute breaks the block in its way")
	_check(world.get_block(Vector2i(4, 0)) == null and world.get_block(Vector2i(4, 2)) == null, "a brute also breaks the blocks around it")
	_check(brute.global_position.x > world.cell_center(Vector2i(4, 1)).x, "the brute walks through the gap")
	_check(zombie.global_position.x > 0.0, "a zombie is spawned for comparison")

	map.cells[Vector2i(4, 1)] = &"rock"
	world.build(map)
	var plain := _spawn(world, bait, load("res://data/enemies/zombie.tres"), Vector2i(2, 1))
	for i in 300:
		await get_tree().physics_frame
	_check(world.get_block(Vector2i(4, 1)) != null, "a zombie does not break blocks")
	_check(plain.global_position.x < world.cell_center(Vector2i(4, 1)).x, "the zombie stays behind the block")

	if _failures == 0:
		print("test_enemy_break: OK")
	get_tree().quit(1 if _failures > 0 else 0)


func _spawn(world: GameWorld, target: Node2D, data: EnemyData, cell: Vector2i) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.target = target
	enemy.world = world
	enemy.position = world.cell_center(cell)
	world.add_child(enemy)
	return enemy


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
