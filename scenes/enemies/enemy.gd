## 敵キャラクターの基底クラス。今後ゾンビ以外の敵種を追加する際、
## 移動パターンなどキャラクター固有の振る舞いを持たせられるよう、
## 共通ロジックをここに集約している。新しい敵種は Enemy を継承し、
## _compute_velocity() 等の一部メソッドをオーバーライドする想定 (issue #7)。
class_name Enemy
extends CharacterBody2D

signal died

const HIT_FLASH_COLOR := Color(4.0, 4.0, 4.0)
const HIT_FLASH_DURATION := 0.12
const HITS_PER_HARDNESS := 20.0

var data: EnemyData
var target: Node2D
var world: GameWorld

var _hp: int
var _speed: float
var _damage: int
var _knockback := Vector2.ZERO
var _knockback_left := 0.0
var _damage_since_knockback := 0
var _attack_cooldown := 0.0
var _break_cell := Vector2i.ZERO
var _break_progress := 0.0
var _chasing := false

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
	_update_breaking(delta)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _attack_cooldown > 0.0:
		return
	for body in _hitbox.get_overlapping_bodies():
		if body is Player and body.take_hit(_damage, global_position):
			_attack_cooldown = data.attack_interval


## プレイヤーへの追尾方向を決める。敵ごとに経路探索すると数が増えた時に
## 重くなるため、DayPhase が計算した共有のフローフィールドを参照するだけに
## している (issue #7)。異なる動きをする敵種はこのメソッドを上書きする。
## ブロックを壊す敵は障害物を避けると壊す機会がなくなるため、直進させる。
func _compute_velocity() -> Vector2:
	if target == null:
		return Vector2.ZERO
	# 一度追い始めたら追い続ける。障害物を迂回する途中で直線距離が aggro_range を
	# 超えた瞬間に止まってしまわないため。
	if not _chasing and global_position.distance_to(target.global_position) > data.aggro_range:
		return Vector2.ZERO
	_chasing = true
	if data.break_speed > 0.0:
		return global_position.direction_to(target.global_position) * _speed
	var cell := world.cell_at(global_position)
	# 軸方向の単位ベクトルではなく次のセルの中心へ向かうことで、列からずれたまま
	# 進んで障害物の角に正面からぶつかって止まるのを防ぐ (PR #11 レビュー)。
	if world.flow_field.has(cell):
		return global_position.direction_to(world.cell_center(cell + world.flow_field[cell])) * _speed
	# プレイヤーと同じセル(フィールドのゴール)では直接向かう
	if cell == world.cell_at(target.global_position):
		return global_position.direction_to(target.global_position) * _speed
	return Vector2.ZERO


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
	if _break_progress >= _break_time(world.get_block(cell)):
		for dx in range(-data.break_radius, data.break_radius + 1):
			for dy in range(-data.break_radius, data.break_radius + 1):
				var neighbor: Vector2i = _break_cell + Vector2i(dx, dy)
				var block := world.get_block(neighbor)
				if block != null and block.hits > 0:
					world.remove_block(neighbor)
		Audio.play(&"break")
		_break_progress = 0.0


## プレビュー統合 (#8 + #9): #9 で BlockData の hardness(秒)が叩く回数に変わったため、
## 叩く回数を HITS_PER_HARDNESS で割った値を「硬さ」とみなし、#8 の元の速さに合わせる
## (草むら 6回→0.3、木 14回→0.7、岩 20回→1.0。元は 0.3 / 0.6 / 1.0)。道具レベルは無視する。
func _break_time(block: BlockData) -> float:
	return block.hits / HITS_PER_HARDNESS


## The diggable block the enemy is currently pushing against, or null.
func _blocking_cell() -> Variant:
	if data.break_speed <= 0.0 or world == null or _knockback_left > 0.0:
		return null
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		# Step slightly into the obstacle so the point lands inside the block's cell.
		var cell := world.cell_at(collision.get_position() - collision.get_normal())
		var block := world.get_block(cell)
		if block != null and block.hits > 0:
			return cell
	return null
