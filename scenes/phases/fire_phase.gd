extends GamePhase

const ROW_SCENE := preload("res://scenes/ui/FireSlot.tscn")
const RESULT_DELAY := 2.0
const FLAME_PER_DEGREE := 0.4
const FLAME_MIN := 24
const FLAME_MAX := 140

var _slots: Array[FireSlot] = []
var _requirements: Array[FireRequirement] = []
var _focus := 0
var _resolved := false

@onready var _title_label: Label = %TitleLabel
@onready var _predict_label: Label = %PredictLabel
@onready var _temp_gauge: ProgressBar = %TempGauge
@onready var _result_label: Label = %ResultLabel
@onready var _flame: CPUParticles2D = %Flame
@onready var _smoke: CPUParticles2D = %Smoke
@onready var _columns: Dictionary[ItemData.FireRole, VBoxContainer] = {
	ItemData.FireRole.FUEL: %FuelColumn,
	ItemData.FireRole.IGNITER: %IgniterColumn,
}
@onready var _empty_label: Label = %EmptyLabel
@onready var _requirement_label: Label = %RequirementLabel


func _ready() -> void:
	_requirements = GameState.tonight_requirements()
	for item in _fire_items():
		var slot: FireSlot = ROW_SCENE.instantiate()
		_columns[item.fire_role].add_child(slot)
		slot.setup(item, GameState.inventory[item])
		_slots.append(slot)
	for column: VBoxContainer in _columns.values():
		column.visible = column.get_child_count() > 1
	_empty_label.visible = _slots.is_empty()
	_title_label.text = "%d日目の夜   目標 %d°" % [GameState.day, GameState.target_temperature()]
	_temp_gauge.max_value = GameState.target_temperature()
	_set_focus(0)
	_refresh_prediction()


func _unhandled_input(event: InputEvent) -> void:
	if _resolved:
		return
	if event.is_action_pressed("move_down"):
		_set_focus(_focus + 1)
		Audio.play(&"menu_move")
	elif event.is_action_pressed("move_up"):
		_set_focus(_focus - 1)
		Audio.play(&"menu_move")
	elif event.is_action_pressed("move_right"):
		_change_focused_count(1)
	elif event.is_action_pressed("move_left"):
		_change_focused_count(-1)
	elif event.is_action_pressed("interact"):
		ignite()


func ignite() -> void:
	if _resolved:
		return
	_resolved = true
	var contributions := _contributions()
	var temperature := FireCalculator.temperature(contributions)
	var target := GameState.target_temperature()
	var unmet := FireCalculator.unmet_requirements(contributions, _requirements)
	for item: ItemData in contributions:
		GameState.remove_item(item, contributions[item])
	if unmet.is_empty() and temperature >= target:
		GameState.fire_points = FireCalculator.reward_points(temperature, target)
		_result_label.text = "火がついた！  %d°   +%d ポイント" % [temperature, GameState.fire_points]
		_flame.amount = clampi(int(temperature * FLAME_PER_DEGREE), FLAME_MIN, FLAME_MAX)
		_flame.emitting = true
		Audio.play(&"fire_success")
		await get_tree().create_timer(RESULT_DELAY).timeout
		finish()
	else:
		if not unmet.is_empty():
			_result_label.text = "火がつかなかった…  たりない: %s" % "、".join(_describe_all(unmet))
		else:
			_result_label.text = "火がつかなかった…  %d° / %d°" % [temperature, target]
		_smoke.restart()
		Audio.play(&"fire_fail")
		await get_tree().create_timer(RESULT_DELAY).timeout
		fail()


func _set_focus(index: int) -> void:
	if _slots.is_empty():
		return
	_focus = wrapi(index, 0, _slots.size())
	for i in _slots.size():
		_slots[i].focused = i == _focus


func _change_focused_count(delta: int) -> void:
	if _slots.is_empty():
		return
	_slots[_focus].change_count(delta)
	_refresh_prediction()
	Audio.play(&"menu_move")


## 火起こしに使える所持素材を、役割(燃料 → 着火)、発熱量の低い順に並べる。
func _fire_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for item: ItemData in GameState.inventory:
		if item.fire_role != ItemData.FireRole.NONE and GameState.inventory[item] > 0:
			items.append(item)
	items.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		if a.fire_role != b.fire_role:
			return a.fire_role < b.fire_role
		return a.heat < b.heat)
	return items


func _contributions() -> Dictionary[ItemData, int]:
	var result: Dictionary[ItemData, int] = {}
	for slot in _slots:
		if slot.item != null and slot.count > 0:
			result[slot.item] = slot.count
	return result


func _refresh_prediction() -> void:
	var predicted := FireCalculator.temperature(_contributions())
	_predict_label.text = "予想 %d°" % predicted
	_temp_gauge.value = predicted
	var unmet := FireCalculator.unmet_requirements(_contributions(), _requirements)
	var marks: PackedStringArray = []
	for requirement in _requirements:
		marks.append("%s %s" % ["×" if requirement in unmet else "○", requirement.describe()])
	_requirement_label.text = "必須  " + "   ".join(marks)


func _describe_all(requirements: Array[FireRequirement]) -> PackedStringArray:
	var texts: PackedStringArray = []
	for requirement in requirements:
		texts.append(requirement.describe())
	return texts


func row_count() -> int:
	return _slots.size()


func row_item(index: int) -> ItemData:
	return _slots[index].item
