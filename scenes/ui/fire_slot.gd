class_name FireSlot
extends PanelContainer

# 陽だまりの枯れ枝 is TINDER inside the code but counts as 燃料 on screen (0048).
const ROLE_NAMES: Dictionary[ItemData.FireRole, String] = {
	ItemData.FireRole.FUEL: "燃料",
	ItemData.FireRole.TINDER: "燃料",
	ItemData.FireRole.IGNITER: "着火具",
}
const FOCUSED_COLOR := Color(1.0, 0.9, 0.4)

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
	if not is_node_ready() or item == null:
		return
	_role_label.text = ROLE_NAMES[item.fire_role]
	_item_label.text = item.display_name
	_count_label.text = "%d / %d" % [count, available]
	modulate = FOCUSED_COLOR if focused else Color.WHITE
