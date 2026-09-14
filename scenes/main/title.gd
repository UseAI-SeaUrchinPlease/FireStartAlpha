extends GamePhase

const ROW_SCENE := preload("res://scenes/ui/MenuRow.tscn")

var _unlocks: Array[UnlockData] = []
var _rows: Array[MenuRow] = []
var _focus := 0

@onready var _best_label: Label = %BestLabel
@onready var _ash_label: Label = %AshLabel
@onready var _rows_container: VBoxContainer = %Rows


func _ready() -> void:
	_unlocks = MetaProgress.all_unlocks()
	for i in _unlocks.size() + 1:
		var row: MenuRow = ROW_SCENE.instantiate()
		_rows_container.add_child(row)
		_rows.append(row)
	set_focus(0)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_down"):
		set_focus(_focus + 1)
		Audio.play(&"menu_move")
	elif event.is_action_pressed("move_up"):
		set_focus(_focus - 1)
		Audio.play(&"menu_move")
	elif event.is_action_pressed("interact"):
		activate_focused()


func activate_focused() -> void:
	if _focus == 0:
		Audio.play(&"menu_select")
		finish()
		return
	if MetaProgress.buy_unlock(_unlocks[_focus - 1]):
		Audio.play(&"pickup")
		_refresh()


func set_focus(index: int) -> void:
	_focus = wrapi(index, 0, _rows.size())
	for i in _rows.size():
		_rows[i].focused = i == _focus


func _refresh() -> void:
	_best_label.text = "さいこう記録: %d日" % MetaProgress.best_day
	_ash_label.text = "灰: %d" % MetaProgress.ash
	_rows[0].set_texts("はじめる", "", "")
	_rows[0].available = true
	for i in _unlocks.size():
		var unlock := _unlocks[i]
		var unlocked := MetaProgress.is_unlocked(unlock)
		_rows[i + 1].set_texts(unlock.display_name, unlock.description, "解放済" if unlocked else "灰 %d" % unlock.cost)
		_rows[i + 1].available = unlocked or MetaProgress.can_buy(unlock)
