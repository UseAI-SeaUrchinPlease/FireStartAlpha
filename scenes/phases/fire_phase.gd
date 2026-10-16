extends GamePhase

const RESULT_DELAY := 2.0
const MISS_COOLDOWN := 0.5
const FLAME_PER_DEGREE := 0.4
const FLAME_MIN := 24
const FLAME_MAX := 140

var _slots: Array[FireSlot] = []
var _focus := 0
var _resolved := false
var _retry_ready := true

@onready var _title_label: Label = %TitleLabel
@onready var _predict_label: Label = %PredictLabel
@onready var _temp_gauge: ProgressBar = %TempGauge
@onready var _result_label: Label = %ResultLabel
@onready var _timing_bar: TimingBar = %TimingBar
@onready var _flame: CPUParticles2D = %Flame
@onready var _smoke: CPUParticles2D = %Smoke
@onready var _fuel_slot: FireSlot = %FuelSlot
@onready var _tinder_slot: FireSlot = %TinderSlot
@onready var _igniter_slot: FireSlot = %IgniterSlot


func _ready() -> void:
	_slots = [_fuel_slot, _tinder_slot, _igniter_slot]
	for slot in _slots:
		var item := _find_item(slot.role)
		slot.setup(item, GameState.inventory.get(item, 0) if item else 0)
	_title_label.text = "%d日目の夜   目標 %d°" % [GameState.day, GameState.target_temperature()]
	_temp_gauge.max_value = GameState.target_temperature()
	_set_focus(0)
	_refresh_prediction()
	_timing_bar.start()


func _unhandled_input(event: InputEvent) -> void:
	if _resolved:
		return
	if event.is_action_pressed("move_right"):
		_set_focus(_focus + 1)
		Audio.play(&"menu_move")
	elif event.is_action_pressed("move_left"):
		_set_focus(_focus - 1)
		Audio.play(&"menu_move")
	elif event.is_action_pressed("move_up"):
		_slots[_focus].change_count(1)
		_refresh_prediction()
		Audio.play(&"menu_move")
	elif event.is_action_pressed("move_down"):
		_slots[_focus].change_count(-1)
		_refresh_prediction()
		Audio.play(&"menu_move")
	elif event.is_action_pressed("interact"):
		_try_ignite()


func _try_ignite() -> void:
	if not _retry_ready:
		return
	if _timing_bar.press():
		ignite()
		return
	_result_label.text = "ミス！  もういちど"
	Audio.play(&"fire_fail")
	_retry_ready = false
	await get_tree().create_timer(MISS_COOLDOWN).timeout
	_retry_ready = true
	if not _resolved:
		_result_label.text = ""


func ignite() -> void:
	if _resolved:
		return
	_resolved = true
	_timing_bar.stop()
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
	_focus = wrapi(index, 0, _slots.size())
	for i in _slots.size():
		_slots[i].focused = i == _focus


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
