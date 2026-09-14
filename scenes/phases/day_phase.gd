extends GamePhase

const PICKUP_SCENE := preload("res://scenes/world/ItemPickup.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")
const MAP_WIDTH := 96
const MAP_HEIGHT := 64
const INITIAL_ENEMIES := 2
const ENEMIES_PER_DAY := 1
const SPAWN_INTERVAL := 20.0
const SPAWN_MIN_DISTANCE := 160.0
const SPAWN_MAX_DISTANCE := 320.0
const SPAWN_ATTEMPTS := 20

@export var day_duration := 90.0

var _enemy_types: Array[EnemyData] = []
var _ended := false

@onready var _world: GameWorld = %World
@onready var _player: Player = %Player
@onready var _day_timer: Timer = %DayTimer
@onready var _spawn_timer: Timer = %SpawnTimer
@onready var _time_label: Label = %TimeLabel
@onready var _hp_label: Label = %HPLabel
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

	for resource in DataDir.load_all("res://data/enemies"):
		var enemy_type := resource as EnemyData
		if enemy_type.min_day <= GameState.day:
			_enemy_types.append(enemy_type)
	for i in INITIAL_ENEMIES + ENEMIES_PER_DAY * (GameState.day - 1):
		_spawn_enemy()
	_spawn_timer.timeout.connect(_spawn_enemy)
	_spawn_timer.start(SPAWN_INTERVAL)

	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.hp_changed.connect(_on_hp_changed)
	_refresh_inventory()
	_refresh_hp()

	_day_timer.timeout.connect(_on_day_timer_timeout)
	_day_timer.start(day_duration)


func _process(_delta: float) -> void:
	_time_label.text = "%d" % ceili(_day_timer.time_left)


func enemy_count() -> int:
	var count := 0
	for child in _world.get_children():
		if child is Enemy:
			count += 1
	return count


func _spawn_enemy() -> void:
	if _enemy_types.is_empty():
		return
	for attempt in SPAWN_ATTEMPTS:
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(SPAWN_MIN_DISTANCE, SPAWN_MAX_DISTANCE)
		var cell := _world.cell_at(_player.global_position + offset)
		if not _world.contains(cell) or _world.get_block(cell) != null:
			continue
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.data = _enemy_types.pick_random()
		enemy.target = _player
		enemy.position = _world.cell_center(cell)
		_world.add_child(enemy)
		return


func _on_block_dug(cell: Vector2i, block: BlockData) -> void:
	if block.drop_item == null:
		return
	var pickup: ItemPickup = PICKUP_SCENE.instantiate()
	pickup.item = block.drop_item
	pickup.count = block.drop_count
	pickup.position = _world.cell_center(cell)
	_world.add_child(pickup)


func _on_hp_changed() -> void:
	_refresh_hp()
	if GameState.hp <= 0 and not _ended:
		_ended = true
		_day_timer.stop()
		_spawn_timer.stop()
		fail()


func _on_day_timer_timeout() -> void:
	if _ended:
		return
	_ended = true
	_spawn_timer.stop()
	finish()


func _refresh_hp() -> void:
	_hp_label.text = "HP %d / %d" % [GameState.hp, GameState.max_hp]


func _refresh_inventory() -> void:
	var lines: PackedStringArray = []
	for item: ItemData in GameState.inventory:
		lines.append("%s x%d" % [item.display_name, GameState.inventory[item]])
	_inventory_label.text = "\n".join(lines)
