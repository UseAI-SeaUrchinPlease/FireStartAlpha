class_name DayPhase
extends GamePhase

signal ignite_requested

const MAP_WIDTH := 96
const MAP_HEIGHT := 64
const SUNSET_START := 0.55
const SUNSET_COLOR := Color(0.9, 0.55, 0.35)
const DUSK_COLOR := Color(0.4, 0.35, 0.55)

@export var day_duration := 90.0

var _ended := false

@onready var world: GameWorld = %World
@onready var player: Player = %Player
@onready var _daylight: CanvasModulate = %Daylight
@onready var _day_timer: Timer = %DayTimer
@onready var _time_label: Label = %TimeLabel
@onready var _hp_label: Label = %HPLabel
@onready var _inventory_label: Label = %InventoryLabel


func _ready() -> void:
	var map := MapGenerator.generate(randi(), MAP_WIDTH, MAP_HEIGHT)
	world.build(map)

	player.world = world
	player.global_position = world.cell_center(map.spawn_cell)
	var bounds := world.pixel_size()
	player.camera.limit_left = 0
	player.camera.limit_top = 0
	player.camera.limit_right = int(bounds.x)
	player.camera.limit_bottom = int(bounds.y)

	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.hp_changed.connect(_on_hp_changed)
	_refresh_inventory()
	_refresh_hp()

	_day_timer.timeout.connect(_on_day_timer_timeout)
	_day_timer.start(day_duration)


func _process(_delta: float) -> void:
	_time_label.text = "%d" % ceili(_day_timer.time_left)
	_daylight.color = _daylight_color(1.0 - _day_timer.time_left / day_duration)


func _unhandled_input(event: InputEvent) -> void:
	if not _ended and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		Audio.play(&"menu_select")
		ignite_requested.emit()


func time_left() -> float:
	return _day_timer.time_left


func _daylight_color(elapsed: float) -> Color:
	if elapsed < SUNSET_START:
		return Color.WHITE
	var t := (elapsed - SUNSET_START) / (1.0 - SUNSET_START)
	if t < 0.5:
		return Color.WHITE.lerp(SUNSET_COLOR, t * 2.0)
	return SUNSET_COLOR.lerp(DUSK_COLOR, (t - 0.5) * 2.0)


func _on_hp_changed() -> void:
	_refresh_hp()
	if GameState.hp <= 0 and not _ended:
		_ended = true
		_day_timer.stop()
		fail()


func _on_day_timer_timeout() -> void:
	if _ended:
		return
	_ended = true
	Audio.play(&"sunset")
	finish()


func _refresh_hp() -> void:
	_hp_label.text = "HP %d / %d" % [GameState.hp, GameState.max_hp]


func _refresh_inventory() -> void:
	var lines: PackedStringArray = []
	for item: ItemData in GameState.inventory:
		lines.append("%s x%d" % [item.display_name, GameState.inventory[item]])
	_inventory_label.text = "\n".join(lines)
