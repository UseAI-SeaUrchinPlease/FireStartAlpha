class_name NightPhase
extends GamePhase

const BARRIER_COLOR := Color(1.0, 0.6, 0.2)

@export var night_duration := 60.0
@export var barrier_radius := 64.0

# Handed over from the day so the night is spent on the same map.
var world: GameWorld
var player: Player

@onready var _barrier: Node2D = %Barrier
@onready var _night_timer: Timer = %NightTimer
@onready var _time_label: Label = %TimeLabel
@onready var _hp_label: Label = %HPLabel


func _ready() -> void:
	world.reparent(self)
	move_child(world, _barrier.get_index())
	player.reparent(self)
	_barrier.global_position = player.global_position
	_barrier.draw.connect(_draw_barrier)

	_hp_label.text = "HP %d / %d" % [GameState.hp, GameState.max_hp]
	_night_timer.timeout.connect(finish)
	_night_timer.start(night_duration)


func _physics_process(_delta: float) -> void:
	var offset := player.global_position - _barrier.global_position
	if offset.length() > barrier_radius:
		player.global_position = _barrier.global_position + offset.limit_length(barrier_radius)


func _process(_delta: float) -> void:
	_time_label.text = "夜明けまで %d" % ceili(_night_timer.time_left)


func _draw_barrier() -> void:
	_barrier.draw_circle(Vector2.ZERO, barrier_radius, Color(BARRIER_COLOR, 0.15))
	_barrier.draw_arc(Vector2.ZERO, barrier_radius, 0.0, TAU, 64, BARRIER_COLOR, 1.0)
