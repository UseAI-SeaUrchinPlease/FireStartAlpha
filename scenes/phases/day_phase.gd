extends GamePhase

const PICKUP_SCENE := preload("res://scenes/world/ItemPickup.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")
const MAP_WIDTH := 96
const MAP_HEIGHT := 64
const INITIAL_ENEMIES := 2
const ENEMIES_PER_DAY := 1
const CAP_BASE := 5
const CAP_PER_DAY := 1
const CAP_MAX := 15
const SPAWN_INTERVAL_BASE := 20.0
const SPAWN_INTERVAL_DECAY_PER_DAY := 2.0
const SPAWN_INTERVAL_MIN := 6.0
const SPAWN_MIN_DISTANCE := 160.0
const SPAWN_MAX_DISTANCE := 320.0
const SPAWN_ATTEMPTS := 20
const SUNSET_START := 0.55
const SUNSET_COLOR := Color(0.9, 0.55, 0.35)
const DUSK_COLOR := Color(0.4, 0.35, 0.55)
const FLOW_FIELD_RADIUS_MARGIN := 2
const FLOW_FIELD_COOLDOWN := 0.2

@export var day_duration := 90.0

var _enemy_types: Array[EnemyData] = []
var _ended := false
var _flow_field_radius := 0
var _flow_field_cooldown := 0.0
var _last_flow_field_cell := Vector2i.ZERO

@onready var _world: GameWorld = %World
@onready var _player: Player = %Player
@onready var _daylight: CanvasModulate = %Daylight
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

	var max_aggro_range := 0.0
	for resource in DataDir.load_all("res://data/enemies"):
		var enemy_type := resource as EnemyData
		max_aggro_range = maxf(max_aggro_range, enemy_type.aggro_range)
		if enemy_type.min_day <= GameState.day:
			_enemy_types.append(enemy_type)
	_flow_field_radius = ceili(max_aggro_range / GameWorld.TILE_SIZE) + FLOW_FIELD_RADIUS_MARGIN
	_recompute_flow_field()

	for i in mini(INITIAL_ENEMIES + ENEMIES_PER_DAY * (GameState.day - 1), _max_concurrent_enemies()):
		_spawn_enemy()
	_spawn_timer.timeout.connect(_spawn_enemy)
	_spawn_timer.start(_spawn_interval())

	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.hp_changed.connect(_on_hp_changed)
	_refresh_inventory()
	_refresh_hp()

	_day_timer.timeout.connect(_on_day_timer_timeout)
	_day_timer.start(day_duration)


func _process(delta: float) -> void:
	_time_label.text = "%d" % ceili(_day_timer.time_left)
	_daylight.color = _daylight_color(1.0 - _day_timer.time_left / day_duration)

	_flow_field_cooldown = maxf(0.0, _flow_field_cooldown - delta)
	if _flow_field_cooldown <= 0.0 and _world.cell_at(_player.global_position) != _last_flow_field_cell:
		_recompute_flow_field()


func _recompute_flow_field() -> void:
	var player_cell := _world.cell_at(_player.global_position)
	_world.flow_field = _world.compute_flow_field(player_cell, _flow_field_radius)
	_last_flow_field_cell = player_cell
	_flow_field_cooldown = FLOW_FIELD_COOLDOWN


func enemy_count() -> int:
	var count := 0
	for child in _world.get_children():
		if child is Enemy:
			count += 1
	return count


func _max_concurrent_enemies() -> int:
	return mini(CAP_BASE + CAP_PER_DAY * (GameState.day - 1), CAP_MAX)


func _spawn_interval() -> float:
	return maxf(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_BASE - SPAWN_INTERVAL_DECAY_PER_DAY * (GameState.day - 1))


func _daylight_color(elapsed: float) -> Color:
	if elapsed < SUNSET_START:
		return Color.WHITE
	var t := (elapsed - SUNSET_START) / (1.0 - SUNSET_START)
	if t < 0.5:
		return Color.WHITE.lerp(SUNSET_COLOR, t * 2.0)
	return SUNSET_COLOR.lerp(DUSK_COLOR, (t - 0.5) * 2.0)


func _spawn_enemy() -> void:
	if _enemy_types.is_empty() or enemy_count() >= _max_concurrent_enemies():
		return
	for attempt in SPAWN_ATTEMPTS:
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(SPAWN_MIN_DISTANCE, SPAWN_MAX_DISTANCE)
		var cell := _world.cell_at(_player.global_position + offset)
		if not _world.contains(cell):
			continue
		var block := _world.get_block(cell)
		if block != null and block.blocks_movement():
			continue
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.data = _enemy_types.pick_random()
		enemy.target = _player
		enemy.world = _world
		enemy.position = _world.cell_center(cell)
		_world.add_child(enemy)
		return


func _on_block_dug(cell: Vector2i, block: BlockData) -> void:
	Audio.play(&"break")
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
	Audio.play(&"sunset")
	finish()


func _refresh_hp() -> void:
	_hp_label.text = "HP %d / %d" % [GameState.hp, GameState.max_hp]


func _refresh_inventory() -> void:
	var lines: PackedStringArray = []
	for item: ItemData in GameState.inventory:
		lines.append("%s x%d" % [item.display_name, GameState.inventory[item]])
	_inventory_label.text = "\n".join(lines)
