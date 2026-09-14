extends Node

enum Phase { TITLE, DAY, FIRE, UPGRADE, GAME_OVER }

const PHASE_SCENES: Dictionary[Phase, PackedScene] = {
	Phase.TITLE: preload("res://scenes/main/Title.tscn"),
	Phase.DAY: preload("res://scenes/phases/DayPhase.tscn"),
	Phase.FIRE: preload("res://scenes/phases/FirePhase.tscn"),
	Phase.UPGRADE: preload("res://scenes/phases/UpgradePhase.tscn"),
	Phase.GAME_OVER: preload("res://scenes/main/GameOver.tscn"),
}

var phase_root: Node
var current_phase: Phase
var _current_scene: GamePhase


func start() -> void:
	_enter(Phase.TITLE)


func start_run() -> void:
	GameState.reset()
	GameState.apply_unlocks(MetaProgress.active_unlocks())
	_enter(Phase.DAY)


func current_scene() -> GamePhase:
	return _current_scene


func _enter(phase: Phase) -> void:
	if _current_scene:
		_current_scene.queue_free()
	current_phase = phase
	_current_scene = PHASE_SCENES[phase].instantiate()
	_current_scene.finished.connect(_on_phase_finished.bind(phase))
	_current_scene.failed.connect(_on_phase_failed)
	phase_root.add_child(_current_scene)
	var phase_name: StringName = Phase.find_key(phase)
	print("[PhaseManager] day=%d phase=%s" % [GameState.day, phase_name])
	EventBus.phase_changed.emit(phase_name)
	if phase == Phase.DAY:
		EventBus.day_started.emit(GameState.day)


func _on_phase_finished(phase: Phase) -> void:
	match phase:
		Phase.TITLE:
			start_run()
		Phase.DAY:
			_enter(Phase.FIRE)
		Phase.FIRE:
			_enter(Phase.UPGRADE)
		Phase.UPGRADE:
			GameState.advance_day()
			_enter(Phase.DAY)
		Phase.GAME_OVER:
			_enter(Phase.TITLE)


func _on_phase_failed() -> void:
	MetaProgress.record_run(GameState.day)
	_enter(Phase.GAME_OVER)
