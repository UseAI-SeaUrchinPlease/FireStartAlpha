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
	var birch_bark: ItemData = load("res://data/items/birch_bark.tres")

	GameState.reset()
	GameState.add_item(wood, 5)
	GameState.add_item(dry_grass, 2)
	GameState.add_item(flint, 1)
	var phase := FIRE_PHASE.instantiate()
	add_child(phase)
	_check(phase.row_count() == 3, "every owned fire item gets its own row")
	_check(phase.row_item(0) == wood and phase.row_item(1) == dry_grass and phase.row_item(2) == flint, "rows list fuel first, then igniters from the weakest")
	remove_child(phase)
	var outcome := await _ignite(phase)
	_check(outcome == "finished", "meeting the requirement and the target lights the fire")
	_check(GameState.fire_points == 3, "135 degrees against a 100 target gives 3 points")
	_check(GameState.inventory.is_empty(), "everything thrown in is consumed")

	GameState.reset()
	GameState.add_item(wood, 10)
	outcome = await _ignite(FIRE_PHASE.instantiate())
	_check(outcome == "failed", "fuel alone misses the igniter requirement even above the target")

	GameState.reset()
	GameState.add_item(wood, 1)
	GameState.add_item(flint, 1)
	outcome = await _ignite(FIRE_PHASE.instantiate())
	_check(outcome == "failed", "meeting the requirement but missing the target fails")

	GameState.reset()
	GameState.day = 3
	GameState.add_item(wood, 10)
	GameState.add_item(flint, 2)
	outcome = await _ignite(FIRE_PHASE.instantiate())
	_check(outcome == "failed", "on day 3 a plain igniter no longer satisfies the birch bark requirement")

	GameState.reset()
	GameState.day = 3
	GameState.add_item(wood, 10)
	GameState.add_item(birch_bark, 1)
	outcome = await _ignite(FIRE_PHASE.instantiate())
	_check(outcome == "finished", "on day 3 birch bark and three wood light a fire above the target")

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
