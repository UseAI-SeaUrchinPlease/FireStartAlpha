class_name MapGenerator
extends RefCounted

const FOREST_FREQUENCY := 0.08
const FOREST_THRESHOLD := 0.25
const ROCK_FREQUENCY := 0.12
const ROCK_THRESHOLD := 0.4
const DIRT_FREQUENCY := 0.05
const DIRT_THRESHOLD := 0.3
const GRASS_TUFT_CHANCE := 0.04
const SPAWN_CLEARANCE := 3


## variants はレアブロック(replaces を持つ BlockData)、minimums はブロック id ごとの
## 最低保証数。どちらも火起こしのデータからは独立している (DEVELOPMENT.md 8.3)。
static func generate(map_seed: int, width: int, height: int, variants: Array[BlockData] = [], minimums: Dictionary[StringName, int] = {}) -> MapData:
	var forest := _noise(map_seed, FOREST_FREQUENCY)
	var rocks := _noise(map_seed + 1, ROCK_FREQUENCY)
	var dirt := _noise(map_seed + 2, DIRT_FREQUENCY)
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed

	var data := MapData.new()
	data.width = width
	data.height = height
	data.spawn_cell = Vector2i(Vector2(width, height) * 0.5)

	for y in height:
		for x in width:
			var cell := Vector2i(x, y)
			data.ground[cell] = &"dirt_floor" if dirt.get_noise_2d(x, y) > DIRT_THRESHOLD else &"grass_floor"
			var tuft := rng.randf() < GRASS_TUFT_CHANCE
			if x == 0 or y == 0 or x == width - 1 or y == height - 1:
				data.cells[cell] = &"wall"
			elif cell.distance_to(data.spawn_cell) <= SPAWN_CLEARANCE:
				continue
			elif forest.get_noise_2d(x, y) > FOREST_THRESHOLD:
				data.cells[cell] = &"tree"
			elif rocks.get_noise_2d(x, y) > ROCK_THRESHOLD:
				data.cells[cell] = &"rock"
			elif tuft:
				data.cells[cell] = &"grass"
	_apply_variants(data, variants, rng)
	_apply_minimums(data, variants, minimums, rng)
	return data


## 1マスにつき乱数を1回引き、候補の確率を累積してどれに置き換えるかを決める。
static func _apply_variants(data: MapData, variants: Array[BlockData], rng: RandomNumberGenerator) -> void:
	var by_base: Dictionary[StringName, Array] = {}
	for variant in variants:
		by_base.get_or_add(variant.replaces, []).append(variant)
	for cell: Vector2i in data.cells:
		var candidates: Array = by_base.get(data.cells[cell], [])
		if candidates.is_empty():
			continue
		var roll := rng.randf()
		var cumulative := 0.0
		for variant: BlockData in candidates:
			cumulative += variant.replace_chance
			if roll < cumulative:
				data.cells[cell] = variant.id
				break


## 足りないレアブロックは置き換え元から、普通のブロックは空き地から補う。
## レアブロックを先に補うのは、置き換えで置き換え元の数が減っても後で補えるようにするため。
static func _apply_minimums(data: MapData, variants: Array[BlockData], minimums: Dictionary[StringName, int], rng: RandomNumberGenerator) -> void:
	var base_of: Dictionary[StringName, StringName] = {}
	for variant in variants:
		base_of[variant.id] = variant.replaces
	var ids: Array[StringName] = minimums.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		if base_of.has(a) != base_of.has(b):
			return base_of.has(a)
		return a < b)
	for id in ids:
		var shortage := minimums[id] - _count(data, id)
		if shortage <= 0:
			continue
		var candidates := _cells_with(data, base_of[id]) if base_of.has(id) else _empty_cells(data)
		_shuffle(candidates, rng)
		for i in mini(shortage, candidates.size()):
			data.cells[candidates[i]] = id


static func _count(data: MapData, id: StringName) -> int:
	var total := 0
	for cell: Vector2i in data.cells:
		if data.cells[cell] == id:
			total += 1
	return total


static func _cells_with(data: MapData, id: StringName) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in data.cells:
		if data.cells[cell] == id:
			result.append(cell)
	return result


static func _empty_cells(data: MapData) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(1, data.height - 1):
		for x in range(1, data.width - 1):
			var cell := Vector2i(x, y)
			if not data.cells.has(cell) and cell.distance_to(data.spawn_cell) > SPAWN_CLEARANCE:
				result.append(cell)
	return result


static func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := cells[i]
		cells[i] = cells[j]
		cells[j] = swap


static func _noise(noise_seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = frequency
	return noise
