extends GamePhase

const ROW_SCENE := preload("res://scenes/ui/UpgradeRow.tscn")

var _rows: Array[UpgradeRow] = []
var _focus := 0

@onready var _title_label: Label = %TitleLabel
@onready var _points_label: Label = %PointsLabel
@onready var _hp_label: Label = %HPLabel
@onready var _rows_container: VBoxContainer = %Rows


func _ready() -> void:
	_title_label.text = "%d日目の夜   強化" % GameState.day
	for resource in DataDir.load_all("res://data/upgrades"):
		_add_row(resource as UpgradeData)
	_add_row(null)
	set_focus(0)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_down"):
		set_focus(_focus + 1)
	elif event.is_action_pressed("move_up"):
		set_focus(_focus - 1)
	elif event.is_action_pressed("interact"):
		activate_focused()


func activate_focused() -> void:
	var row := _rows[_focus]
	if row.upgrade == null:
		finish()
		return
	if GameState.buy_upgrade(row.upgrade):
		_refresh()


func row_count() -> int:
	return _rows.size()


func _add_row(upgrade: UpgradeData) -> void:
	var row: UpgradeRow = ROW_SCENE.instantiate()
	row.upgrade = upgrade
	_rows_container.add_child(row)
	_rows.append(row)


func set_focus(index: int) -> void:
	_focus = wrapi(index, 0, _rows.size())
	for i in _rows.size():
		_rows[i].focused = i == _focus


func _refresh() -> void:
	_points_label.text = "ポイント: %d" % GameState.fire_points
	_hp_label.text = "HP %d / %d   攻撃 %d" % [GameState.hp, GameState.max_hp, GameState.attack_damage()]
	for row in _rows:
		row.refresh()
