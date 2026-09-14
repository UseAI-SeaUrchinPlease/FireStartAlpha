class_name Enemy
extends CharacterBody2D

signal died

const HIT_FLASH_COLOR := Color(4.0, 4.0, 4.0)
const HIT_FLASH_DURATION := 0.12
const KNOCKBACK_SPEED := 120.0
const KNOCKBACK_DURATION := 0.15

var data: EnemyData
var target: Node2D

var _hp: int
var _knockback := Vector2.ZERO
var _knockback_left := 0.0

@onready var _sprite: Sprite2D = %Sprite
@onready var _hitbox: Area2D = %Hitbox


func _ready() -> void:
	_hp = data.max_hp
	_sprite.texture = data.sprite


func _physics_process(delta: float) -> void:
	if _knockback_left > 0.0:
		_knockback_left -= delta
		velocity = _knockback
	elif target != null and global_position.distance_to(target.global_position) <= data.aggro_range:
		velocity = global_position.direction_to(target.global_position) * data.speed
	else:
		velocity = Vector2.ZERO
	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0.0
	move_and_slide()
	for body in _hitbox.get_overlapping_bodies():
		if body is Player:
			body.take_hit(data.damage, global_position)


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
