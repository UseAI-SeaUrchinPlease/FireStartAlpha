class_name GameWorld
extends Node2D

signal block_dug(cell: Vector2i, block: BlockData)

enum HitResult { NONE, BLOCKED, HIT, BROKEN }

const TILE_SIZE := 16
const HIT_RESET_TIME := 2.0
const GROUND_ATLAS: Dictionary[StringName, Vector2i] = {
	&"grass_floor": Vector2i(0, 0),
	&"dirt_floor": Vector2i(1, 0),
}

const FLOW_FIELD_DIRECTIONS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## 次に進むセルの候補。4方向 + 斜め。セルごとに配列を作り直さないよう定数にしている。
const FLOW_FIELD_NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]
const DEBUG_ARROW_COLOR := Color(1.0, 0.2, 0.8, 0.8)

## エディタでオンにすると、フローフィールドの向きを各マスに矢印で描く(デバッグ用)。
@export var debug_draw_flow_field := false

var map: MapData
## プレイヤー中心のフローフィールド。DayPhase が定期的に計算して更新する
## (敵ごとに経路探索すると数が増えた時に重くなるため、1つだけ計算して
## 全敵で共有する。issue #7)。セルごとに、次に進む隣のセルへのオフセットを持つ。
var flow_field: Dictionary[Vector2i, Vector2i] = {}:
	set(value):
		flow_field = value
		if _debug_layer != null:
			_debug_layer.queue_redraw()
## 叩いた回数の期限切れ判定に使う経過秒数。テストから時間を進められるよう公開している。
var clock := 0.0

var _blocks_by_id: Dictionary[StringName, BlockData] = {}
var _debug_layer: Node2D
## 叩いた回数はマスごとに持ち、最後に叩いてから HIT_RESET_TIME 経つと 0 に戻す。
## 別のマスに移っても時間内に戻れば続きから掘れる (DEVELOPMENT.md 8.5)。
var _hits: Dictionary[Vector2i, int] = {}
var _last_hit_at: Dictionary[Vector2i, float] = {}

@onready var _ground: TileMapLayer = %Ground
@onready var _blocks: TileMapLayer = %Blocks


func _ready() -> void:
	for resource in DataDir.load_all("res://data/blocks"):
		var block := resource as BlockData
		_blocks_by_id[block.id] = block
	if debug_draw_flow_field:
		_debug_layer = Node2D.new()
		_debug_layer.z_index = 100
		_debug_layer.draw.connect(_draw_flow_field)
		add_child(_debug_layer)


func _physics_process(delta: float) -> void:
	clock += delta


func build(map_data: MapData) -> void:
	map = map_data
	_ground.clear()
	_blocks.clear()
	for cell: Vector2i in map.ground:
		_ground.set_cell(cell, 0, GROUND_ATLAS[map.ground[cell]])
	for cell: Vector2i in map.cells:
		_blocks.set_cell(cell, 0, _blocks_by_id[map.cells[cell]].atlas_coords)


func get_block(cell: Vector2i) -> BlockData:
	var id: StringName = map.cells.get(cell, &"")
	return _blocks_by_id.get(id)


func hit(cell: Vector2i, tool_level: int) -> HitResult:
	var block := get_block(cell)
	if block == null or block.hits <= 0:
		return HitResult.NONE
	if block.required_tool_level > tool_level:
		return HitResult.BLOCKED
	var count := hit_count(cell) + 1
	if count >= block.hits:
		dig(cell)
		return HitResult.BROKEN
	_hits[cell] = count
	_last_hit_at[cell] = clock
	return HitResult.HIT


func hit_count(cell: Vector2i) -> int:
	if not _last_hit_at.has(cell) or clock - _last_hit_at[cell] > HIT_RESET_TIME:
		return 0
	return _hits[cell]


func dig(cell: Vector2i) -> void:
	var block := get_block(cell)
	if block == null:
		return
	map.cells.erase(cell)
	_hits.erase(cell)
	_last_hit_at.erase(cell)
	_blocks.erase_cell(cell)
	block_dug.emit(cell, block)


## Removes a block without emitting block_dug, so nothing drops.
func remove_block(cell: Vector2i) -> void:
	map.cells.erase(cell)
	_hits.erase(cell)
	_last_hit_at.erase(cell)
	_blocks.erase_cell(cell)


func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map.width and cell.y < map.height


func cell_at(world_position: Vector2) -> Vector2i:
	return _blocks.local_to_map(_blocks.to_local(world_position))


func cell_center(cell: Vector2i) -> Vector2:
	return _blocks.to_global(_blocks.map_to_local(cell))


func pixel_size() -> Vector2:
	return Vector2(map.width, map.height) * TILE_SIZE


## goal_cell を起点にBFS(4方向)でコスト場を作り、各セルから見て
## ゴールに最も近づく隣接セル(斜めを含む)へのオフセットを返す。
## radius は goal_cell からのタイル数(正方形範囲)で、マップ全体を毎回舐めないための範囲制限。
##
## 距離は4方向で測るので、斜めの隣は「2歩先」になり、斜めに進めるときは自然に斜めが選ばれる
## (L字のカクカクした動きを避ける)。角をかすめて障害物に引っかからないよう、
## 斜めは両脇の2マスがどちらも通れるときだけ許す (PR #11 レビュー)。
func compute_flow_field(goal_cell: Vector2i, radius: int) -> Dictionary[Vector2i, Vector2i]:
	var distances: Dictionary[Vector2i, int] = {goal_cell: 0}
	var queue: Array[Vector2i] = [goal_cell]
	var head := 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		for dir in FLOW_FIELD_DIRECTIONS:
			var neighbor := current + dir
			if distances.has(neighbor) or not contains(neighbor):
				continue
			if absi(neighbor.x - goal_cell.x) > radius or absi(neighbor.y - goal_cell.y) > radius:
				continue
			var block := get_block(neighbor)
			if block != null and block.blocks_movement():
				continue
			distances[neighbor] = distances[current] + 1
			queue.append(neighbor)

	var field: Dictionary[Vector2i, Vector2i] = {}
	for cell: Vector2i in distances:
		if cell == goal_cell:
			continue
		var best_step := Vector2i.ZERO
		var best_distance: int = distances[cell]
		for dir in FLOW_FIELD_NEIGHBORS:
			var neighbor := cell + dir
			if not distances.has(neighbor) or distances[neighbor] >= best_distance:
				continue
			if dir.x != 0 and dir.y != 0:
				if not distances.has(cell + Vector2i(dir.x, 0)) or not distances.has(cell + Vector2i(0, dir.y)):
					continue
			best_distance = distances[neighbor]
			best_step = dir
		if best_step != Vector2i.ZERO:
			field[cell] = best_step
	return field


func _draw_flow_field() -> void:
	for cell: Vector2i in flow_field:
		var from := cell_center(cell)
		var to := from + Vector2(flow_field[cell]).normalized() * TILE_SIZE * 0.4
		_debug_layer.draw_line(from, to, DEBUG_ARROW_COLOR, 1.0)
		_debug_layer.draw_circle(to, 1.5, DEBUG_ARROW_COLOR)
