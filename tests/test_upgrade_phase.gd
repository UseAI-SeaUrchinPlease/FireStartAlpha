extends Node

const UPGRADE_PHASE := preload("res://scenes/phases/UpgradePhase.tscn")

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	var hp: UpgradeData = load("res://data/upgrades/hp.tres")
	var attack: UpgradeData = load("res://data/upgrades/attack.tres")
	var dig: UpgradeData = load("res://data/upgrades/dig.tres")
	var rest: UpgradeData = load("res://data/upgrades/rest.tres")
	var tool: UpgradeData = load("res://data/upgrades/tool.tres")

	GameState.reset()
	GameState.fire_points = 4
	_check(GameState.buy_upgrade(hp), "hp upgrade is affordable with 4 points")
	_check(GameState.fire_points == 2, "buying spends the cost")
	_check(GameState.max_hp == 12 and GameState.hp == 12, "hp upgrade raises max HP and current HP")
	_check(not GameState.buy_upgrade(attack), "attack upgrade costs more than the remaining points")

	GameState.damage(5)
	_check(GameState.buy_upgrade(rest), "rest is affordable")
	_check(GameState.hp == 10, "rest heals 3")
	_check(GameState.buy_upgrade(rest), "rest can be bought again")

	GameState.fire_points = 100
	for i in 3:
		GameState.buy_upgrade(attack)
	_check(not GameState.buy_upgrade(attack), "attack stops at its max level")
	_check(GameState.attack_damage() == 4, "three attack levels give 4 damage")
	GameState.buy_upgrade(dig)
	_check(is_equal_approx(GameState.dig_speed_multiplier(), 1.25), "one dig level gives a 1.25x multiplier")
	_check(GameState.tool_level() == 0, "the run starts without a tool level")
	GameState.buy_upgrade(tool)
	GameState.buy_upgrade(tool)
	_check(GameState.tool_level() == 2, "two tool levels give tool level 2")
	_check(not GameState.buy_upgrade(tool), "the tool stops at its max level")

	GameState.reset()
	GameState.fire_points = 4
	var phase := UPGRADE_PHASE.instantiate()
	var outcome := [""]
	phase.finished.connect(func() -> void: outcome[0] = "finished")
	add_child(phase)
	await get_tree().process_frame
	_check(phase.row_count() == 6, "five upgrades plus the next-day row are listed")
	var upcoming: Label = phase.get_node("%UpcomingLabel")
	_check(upcoming.visible and "3日目から 白樺の樹皮 ×1" in upcoming.text, "the upgrade screen previews the next requirement change")
	_check(not "つるはし" in upcoming.text and not "道具" in upcoming.text, "the preview does not reveal the tool needed")
	phase.set_focus(phase.row_count() - 1)
	phase.activate_focused()
	_check(outcome[0] == "finished", "activating the next-day row finishes the phase")
	phase.queue_free()

	GameState.reset()
	GameState.day = 4
	phase = UPGRADE_PHASE.instantiate()
	add_child(phase)
	await get_tree().process_frame
	upcoming = phase.get_node("%UpcomingLabel")
	_check("着火: 5日目から 鉄片 ×1" in upcoming.text and "燃料: 7日目から 松やにの木片 ×1" in upcoming.text, "the preview shows the next change of each role")
	phase.queue_free()

	GameState.reset()
	GameState.day = 11
	phase = UPGRADE_PHASE.instantiate()
	add_child(phase)
	await get_tree().process_frame
	_check(not phase.get_node("%UpcomingLabel").visible, "the preview hides itself once nothing changes anymore")
	phase.queue_free()

	if _failures == 0:
		print("test_upgrade_phase: OK")
	get_tree().quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
