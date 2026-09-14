class_name FireSlot
extends PanelContainer

const ROLE_NAMES: Dictionary[ItemData.FireRole, String] = {
	ItemData.FireRole.FUEL: "燃料",
	ItemData.FireRole.TINDER: "火口",
	ItemData.FireRole.IGNITER: "着火",
}
const FOCUSED_COLOR := Color(1.0, 0.9, 0.4)

@export var role: ItemData.FireRole = ItemData.FireRole.FUEL

var item: ItemData
var count := 0
var available := 0
var focused := false:
	set(value):
		focused = value
		_refresh()

@onready var _role_label: Label = %RoleLabel
@onready var _item_label: Label = %ItemLabel
@onready var _count_label: Label = %CountLabel


func _ready() -> void:
	_refresh()


func setup(new_item: ItemData, new_available: int) -> void:
	item = new_item
	available = new_available
	count = available
	_refresh()


func change_count(delta: int) -> void:
	count = clampi(count + delta, 0, available)
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	_role_label.text = ROLE_NAMES[role]
	_item_label.text = item.display_name if item else "なし"
	_count_label.text = "%d / %d" % [count, available]
	modulate = FOCUSED_COLOR if focused else Color.WHITE
