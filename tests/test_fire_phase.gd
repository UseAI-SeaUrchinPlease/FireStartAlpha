extends Node

const FIRE_PHASE := preload("res://scenes/phases/FirePhase.tscn")
const WAIT_AFTER_IGNITE := 2.5

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	var wood: ItemData = load("res://data/items/wood.tres")
	var dry_grass: ItemData = load("res://data/items/dry_grass.tres")
	var flint: ItemData = load("res://data/items/flint.tres")

	GameState.reset()
	GameState.add_item(wood, 3)
	GameState.add_item(dry_grass, 2)
	GameState.add_item(flint, 1)
	var outcome := await _ignite(FIRE_PHASE.instantiate())
	_check(outcome == "finished", "enough heat lights the fire and finishes the phase")
	_check(GameState.fire_points == 4, "130 degrees against a 100 target gives 4 points")
	_check(GameState.inventory.is_empty(), "everything thrown in is consumed")

	GameState.reset()
	GameState.add_item(wood, 1)
	outcome = await _ignite(FIRE_PHASE.instantiate())
	_check(outcome == "failed", "at sunset, a fire that cannot reach the cutoff even with everything fails")

	_fill(wood, dry_grass, flint)
	var phase: FirePhase = FIRE_PHASE.instantiate()
	phase.can_cancel = true
	var result := _watch(phase)
	add_child(phase)
	for i in 3:
		_press(&"move_down")
	phase.ignite()
	await get_tree().create_timer(WAIT_AFTER_IGNITE).timeout
	_check(result[0] == "", "during the day, a fire below the cutoff cannot be lit")
	_check(GameState.inventory.get(wood, 0) == 3, "a blocked fire uses nothing up")
	for i in 3:
		_hold_up()
	phase.ignite()
	await get_tree().create_timer(WAIT_AFTER_IGNITE).timeout
	_check(result[0] == "finished", "holding up adds the wood back and the fire lights")
	phase.queue_free()

	_fill(wood, dry_grass, flint)
	phase = FIRE_PHASE.instantiate()
	result = _watch(phase)
	add_child(phase)
	for i in 3:
		_press(&"move_down")
	phase.ignite()
	await get_tree().create_timer(WAIT_AFTER_IGNITE).timeout
	_check(result[0] == "", "at sunset, a fire that could reach the cutoff is blocked instead of failing")
	phase.queue_free()

	phase = FIRE_PHASE.instantiate()
	phase.can_cancel = true
	var cancelled := [false]
	phase.cancelled.connect(func() -> void: cancelled[0] = true)
	add_child(phase)
	phase.cancel()
	_check(cancelled[0], "an ignition opened during the day can go back")
	phase.queue_free()

	phase = FIRE_PHASE.instantiate()
	cancelled[0] = false
	phase.cancelled.connect(func() -> void: cancelled[0] = true)
	add_child(phase)
	phase.cancel()
	_check(not cancelled[0], "an ignition forced by sunset cannot go back")
	phase.queue_free()

	if _failures == 0:
		print("test_fire_phase: OK")
	get_tree().quit(1 if _failures > 0 else 0)


func _fill(wood: ItemData, dry_grass: ItemData, flint: ItemData) -> void:
	GameState.reset()
	GameState.add_item(wood, 3)
	GameState.add_item(dry_grass, 2)
	GameState.add_item(flint, 1)


func _watch(phase: GamePhase) -> Array:
	var result := [""]
	phase.finished.connect(func() -> void: result[0] = "finished")
	phase.failed.connect(func() -> void: result[0] = "failed")
	return result


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event)


# A held key arrives as repeated echo events.
func _hold_up() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_UP
	event.pressed = true
	event.echo = true
	get_viewport().push_input(event)


func _ignite(phase: GamePhase) -> String:
	var outcome := [""]
	phase.finished.connect(func() -> void: outcome[0] = "finished")
	phase.failed.connect(func() -> void: outcome[0] = "failed")
	add_child(phase)
	phase.ignite()
	await get_tree().create_timer(WAIT_AFTER_IGNITE).timeout
	phase.queue_free()
	return outcome[0]


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
