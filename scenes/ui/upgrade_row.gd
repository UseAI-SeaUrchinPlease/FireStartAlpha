class_name UpgradeRow
extends PanelContainer

const FOCUSED_COLOR := Color(1.0, 0.9, 0.4)
const UNAVAILABLE_COLOR := Color(0.55, 0.55, 0.55)

var upgrade: UpgradeData
var focused := false:
	set(value):
		focused = value
		refresh()

@onready var _name_label: Label = %NameLabel
@onready var _detail_label: Label = %DetailLabel
@onready var _cost_label: Label = %CostLabel


func _ready() -> void:
	refresh()


func refresh() -> void:
	if not is_node_ready():
		return
	if upgrade == null:
		_name_label.text = "次の日へ"
		_detail_label.text = ""
		_cost_label.text = ""
		modulate = FOCUSED_COLOR if focused else Color.WHITE
		return
	var level := GameState.upgrade_level(upgrade)
	_name_label.text = upgrade.display_name
	_detail_label.text = upgrade.description if upgrade.max_level == 0 else "%s   Lv %d / %d" % [upgrade.description, level, upgrade.max_level]
	if upgrade.max_level != 0 and level >= upgrade.max_level:
		_cost_label.text = "MAX"
	else:
		_cost_label.text = "%d pt" % upgrade.cost
	if focused:
		modulate = FOCUSED_COLOR
	else:
		modulate = Color.WHITE if GameState.can_buy(upgrade) else UNAVAILABLE_COLOR
