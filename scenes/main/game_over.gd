extends GamePhase

@onready var _days_label: Label = %DaysLabel
@onready var _ash_label: Label = %AshLabel


func _ready() -> void:
	_days_label.text = "%d日目で力尽きた" % GameState.day
	_ash_label.text = "灰 +%d   (合計 %d)" % [MetaProgress.last_ash_gain, MetaProgress.ash]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		Audio.play(&"menu_select")
		finish()
