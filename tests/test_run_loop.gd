extends Node

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const TEST_SAVE_PATH := "user://meta_test.json"

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	MetaProgress.save_path = TEST_SAVE_PATH
	MetaProgress.reset_progress()
	var start_wood: UnlockData = load("res://data/unlocks/start_wood.tres")
	var wood: ItemData = load("res://data/items/wood.tres")

	add_child(MAIN_SCENE.instantiate())
	await get_tree().process_frame
	_check(PhaseManager.current_phase == PhaseManager.Phase.TITLE, "the game boots to the title")

	PhaseManager.current_scene().finish()
	await get_tree().process_frame
	_check(PhaseManager.current_phase == PhaseManager.Phase.DAY, "starting from the title enters day one")
	_check(GameState.day == 1 and GameState.inventory.is_empty(), "a fresh run starts empty")

	GameState.damage(GameState.hp)
	await get_tree().process_frame
	_check(PhaseManager.current_phase == PhaseManager.Phase.GAME_OVER, "dying leads to game over")
	_check(MetaProgress.ash == 5, "dying on day one grants 5 ash")

	PhaseManager.current_scene().finish()
	await get_tree().process_frame
	_check(PhaseManager.current_phase == PhaseManager.Phase.TITLE, "game over returns to the title")

	_check(MetaProgress.buy_unlock(start_wood), "the first run's ash buys the first unlock")
	PhaseManager.current_scene().finish()
	await get_tree().process_frame
	_check(PhaseManager.current_phase == PhaseManager.Phase.DAY, "a second run starts")
	_check(GameState.inventory.get(wood, 0) == 2, "the second run starts with the unlocked wood")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	if _failures == 0:
		print("test_run_loop: OK")
	get_tree().quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
