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

var map: MapData
## 叩いた回数の期限切れ判定に使う経過秒数。テストから時間を進められるよう公開している。
var clock := 0.0

var _blocks_by_id: Dictionary[StringName, BlockData] = {}
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


func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map.width and cell.y < map.height


func cell_at(world_position: Vector2) -> Vector2i:
	return _blocks.local_to_map(_blocks.to_local(world_position))


func cell_center(cell: Vector2i) -> Vector2:
	return _blocks.to_global(_blocks.map_to_local(cell))


func pixel_size() -> Vector2:
	return Vector2(map.width, map.height) * TILE_SIZE
