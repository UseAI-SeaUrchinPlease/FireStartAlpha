extends Node

const DAY_PHASE := preload("res://scenes/phases/DayPhase.tscn")

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	GameState.reset()
	var phase := DAY_PHASE.instantiate()
	var outcome := [""]
	phase.finished.connect(func() -> void: outcome[0] = "finished")
	phase.failed.connect(func() -> void: outcome[0] = "failed")
	add_child(phase)
	await get_tree().physics_frame
	await get_tree().physics_frame

	_check(phase.enemy_count() == 2, "day 1 starts with two enemies")
	_check(outcome[0] == "", "the phase is still running after spawning")

	GameState.damage(GameState.hp)
	_check(outcome[0] == "failed", "reaching 0 HP fails the phase")
	phase.queue_free()

	GameState.reset()
	GameState.day = 3
	phase = DAY_PHASE.instantiate()
	add_child(phase)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(phase.enemy_count() == 4, "day 3 starts with four enemies")
	phase.queue_free()

	if _failures == 0:
		print("test_day_phase: OK")
	get_tree().quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
