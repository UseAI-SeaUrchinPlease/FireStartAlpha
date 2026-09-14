extends Node

const TEST_SAVE_PATH := "user://meta_test.json"

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	MetaProgress.save_path = TEST_SAVE_PATH
	MetaProgress.reset_progress()
	var start_wood: UnlockData = load("res://data/unlocks/start_wood.tres")
	var wood: ItemData = load("res://data/items/wood.tres")

	_check(MetaProgress.all_unlocks().size() == 3, "three unlocks are defined")
	_check(not MetaProgress.can_buy(start_wood), "nothing is affordable with no ash")

	MetaProgress.record_run(3)
	_check(MetaProgress.ash == 15 and MetaProgress.last_ash_gain == 15, "three days give 15 ash")
	_check(MetaProgress.best_day == 3, "best day is recorded")
	MetaProgress.record_run(1)
	_check(MetaProgress.best_day == 3, "a shorter run keeps the best day")

	_check(MetaProgress.buy_unlock(start_wood), "start_wood is affordable with 20 ash")
	_check(MetaProgress.ash == 15, "buying spends ash")
	_check(not MetaProgress.buy_unlock(start_wood), "an unlock cannot be bought twice")
	_check(MetaProgress.active_unlocks() == [start_wood], "active unlocks lists what was bought")

	MetaProgress.reset_progress()
	MetaProgress.load_from_disk()
	_check(MetaProgress.ash == 15 and MetaProgress.best_day == 3, "ash and best day survive a reload")
	_check(MetaProgress.is_unlocked(start_wood), "unlocks survive a reload")

	GameState.reset()
	GameState.apply_unlocks(MetaProgress.active_unlocks())
	_check(GameState.inventory.get(wood, 0) == 2, "start_wood grants two wood at run start")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	if _failures == 0:
		print("test_meta_progress: OK")
	get_tree().quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
