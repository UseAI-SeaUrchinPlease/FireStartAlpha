extends SceneTree

const GROUND_COLORS: Array[Color] = [Color("6aa84f"), Color("8b5a2b")]
const BLOCK_COLORS: Array[Color] = [Color("2e7d32"), Color("7f7f7f"), Color("9ccc65"), Color("3a3a3a")]
const ITEM_COLORS: Array[Color] = [Color("a0522d"), Color("c8b560"), Color("b0b0b0")]


func _init() -> void:
	_save_atlas("res://assets/sprites/ground.png", 16, GROUND_COLORS, 0.1)
	_save_atlas("res://assets/sprites/blocks.png", 16, BLOCK_COLORS, 0.3)
	_save_atlas("res://assets/sprites/items.png", 8, ITEM_COLORS, 0.3)
	_save_solid("res://assets/sprites/player.png", Vector2i(12, 16), Color("ff9800"))
	_save_solid("res://assets/sprites/zombie.png", Vector2i(12, 16), Color("6a8f3c"))
	quit()


func _save_atlas(path: String, size: int, colors: Array[Color], border_darken: float) -> void:
	var image := Image.create_empty(size * colors.size(), size, false, Image.FORMAT_RGBA8)
	for i in colors.size():
		var rect := Rect2i(i * size, 0, size, size)
		image.fill_rect(rect, colors[i].darkened(border_darken))
		image.fill_rect(rect.grow(-1), colors[i])
	image.save_png(path)
	print("saved ", path)


func _save_solid(path: String, size: Vector2i, color: Color) -> void:
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color.darkened(0.3))
	image.fill_rect(Rect2i(Vector2i.ONE, size - Vector2i(2, 2)), color)
	image.save_png(path)
	print("saved ", path)
