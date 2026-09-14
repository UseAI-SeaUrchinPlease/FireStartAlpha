extends Node

const FIRE_PHASE := preload("res://scenes/phases/FirePhase.tscn")
const WAIT_AFTER_IGNITE := 2.0

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
	_check(outcome == "failed", "fuel alone cannot light the fire and fails the phase")

	if _failures == 0:
		print("test_fire_phase: OK")
	get_tree().quit(1 if _failures > 0 else 0)


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
