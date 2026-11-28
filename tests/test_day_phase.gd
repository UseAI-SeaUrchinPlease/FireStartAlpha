extends Node

const DAY_PHASE := preload("res://scenes/phases/DayPhase.tscn")
const SHORT_DAY := 0.2

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	GameState.reset()
	var phase: DayPhase = DAY_PHASE.instantiate()
	var outcome := [""]
	phase.finished.connect(func() -> void: outcome[0] = "finished")
	phase.failed.connect(func() -> void: outcome[0] = "failed")
	phase.ignite_requested.connect(func() -> void: outcome[0] = "ignite")
	add_child(phase)
	await get_tree().physics_frame
	await get_tree().physics_frame

	_check(_enemy_count(phase) == 0, "no enemies appear during the day")
	_check(outcome[0] == "", "the phase is still running")

	var press := InputEventAction.new()
	press.action = &"interact"
	press.pressed = true
	get_viewport().push_input(press)
	await get_tree().process_frame
	_check(outcome[0] == "ignite", "pressing interact asks to open the ignition screen")

	GameState.damage(GameState.hp)
	_check(outcome[0] == "failed", "reaching 0 HP fails the phase")
	phase.queue_free()

	GameState.reset()
	phase = DAY_PHASE.instantiate()
	phase.day_duration = SHORT_DAY
	outcome[0] = ""
	phase.finished.connect(func() -> void: outcome[0] = "finished")
	add_child(phase)
	await get_tree().create_timer(SHORT_DAY * 2.0).timeout
	_check(outcome[0] == "finished", "sunset finishes the day")
	phase.queue_free()

	if _failures == 0:
		print("test_day_phase: OK")
	get_tree().quit(1 if _failures > 0 else 0)


func _enemy_count(phase: DayPhase) -> int:
	var count := 0
	for child in phase.world.get_children():
		if child is Enemy:
			count += 1
	return count


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
