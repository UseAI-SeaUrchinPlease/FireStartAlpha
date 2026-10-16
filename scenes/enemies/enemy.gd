class_name Enemy
extends CharacterBody2D

signal died

const HIT_FLASH_COLOR := Color(4.0, 4.0, 4.0)
const HIT_FLASH_DURATION := 0.12

var data: EnemyData
var target: Node2D
var world: GameWorld

var _hp: int
var _knockback := Vector2.ZERO
var _knockback_left := 0.0
var _damage_since_knockback := 0
var _attack_cooldown := 0.0
var _break_cell := Vector2i.ZERO
var _break_progress := 0.0

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
	_update_breaking(delta)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _attack_cooldown > 0.0:
		return
	for body in _hitbox.get_overlapping_bodies():
		if body is Player and body.take_hit(data.damage, global_position):
			_attack_cooldown = data.attack_interval


func take_damage(amount: int, from: Vector2) -> void:
	_hp -= amount
	_damage_since_knockback += amount
	if _damage_since_knockback >= data.knockback_threshold:
		_damage_since_knockback = 0
		_knockback = from.direction_to(global_position) * data.knockback_speed
		_knockback_left = data.knockback_duration
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, HIT_FLASH_DURATION).from(HIT_FLASH_COLOR)
	if _hp <= 0:
		Audio.play(&"enemy_die")
		died.emit()
		queue_free()
	else:
		Audio.play(&"enemy_hit")


func _update_breaking(delta: float) -> void:
	var cell: Variant = _blocking_cell()
	if cell == null:
		_break_progress = 0.0
		return
	if cell != _break_cell:
		_break_cell = cell as Vector2i
		_break_progress = 0.0
	_break_progress += delta * data.break_speed
	if _break_progress >= world.get_block(cell).hardness:
		for dx in range(-data.break_radius, data.break_radius + 1):
			for dy in range(-data.break_radius, data.break_radius + 1):
				var neighbor: Vector2i = _break_cell + Vector2i(dx, dy)
				var block := world.get_block(neighbor)
				if block != null and block.hardness > 0.0:
					world.remove_block(neighbor)
		Audio.play(&"break")
		_break_progress = 0.0


## The diggable block the enemy is currently pushing against, or null.
func _blocking_cell() -> Variant:
	if data.break_speed <= 0.0 or world == null or _knockback_left > 0.0:
		return null
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		# Step slightly into the obstacle so the point lands inside the block's cell.
		var cell := world.cell_at(collision.get_position() - collision.get_normal())
		var block := world.get_block(cell)
		if block != null and block.hardness > 0.0:
			return cell
	return null
