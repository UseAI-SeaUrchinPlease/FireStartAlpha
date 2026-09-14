class_name Player
extends CharacterBody2D

const SPEED := 90.0
const DIG_REACH := 12.0
const DIG_BAR_OFFSET := Vector2(-8.0, -13.0)
const ATTACK_REACH := 14.0
const ATTACK_COOLDOWN := 0.4
const INVULNERABLE_DURATION := 0.8
const BLINK_PERIOD := 0.1
const KNOCKBACK_SPEED := 160.0
const KNOCKBACK_DURATION := 0.12

var world: GameWorld

var _facing := Vector2.DOWN
var _dig_cell := Vector2i.ZERO
var _dig_progress := 0.0
var _attack_cooldown := 0.0
var _invulnerable_left := 0.0
var _knockback := Vector2.ZERO
var _knockback_left := 0.0

@onready var camera: Camera2D = %Camera
@onready var _sprite: Sprite2D = %Sprite
@onready var _attack_area: Area2D = %AttackArea
@onready var _dig_bar: ProgressBar = %DigBar


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _knockback_left > 0.0:
		_knockback_left -= delta
		velocity = _knockback
	else:
		velocity = direction * SPEED
	if direction != Vector2.ZERO:
		_facing = _cardinal(direction)
		if _facing.x != 0.0:
			_sprite.flip_h = _facing.x < 0.0
	_attack_area.position = _facing * ATTACK_REACH
	move_and_slide()
	_update_dig(delta)
	_update_attack(delta)
	_update_invulnerability(delta)


func take_hit(damage: int, from: Vector2) -> void:
	if _invulnerable_left > 0.0:
		return
	_invulnerable_left = INVULNERABLE_DURATION
	_knockback = from.direction_to(global_position) * KNOCKBACK_SPEED
	_knockback_left = KNOCKBACK_DURATION
	Audio.play(&"hurt")
	GameState.damage(damage)


func _update_dig(delta: float) -> void:
	_dig_bar.visible = false
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
		Audio.play(&"dig")
	_dig_progress += delta * GameState.dig_speed_multiplier()
	if _dig_progress >= block.hardness:
		world.dig(cell)
		_dig_progress = 0.0
		return
	_dig_bar.visible = true
	_dig_bar.value = _dig_progress / block.hardness
	_dig_bar.global_position = world.cell_center(cell) + DIG_BAR_OFFSET


func _update_attack(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _attack_cooldown > 0.0 or not Input.is_action_just_pressed("attack"):
		return
	_attack_cooldown = ATTACK_COOLDOWN
	Audio.play(&"attack")
	for body in _attack_area.get_overlapping_bodies():
		if body is Enemy:
			body.take_damage(GameState.attack_damage(), global_position)


func _update_invulnerability(delta: float) -> void:
	if _invulnerable_left <= 0.0:
		_sprite.visible = true
		return
	_invulnerable_left -= delta
	_sprite.visible = fmod(_invulnerable_left, BLINK_PERIOD) < BLINK_PERIOD * 0.5


func _cardinal(direction: Vector2) -> Vector2:
	if absf(direction.x) >= absf(direction.y):
		return Vector2(signf(direction.x), 0.0)
	return Vector2(0.0, signf(direction.y))
