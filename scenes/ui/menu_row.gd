class_name MenuRow
extends PanelContainer

const FOCUSED_COLOR := Color(1.0, 0.9, 0.4)
const UNAVAILABLE_COLOR := Color(0.55, 0.55, 0.55)

var focused := false:
	set(value):
		focused = value
		_apply_color()
var available := true:
	set(value):
		available = value
		_apply_color()

@onready var _name_label: Label = %NameLabel
@onready var _detail_label: Label = %DetailLabel
@onready var _cost_label: Label = %CostLabel


func _ready() -> void:
	_apply_color()


func set_texts(name_text: String, detail_text: String, cost_text: String) -> void:
	_name_label.text = name_text
	_detail_label.text = detail_text
	_cost_label.text = cost_text


func _apply_color() -> void:
	if not is_node_ready():
		return
	if focused:
		modulate = FOCUSED_COLOR
	else:
		modulate = Color.WHITE if available else UNAVAILABLE_COLOR
