extends Node

const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")
const ZOMBIE_DATA: EnemyData = preload("res://data/enemies/zombie.tres")
const WORLD_SCENE := preload("res://scenes/world/World.tscn")

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	GameState.reset()
	var day1 := await _spawn()
	_check(day1._hp == ZOMBIE_DATA.max_hp, "day 1 has the base HP")
	_check(day1._damage == ZOMBIE_DATA.damage, "day 1 has the base damage")
	_check(is_equal_approx(day1._speed, ZOMBIE_DATA.speed), "day 1 has the base speed")
	day1.queue_free()

	GameState.day = 5
	var day5 := await _spawn()
	var offset := 4
	_check(
		day5._hp == int(ZOMBIE_DATA.max_hp + ZOMBIE_DATA.hp_growth_per_day * offset),
		"hp grows with days elapsed"
	)
	_check(
		day5._damage == int(ZOMBIE_DATA.damage + ZOMBIE_DATA.damage_growth_per_day * offset),
		"damage grows with days elapsed"
	)
	_check(
		is_equal_approx(day5._speed, ZOMBIE_DATA.speed + ZOMBIE_DATA.speed_growth_per_day * offset),
		"speed grows with days elapsed"
	)
	day5.queue_free()

	GameState.day = 50
	var day50 := await _spawn()
	_check(
		is_equal_approx(day50._speed, ZOMBIE_DATA.max_speed),
		"speed growth is capped at max_speed on a very late day"
	)
	day50.queue_free()

	await _check_steering()

	if _failures == 0:
		print("test_enemy: OK")
	get_tree().quit(1 if _failures > 0 else 0)


## 次のセルの中心へ向かうので、列の中心からずれていれば戻る成分を持つこと。
func _check_steering() -> void:
	GameState.reset()
	var world: GameWorld = WORLD_SCENE.instantiate()
	add_child(world)
	var map := MapData.new()
	map.width = 10
	map.height = 5
	world.build(map)
	var target := Node2D.new()
	world.add_child(target)
	target.global_position = world.cell_center(Vector2i(8, 2))
	world.flow_field = world.compute_flow_field(Vector2i(8, 2), 10)

	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = ZOMBIE_DATA
	enemy.target = target
	enemy.world = world
	world.add_child(enemy)
	enemy.set_physics_process(false)
	await get_tree().process_frame
	enemy.global_position = world.cell_center(Vector2i(3, 2)) + Vector2(0.0, 5.0)
	var velocity := enemy._compute_velocity()
	_check(velocity.x > 0.0 and velocity.y < 0.0, "an enemy off its row's center steers back toward it while moving along the row (got %s)" % velocity)
	_check(is_equal_approx(velocity.length(), enemy._speed), "steering keeps the enemy's speed")

	enemy.global_position = world.cell_center(Vector2i(8, 2)) + Vector2(-6.0, 0.0)
	velocity = enemy._compute_velocity()
	_check(velocity.x > 0.0 and is_zero_approx(velocity.y), "in the player's own cell the enemy heads straight for the player (got %s)" % velocity)
	world.queue_free()


func _spawn() -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = ZOMBIE_DATA
	add_child(enemy)
	await get_tree().process_frame
	return enemy


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
