extends Node

@onready var _phase_root: Node = %PhaseRoot
@onready var _phase_label: Label = %PhaseLabel


func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	PhaseManager.phase_root = _phase_root
	PhaseManager.start()


func _on_phase_changed(phase_name: StringName) -> void:
	_phase_label.text = "Day %d - %s" % [GameState.day, phase_name]
