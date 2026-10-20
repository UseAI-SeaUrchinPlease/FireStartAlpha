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

	# フィールドが空(=歩いて行けるセルがない)なら、ブロックのないセルがあっても湧かない
	var day1_world: GameWorld = phase.get_node("%World")
	day1_world.flow_field = {}
	phase._spawn_enemy()
	_check(phase.enemy_count() == 2, "an enemy is never placed on a cell that cannot walk to the player")

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

	GameState.reset()
	GameState.day = 20
	phase = DAY_PHASE.instantiate()
	phase.map_seed = 12345 # 15体全てのスポーン成否が運任せにならないよう固定する
	add_child(phase)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(phase.enemy_count() == 20, "initial spawn is clamped to CAP_MAX on a late day instead of growing unbounded")
	var world: GameWorld = phase.get_node("%World")
	var all_reachable := true
	for child in world.get_children():
		if child is Enemy:
			all_reachable = all_reachable and world.flow_field.has(world.cell_at(child.global_position))
	_check(all_reachable, "enemies only spawn on cells that can walk to the player")

	var dug_cell := Vector2i(-1, -1)
	for cell: Vector2i in world.map.cells:
		var block := world.get_block(cell)
		var from_player: Vector2i = cell - world.cell_at(phase.get_node("%Player").global_position)
		var inside_radius: bool = absi(from_player.x) < phase._flow_field_radius and absi(from_player.y) < phase._flow_field_radius
		if inside_radius and block.hardness > 0.0 and world.flow_field.has(cell + Vector2i(1, 0)) and not world.flow_field.has(cell):
			dug_cell = cell
			break
	world.dig(dug_cell)
	await get_tree().create_timer(0.3).timeout
	_check(world.flow_field.has(dug_cell), "digging a block puts its cell into the flow field without the player moving")
	phase.queue_free()

	if _failures == 0:
		print("test_day_phase: OK")
	get_tree().quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
