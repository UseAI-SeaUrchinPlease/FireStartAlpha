extends GamePhase

const PICKUP_SCENE := preload("res://scenes/world/ItemPickup.tscn")
const MAP_WIDTH := 96
const MAP_HEIGHT := 64

@export var day_duration := 90.0

@onready var _world: GameWorld = %World
@onready var _player: Player = %Player
@onready var _day_timer: Timer = %DayTimer
@onready var _time_label: Label = %TimeLabel
@onready var _inventory_label: Label = %InventoryLabel


func _ready() -> void:
	var map := MapGenerator.generate(randi(), MAP_WIDTH, MAP_HEIGHT)
	_world.build(map)
	_world.block_dug.connect(_on_block_dug)

	_player.world = _world
	_player.global_position = _world.cell_center(map.spawn_cell)
	var bounds := _world.pixel_size()
	_player.camera.limit_left = 0
	_player.camera.limit_top = 0
	_player.camera.limit_right = int(bounds.x)
	_player.camera.limit_bottom = int(bounds.y)

	GameState.inventory_changed.connect(_refresh_inventory)
	_refresh_inventory()

	_day_timer.timeout.connect(finish)
	_day_timer.start(day_duration)


func _process(_delta: float) -> void:
	_time_label.text = "%d" % ceili(_day_timer.time_left)


func _on_block_dug(cell: Vector2i, block: BlockData) -> void:
	if block.drop_item == null:
		return
	var pickup: ItemPickup = PICKUP_SCENE.instantiate()
	pickup.item = block.drop_item
	pickup.count = block.drop_count
	pickup.position = _world.cell_center(cell)
	_world.add_child(pickup)


func _refresh_inventory() -> void:
	var lines: PackedStringArray = []
	for item: ItemData in GameState.inventory:
		lines.append("%s x%d" % [item.display_name, GameState.inventory[item]])
	_inventory_label.text = "\n".join(lines)
