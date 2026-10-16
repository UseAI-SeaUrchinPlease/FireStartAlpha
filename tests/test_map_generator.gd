extends SceneTree

const KNOWN_BLOCKS: Array[StringName] = [&"wall", &"tree", &"rock", &"grass"]

var _failures := 0


func _init() -> void:
	var a := MapGenerator.generate(42, 48, 32)
	var b := MapGenerator.generate(42, 48, 32)
	var c := MapGenerator.generate(7, 48, 32)

	_check(a.cells.hash() == b.cells.hash(), "same seed produces the same map")
	_check(a.cells.hash() != c.cells.hash(), "different seed produces a different map")
	_check(a.ground.size() == a.width * a.height, "every cell has a ground tile")

	var border_ok := true
	for x in a.width:
		border_ok = border_ok and a.cells.get(Vector2i(x, 0)) == &"wall"
		border_ok = border_ok and a.cells.get(Vector2i(x, a.height - 1)) == &"wall"
	for y in a.height:
		border_ok = border_ok and a.cells.get(Vector2i(0, y)) == &"wall"
		border_ok = border_ok and a.cells.get(Vector2i(a.width - 1, y)) == &"wall"
	_check(border_ok, "the outer ring is wall")

	var ids_ok := true
	for cell: Vector2i in a.cells:
		ids_ok = ids_ok and a.cells[cell] in KNOWN_BLOCKS
	_check(ids_ok, "every block id is known")

	var spawn_clear := true
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			spawn_clear = spawn_clear and not a.cells.has(a.spawn_cell + Vector2i(dx, dy))
	_check(spawn_clear, "spawn cell and its neighbours are clear")
	_check(a.cells.size() > a.width * 2 + a.height * 2, "the map has obstacles beyond the border")

	_check_variants()
	_check_minimums()

	if _failures == 0:
		print("test_map_generator: OK")
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func _check_variants() -> void:
	var variants: Array[BlockData] = [_variant(&"pale_tree", &"tree", 0.2), _variant(&"dark_tree", &"tree", 0.1)]
	var plain := MapGenerator.generate(42, 96, 64)
	var mixed := MapGenerator.generate(42, 96, 64, variants)
	var again := MapGenerator.generate(42, 96, 64, variants)
	_check(mixed.cells.hash() == again.cells.hash(), "variants keep generation deterministic")

	var replaced_only_trees := true
	var counts := {}
	for cell: Vector2i in mixed.cells:
		var id: StringName = mixed.cells[cell]
		counts[id] = counts.get(id, 0) + 1
		if id != plain.cells[cell]:
			replaced_only_trees = replaced_only_trees and plain.cells[cell] == &"tree"
	_check(replaced_only_trees, "variants only replace the block they are declared on")
	var forest: int = counts.get(&"tree", 0) + counts.get(&"pale_tree", 0) + counts.get(&"dark_tree", 0)
	_check(forest == _count(plain, &"tree"), "replacing keeps the forest the same size")
	var pale_ratio := float(counts.get(&"pale_tree", 0)) / forest
	var dark_ratio := float(counts.get(&"dark_tree", 0)) / forest
	_check(absf(pale_ratio - 0.2) < 0.05, "a 20%% variant replaces about 20%% of its base (got %.3f)" % pale_ratio)
	_check(absf(dark_ratio - 0.1) < 0.04, "a second variant on the same base gets its own share (got %.3f)" % dark_ratio)


func _check_minimums() -> void:
	var never := _variant(&"never_ore", &"rock", 0.0)
	var minimums: Dictionary[StringName, int] = {&"never_ore": 7, &"grass": 600}
	var plain := MapGenerator.generate(42, 96, 64)
	var map := MapGenerator.generate(42, 96, 64, [never], minimums)
	_check(_count(map, &"never_ore") == 7, "a missing rare block is topped up exactly to its minimum")
	_check(_count(map, &"rock") == _count(plain, &"rock") - 7, "rare blocks are topped up by replacing their base block")
	_check(_count(map, &"grass") == 600, "a plain block is topped up to its minimum")

	var added_on_empty := true
	for cell: Vector2i in map.cells:
		if map.cells[cell] == &"grass" and not plain.cells.has(cell):
			added_on_empty = added_on_empty and cell.distance_to(map.spawn_cell) > MapGenerator.SPAWN_CLEARANCE
		elif map.cells[cell] == &"grass":
			added_on_empty = added_on_empty and plain.cells[cell] == &"grass"
	_check(added_on_empty, "plain blocks are only added on empty cells outside the spawn clearance")

	var enough: Dictionary[StringName, int] = {&"grass": 1}
	var untouched := MapGenerator.generate(42, 96, 64, [], enough)
	_check(untouched.cells.hash() == plain.cells.hash(), "a minimum that is already met changes nothing")


func _variant(id: StringName, base: StringName, chance: float) -> BlockData:
	var block := BlockData.new()
	block.id = id
	block.replaces = base
	block.replace_chance = chance
	return block


func _count(map: MapData, id: StringName) -> int:
	var total := 0
	for cell: Vector2i in map.cells:
		if map.cells[cell] == id:
			total += 1
	return total
