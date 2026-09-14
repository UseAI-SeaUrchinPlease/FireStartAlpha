extends GamePhase

@onready var _days_label: Label = %DaysLabel


func _ready() -> void:
	_days_label.text = "%d日目で力尽きた" % GameState.day


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		finish()
