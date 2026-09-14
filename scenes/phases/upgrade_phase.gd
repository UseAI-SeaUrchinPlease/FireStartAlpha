extends GamePhase

const PLACEHOLDER_DURATION := 1.5


func _ready() -> void:
	get_tree().create_timer(PLACEHOLDER_DURATION).timeout.connect(finish)
