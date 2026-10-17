extends Node

const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	var zombie := _spawn(load("res://data/enemies/zombie.tres"))
	zombie.take_damage(1, Vector2.LEFT)
	_check(zombie._knockback_left > 0.0, "a zombie is knocked back by every hit")

	var brute := _spawn(load("res://data/enemies/brute.tres"))
	brute.take_damage(1, Vector2.LEFT)
	_check(brute._knockback_left == 0.0, "a brute is not knocked back by the first hit")
	brute.take_damage(1, Vector2.LEFT)
	_check(brute._knockback_left > 0.0, "a brute is knocked back once it has lost enough HP")
	brute._knockback_left = 0.0
	brute.take_damage(1, Vector2.LEFT)
	_check(brute._knockback_left == 0.0, "the brute's damage count starts over after a knockback")

	if _failures == 0:
		print("test_enemy_knockback: OK")
	get_tree().quit(1 if _failures > 0 else 0)


func _spawn(data: EnemyData) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	add_child(enemy)
	return enemy


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
