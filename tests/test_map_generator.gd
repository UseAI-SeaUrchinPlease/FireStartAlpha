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

	if _failures == 0:
		print("test_map_generator: OK")
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
