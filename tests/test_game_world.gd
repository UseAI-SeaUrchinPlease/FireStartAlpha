extends Node

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const WALL_ROW_Y := 4
const GAP_X := 4
const GOAL_CELL := Vector2i(4, 1)
const NEAR_CELL := Vector2i(4, 2)
const FAR_CELL := Vector2i(1, 7)
const BOXED_CELL := Vector2i(7, 7)

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	var world: GameWorld = WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	world.build(_build_test_map())

	var wide_field := world.compute_flow_field(GOAL_CELL, 20)
	_check(
		_walk_to_goal(world, wide_field, FAR_CELL, GOAL_CELL),
		"flow field routes around the wall through the gap instead of walking into a block"
	)
	_check(not wide_field.has(BOXED_CELL), "a cell fully enclosed by blocks has no direction (unreachable)")

	var narrow_field := world.compute_flow_field(GOAL_CELL, 2)
	_check(narrow_field.has(NEAR_CELL), "a cell within the radius is included in the field")
	_check(not narrow_field.has(FAR_CELL), "a cell beyond the radius is excluded from the field")

	if _failures == 0:
		print("test_game_world: OK")
	get_tree().quit(1 if _failures > 0 else 0)


## 縦に長いマップの中央 (y=WALL_ROW_Y) を、GAP_X の1マスだけ空けて岩の壁で
## 仕切る。GOAL_CELL は壁の上側の隙間の近く、FAR_CELL は壁の下側かつ
## 隙間から離れた位置に置き、直進では壁にぶつかる状況を作る。
## BOXED_CELL は四方を岩で囲み、どこからも到達できないセルにする。
func _build_test_map() -> MapData:
	var map := MapData.new()
	map.width = 10
	map.height = 10
	map.spawn_cell = GOAL_CELL
	for x in range(1, 8):
		if x != GAP_X:
			map.cells[Vector2i(x, WALL_ROW_Y)] = &"rock"
	for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		map.cells[BOXED_CELL + offset] = &"rock"
	return map


## フィールドに従って start から goal まで実際に1マスずつ進み、途中で
## ブロックの上に乗ることなく goal に到達できるかを検証する。
func _walk_to_goal(world: GameWorld, field: Dictionary, start: Vector2i, goal: Vector2i) -> bool:
	var current := start
	for i in world.map.width * world.map.height:
		if current == goal:
			return true
		if not field.has(current):
			return false
		var block := world.get_block(current)
		if block != null and block.blocks_movement():
			return false
		current += Vector2i(field[current])
	return false


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
