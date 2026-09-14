class_name Player
extends CharacterBody2D

const SPEED := 90.0
const DIG_REACH := 12.0

var world: GameWorld

var _facing := Vector2.DOWN
var _dig_cell := Vector2i.ZERO
var _dig_progress := 0.0

@onready var camera: Camera2D = %Camera
@onready var _sprite: Sprite2D = %Sprite


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	if direction != Vector2.ZERO:
		_facing = _cardinal(direction)
		if _facing.x != 0.0:
			_sprite.flip_h = _facing.x < 0.0
	move_and_slide()
	_update_dig(delta)


func _update_dig(delta: float) -> void:
	if world == null or not Input.is_action_pressed("dig"):
		_dig_progress = 0.0
		return
	var cell := world.cell_at(global_position + _facing * DIG_REACH)
	var block := world.get_block(cell)
	if block == null or block.hardness <= 0.0:
		_dig_progress = 0.0
		return
	if cell != _dig_cell:
		_dig_cell = cell
		_dig_progress = 0.0
	_dig_progress += delta
	if _dig_progress >= block.hardness:
		world.dig(cell)
		_dig_progress = 0.0


func _cardinal(direction: Vector2) -> Vector2:
	if absf(direction.x) >= absf(direction.y):
		return Vector2(signf(direction.x), 0.0)
	return Vector2(0.0, signf(direction.y))
