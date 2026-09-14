extends GamePhase

const ROW_SCENE := preload("res://scenes/ui/MenuRow.tscn")

var _upgrades: Array[UpgradeData] = []
var _rows: Array[MenuRow] = []
var _focus := 0

@onready var _title_label: Label = %TitleLabel
@onready var _points_label: Label = %PointsLabel
@onready var _hp_label: Label = %HPLabel
@onready var _rows_container: VBoxContainer = %Rows


func _ready() -> void:
	_title_label.text = "%d日目の夜   強化" % GameState.day
	for resource in DataDir.load_all("res://data/upgrades"):
		_upgrades.append(resource as UpgradeData)
	for i in _upgrades.size() + 1:
		var row: MenuRow = ROW_SCENE.instantiate()
		_rows_container.add_child(row)
		_rows.append(row)
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
	if _focus == _upgrades.size():
		finish()
		return
	if GameState.buy_upgrade(_upgrades[_focus]):
		_refresh()


func row_count() -> int:
	return _rows.size()


func set_focus(index: int) -> void:
	_focus = wrapi(index, 0, _rows.size())
	for i in _rows.size():
		_rows[i].focused = i == _focus


func _refresh() -> void:
	_points_label.text = "ポイント: %d" % GameState.fire_points
	_hp_label.text = "HP %d / %d   攻撃 %d" % [GameState.hp, GameState.max_hp, GameState.attack_damage()]
	for i in _upgrades.size():
		var upgrade := _upgrades[i]
		var level := GameState.upgrade_level(upgrade)
		var detail := upgrade.description
		var cost := "%d pt" % upgrade.cost
		if upgrade.max_level != 0:
			detail += "   Lv %d / %d" % [level, upgrade.max_level]
			if level >= upgrade.max_level:
				cost = "MAX"
		_rows[i].set_texts(upgrade.display_name, detail, cost)
		_rows[i].available = GameState.can_buy(upgrade)
	var next_row := _rows[_upgrades.size()]
	next_row.set_texts("次の日へ", "", "")
	next_row.available = true
