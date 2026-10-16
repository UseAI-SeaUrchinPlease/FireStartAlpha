class_name Player
extends CharacterBody2D

const SPEED := 90.0
const DIG_REACH := 12.0
const DIG_BAR_OFFSET := Vector2(-8.0, -13.0)
## 押しっぱなしで自動的に叩く間隔。連打してもこれより速くは叩けない (DEVELOPMENT.md 8.5)。
const DIG_INTERVAL := 0.3
## 毎フレーム delta を引いた結果に残る浮動小数点の誤差で1フレーム遅れないための許容幅。
const DIG_COOLDOWN_EPSILON := 0.0001
const BLOCKED_MARK_OFFSET := Vector2(-4.0, -12.0)
const BLOCKED_MARK_DURATION := 0.4
const ATTACK_REACH := 14.0
const ATTACK_COOLDOWN := 0.4
const INVULNERABLE_DURATION := 0.8
const BLINK_PERIOD := 0.1
const KNOCKBACK_SPEED := 160.0
const KNOCKBACK_DURATION := 0.12

var world: GameWorld

var _facing := Vector2.DOWN
var _dig_cooldown := 0.0
var _blocked_mark_left := 0.0
var _attack_cooldown := 0.0
var _invulnerable_left := 0.0
var _knockback := Vector2.ZERO
var _knockback_left := 0.0

@onready var camera: Camera2D = %Camera
@onready var _sprite: Sprite2D = %Sprite
@onready var _attack_area: Area2D = %AttackArea
@onready var _dig_bar: ProgressBar = %DigBar
@onready var _blocked_mark: Label = %BlockedMark


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
	_dig_cooldown -= delta
	_blocked_mark_left = maxf(_blocked_mark_left - delta, 0.0)
	_blocked_mark.visible = _blocked_mark_left > 0.0
	_dig_bar.visible = false
	if world == null:
		return
	var cell := world.cell_at(global_position + _facing * DIG_REACH)
	if Input.is_action_pressed("dig") and _dig_cooldown <= DIG_COOLDOWN_EPSILON:
		var result := world.hit(cell, GameState.tool_level())
		if result != GameWorld.HitResult.NONE:
			# 押し続けている間はフレームに収まらなかった余りを次に繰り越し、間隔を平均で正確に保つ。
			# 離していた間に溜まった分は1フレーム分までしか持ち越さない。
			_dig_cooldown = maxf(_dig_cooldown, -delta) + DIG_INTERVAL / GameState.dig_speed_multiplier()
		if result == GameWorld.HitResult.HIT:
			Audio.play(&"dig")
		elif result == GameWorld.HitResult.BLOCKED:
			Audio.play(&"dig_blocked")
			_blocked_mark.global_position = world.cell_center(cell) + BLOCKED_MARK_OFFSET
			_blocked_mark_left = BLOCKED_MARK_DURATION
			_blocked_mark.visible = true
	var block := world.get_block(cell)
	var count := world.hit_count(cell)
	if block == null or count == 0:
		return
	_dig_bar.visible = true
	_dig_bar.value = float(count) / block.hits
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
