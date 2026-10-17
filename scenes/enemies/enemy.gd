## 敵キャラクターの基底クラス。今後ゾンビ以外の敵種を追加する際、
## 移動パターンなどキャラクター固有の振る舞いを持たせられるよう、
## 共通ロジックをここに集約している。新しい敵種は Enemy を継承し、
## _compute_velocity() 等の一部メソッドをオーバーライドする想定 (issue #7)。
class_name Enemy
extends CharacterBody2D

signal died

const HIT_FLASH_COLOR := Color(4.0, 4.0, 4.0)
const HIT_FLASH_DURATION := 0.12
const KNOCKBACK_SPEED := 120.0
const KNOCKBACK_DURATION := 0.15

var data: EnemyData
var target: Node2D
var world: GameWorld

var _hp: int
var _speed: float
var _damage: int
var _knockback := Vector2.ZERO
var _knockback_left := 0.0

@onready var _sprite: Sprite2D = %Sprite
@onready var _hitbox: Area2D = %Hitbox


func _ready() -> void:
	var day_offset := GameState.day - 1
	_hp = int(data.max_hp + data.hp_growth_per_day * day_offset)
	_speed = minf(data.speed + data.speed_growth_per_day * day_offset, data.max_speed)
	_damage = int(data.damage + data.damage_growth_per_day * day_offset)
	_sprite.texture = data.sprite


func _physics_process(delta: float) -> void:
	if _knockback_left > 0.0:
		_knockback_left -= delta
		velocity = _knockback
	else:
		velocity = _compute_velocity()
	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0.0
	move_and_slide()
	for body in _hitbox.get_overlapping_bodies():
		if body is Player:
			body.take_hit(_damage, global_position)


## プレイヤーへの追尾方向を決める。敵ごとに経路探索すると数が増えた時に
## 重くなるため、DayPhase が計算した共有のフローフィールドを参照するだけに
## している (issue #7)。異なる動きをする敵種はこのメソッドを上書きする。
func _compute_velocity() -> Vector2:
	if target == null or global_position.distance_to(target.global_position) > data.aggro_range:
		return Vector2.ZERO
	var cell := world.cell_at(global_position)
	var direction: Vector2 = world.flow_field.get(cell, Vector2.ZERO)
	return direction * _speed


func take_damage(amount: int, from: Vector2) -> void:
	_hp -= amount
	_knockback = from.direction_to(global_position) * KNOCKBACK_SPEED
	_knockback_left = KNOCKBACK_DURATION
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, HIT_FLASH_DURATION).from(HIT_FLASH_COLOR)
	if _hp <= 0:
		Audio.play(&"enemy_die")
		died.emit()
		queue_free()
	else:
		Audio.play(&"enemy_hit")
