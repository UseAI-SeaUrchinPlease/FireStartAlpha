class_name FirePhase
extends GamePhase

signal cancelled

const RESULT_DELAY := 2.0
const FLAME_PER_DEGREE := 0.4
const FLAME_MIN := 24
const FLAME_MAX := 140

var can_cancel := false

var _slots: Array[FireSlot] = []
var _focus := 0
var _resolved := false

@onready var _title_label: Label = %TitleLabel
@onready var _predict_label: Label = %PredictLabel
@onready var _temp_gauge: ProgressBar = %TempGauge
@onready var _result_label: Label = %ResultLabel
@onready var _flame: CPUParticles2D = %Flame
@onready var _smoke: CPUParticles2D = %Smoke
@onready var _fuel_slot: FireSlot = %FuelSlot
@onready var _tinder_slot: FireSlot = %TinderSlot
@onready var _igniter_slot: FireSlot = %IgniterSlot
@onready var _back_label: Label = %BackLabel
@onready var _hint_label: Label = %HintLabel


func _ready() -> void:
	_slots = [_fuel_slot, _tinder_slot, _igniter_slot]
	for slot in _slots:
		var item := _find_item(slot.role)
		slot.setup(item, GameState.inventory.get(item, 0) if item else 0)
	_title_label.text = "%d日目   着火   足切り %d°" % [GameState.day, GameState.target_temperature()]
	_back_label.visible = can_cancel
	if can_cancel:
		_hint_label.text += "\n戻る を選んで E  昼に戻る"
	_temp_gauge.max_value = GameState.target_temperature()
	_set_focus(0)
	_refresh_prediction()


func _unhandled_input(event: InputEvent) -> void:
	if _resolved:
		return
	if event.is_action_pressed("move_right"):
		_set_focus(_focus + 1)
		Audio.play(&"menu_move")
	elif event.is_action_pressed("move_left"):
		_set_focus(_focus - 1)
		Audio.play(&"menu_move")
	elif event.is_action_pressed("interact"):
		# The day resumes inside cancel(); without this the same press reopens the ignition screen.
		get_viewport().set_input_as_handled()
		if _focus == _slots.size():
			cancel()
		else:
			ignite()
	elif _focus == _slots.size():
		return
	elif event.is_action_pressed("move_up"):
		_slots[_focus].change_count(1)
		_refresh_prediction()
		Audio.play(&"menu_move")
	elif event.is_action_pressed("move_down"):
		_slots[_focus].change_count(-1)
		_refresh_prediction()
		Audio.play(&"menu_move")


func cancel() -> void:
	if _resolved or not can_cancel:
		return
	_resolved = true
	Audio.play(&"menu_select")
	cancelled.emit()


func ignite() -> void:
	if _resolved:
		return
	_resolved = true
	var contributions := _contributions()
	var temperature := FireCalculator.temperature(contributions)
	var target := GameState.target_temperature()
	for item: ItemData in contributions:
		GameState.remove_item(item, contributions[item])
	if temperature >= target:
		GameState.fire_points = FireCalculator.reward_points(temperature, target)
		_result_label.text = "火がついた！  %d°   +%d ポイント" % [temperature, GameState.fire_points]
		_flame.amount = clampi(int(temperature * FLAME_PER_DEGREE), FLAME_MIN, FLAME_MAX)
		_flame.emitting = true
		Audio.play(&"fire_success")
		await get_tree().create_timer(RESULT_DELAY).timeout
		finish()
	else:
		_result_label.text = "火がつかなかった…  %d° / %d°" % [temperature, target]
		_smoke.restart()
		Audio.play(&"fire_fail")
		await get_tree().create_timer(RESULT_DELAY).timeout
		fail()


func _set_focus(index: int) -> void:
	var targets := _slots.size() + (1 if can_cancel else 0)
	_focus = wrapi(index, 0, targets)
	for i in _slots.size():
		_slots[i].focused = i == _focus
	_back_label.modulate = FireSlot.FOCUSED_COLOR if _focus == _slots.size() else Color.WHITE


func _find_item(role: ItemData.FireRole) -> ItemData:
	for item: ItemData in GameState.inventory:
		if item.fire_role == role and GameState.inventory[item] > 0:
			return item
	return null


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
