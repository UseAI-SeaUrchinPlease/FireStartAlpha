extends Node

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const TEST_SAVE_PATH := "user://meta_test.json"
const PAUSE_CHECK := 0.3
const WAIT_AFTER_IGNITE := 2.5

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

	var day_scene := PhaseManager.current_scene() as DayPhase
	var day_world := day_scene.world
	day_scene.ignite_requested.emit()
	await get_tree().process_frame
	_check(PhaseManager.current_phase == PhaseManager.Phase.FIRE, "the ignition screen opens during the day")
	var time_left := day_scene.time_left()
	await get_tree().create_timer(PAUSE_CHECK).timeout
	_check(is_equal_approx(day_scene.time_left(), time_left), "the day timer stops while the ignition screen is open")

	_press(&"move_left")
	_press(&"interact")
	await get_tree().process_frame
	_check(PhaseManager.current_scene() == day_scene, "choosing 戻る with E resumes the same day")

	GameState.add_item(load("res://data/items/dry_grass.tres"), 2)
	GameState.add_item(load("res://data/items/flint.tres"), 1)
	GameState.add_item(wood, 1)
	var fire_spot := day_scene.player.global_position
	day_scene.ignite_requested.emit()
	await get_tree().process_frame
	(PhaseManager.current_scene() as FirePhase).ignite()
	await get_tree().create_timer(WAIT_AFTER_IGNITE).timeout
	_check(PhaseManager.current_phase == PhaseManager.Phase.NIGHT, "lighting the fire starts the night")
	var night := PhaseManager.current_scene() as NightPhase
	_check(night.world == day_world, "the night is spent on the day's map")
	_check(not is_instance_valid(day_scene), "the day scene is gone once the night starts")

	night.player.global_position = fire_spot + Vector2(night.barrier_radius * 3.0, 0.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(night.player.global_position.distance_to(fire_spot) <= night.barrier_radius + 0.01, "the player cannot leave the barrier")

	night.finish()
	await get_tree().process_frame
	_check(PhaseManager.current_phase == PhaseManager.Phase.UPGRADE, "the night leads to self-improvement")
	PhaseManager.current_scene().finish()
	await get_tree().process_frame
	_check(PhaseManager.current_phase == PhaseManager.Phase.DAY and GameState.day == 2, "passing the night starts the next day")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	if _failures == 0:
		print("test_run_loop: OK")
	get_tree().quit(1 if _failures > 0 else 0)


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
