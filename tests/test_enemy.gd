extends Node

const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")
const ZOMBIE_DATA: EnemyData = preload("res://data/enemies/zombie.tres")

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

	if _failures == 0:
		print("test_enemy: OK")
	get_tree().quit(1 if _failures > 0 else 0)


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
