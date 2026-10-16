extends Node

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	GameState.reset()
	var world: GameWorld = WORLD_SCENE.instantiate()
	add_child(world)
	world.set_physics_process(false) # 時間はテストから clock で進める
	var map := MapData.new()
	map.width = 12
	map.height = 6
	var tree := Vector2i(1, 1)
	var other_tree := Vector2i(2, 1)
	var ore := Vector2i(3, 1)
	var wall := Vector2i(4, 1)
	map.cells = {tree: &"tree", other_tree: &"tree", ore: &"iron_ore", wall: &"wall"}
	world.build(map)
	var tree_hits := world.get_block(tree).hits
	var dug: Array[Vector2i] = []
	world.block_dug.connect(func(cell: Vector2i, _block: BlockData) -> void: dug.append(cell))

	for i in tree_hits - 1:
		world.hit(tree, 0)
	_check(world.hit_count(tree) == tree_hits - 1, "each hit adds one to the cell's count")
	_check(world.get_block(tree) != null and dug.is_empty(), "the block survives until the last hit")
	_check(world.hit(tree, 0) == GameWorld.HitResult.BROKEN, "the hit reaching the block's count breaks it")
	_check(world.get_block(tree) == null and dug == [tree], "breaking removes the block and reports it")

	world.hit(other_tree, 0)
	world.hit(other_tree, 0)
	world.hit(ore, 1)
	_check(world.hit_count(other_tree) == 2, "hitting another cell keeps the first cell's count")
	world.clock += GameWorld.HIT_RESET_TIME - 0.1
	_check(world.hit_count(other_tree) == 2, "the count is kept while the reset time has not passed")
	world.clock += 0.2
	_check(world.hit_count(other_tree) == 0, "the count resets after the reset time without hits")
	world.hit(other_tree, 0)
	_check(world.hit_count(other_tree) == 1, "hitting again after a reset starts from one")

	_check(world.hit(ore, 0) == GameWorld.HitResult.BLOCKED, "a block needing a better tool is blocked")
	world.clock += GameWorld.HIT_RESET_TIME + 1.0
	world.hit(ore, 0)
	_check(world.hit_count(ore) == 0, "a blocked hit does not count")
	_check(world.hit(ore, 1) == GameWorld.HitResult.HIT, "the required tool level lets the hit through")
	_check(world.hit(wall, 99) == GameWorld.HitResult.NONE, "walls can never be dug")

	await _check_auto_repeat(world)

	if _failures == 0:
		print("test_digging: OK")
	get_tree().quit(1 if _failures > 0 else 0)


## 押しっぱなしで一定間隔ごとに叩き、連打してもその間隔より速くならないこと。
func _check_auto_repeat(world: GameWorld) -> void:
	var target := Vector2i(6, 3)
	world.map.cells[target] = &"rock"
	world.build(world.map)
	var player: Player = PLAYER_SCENE.instantiate()
	player.world = world
	world.add_child(player)
	player.global_position = world.cell_center(target + Vector2i(0, 1))
	player.set("_facing", Vector2.UP)

	# 0.3秒間隔で約0.42秒押し続けると、押した瞬間と0.3秒後の2回叩く
	Input.action_press("dig")
	await _frames(25)
	Input.action_release("dig")
	_check(world.hit_count(target) == 2, "holding dig hits once at once and again every interval (got %d)" % world.hit_count(target))

	world.clock += GameWorld.HIT_RESET_TIME + 1.0
	await _frames(20)
	for i in 10:
		Input.action_press("dig")
		await _frames(1)
		Input.action_release("dig")
		await _frames(1)
	var mashed := world.hit_count(target)
	_check(mashed >= 1 and mashed <= 2, "mashing for about 0.33 seconds is no faster than holding (got %d)" % mashed)

	var dig: UpgradeData = load("res://data/upgrades/dig.tres")
	GameState.upgrades[dig] = 4
	world.clock += GameWorld.HIT_RESET_TIME + 1.0
	await _frames(20)
	Input.action_press("dig")
	await _frames(25)
	Input.action_release("dig")
	_check(world.hit_count(target) == 3, "max dig speed halves the interval (got %d)" % world.hit_count(target))
	GameState.upgrades.clear()
	player.queue_free()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
