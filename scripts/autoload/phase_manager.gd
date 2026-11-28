extends Node

enum Phase { TITLE, DAY, FIRE, NIGHT, UPGRADE, GAME_OVER }

const PHASE_SCENES: Dictionary[Phase, PackedScene] = {
	Phase.TITLE: preload("res://scenes/main/Title.tscn"),
	Phase.DAY: preload("res://scenes/phases/DayPhase.tscn"),
	Phase.FIRE: preload("res://scenes/phases/FirePhase.tscn"),
	Phase.NIGHT: preload("res://scenes/phases/NightPhase.tscn"),
	Phase.UPGRADE: preload("res://scenes/phases/UpgradePhase.tscn"),
	Phase.GAME_OVER: preload("res://scenes/main/GameOver.tscn"),
}

var phase_root: Node
var current_phase: Phase
var _current_scene: GamePhase
# The day scene stays paused under the ignition screen so the night can reuse its world.
var _paused_day: GamePhase


func start() -> void:
	_enter(Phase.TITLE)


func start_run() -> void:
	GameState.reset()
	GameState.apply_unlocks(MetaProgress.active_unlocks())
	_enter(Phase.DAY)


func current_scene() -> GamePhase:
	return _current_scene


func _enter(phase: Phase, properties: Dictionary = {}) -> void:
	if _current_scene and _current_scene != _paused_day:
		_current_scene.queue_free()
	current_phase = phase
	_current_scene = PHASE_SCENES[phase].instantiate()
	for key: String in properties:
		_current_scene.set(key, properties[key])
	_current_scene.finished.connect(_on_phase_finished.bind(phase))
	_current_scene.failed.connect(_on_phase_failed)
	if _current_scene is DayPhase:
		(_current_scene as DayPhase).ignite_requested.connect(_open_fire.bind(true))
	elif _current_scene is FirePhase:
		(_current_scene as FirePhase).cancelled.connect(_close_fire)
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
			_open_fire(false)
		Phase.FIRE:
			_enter_night()
		Phase.NIGHT:
			_enter(Phase.UPGRADE)
		Phase.UPGRADE:
			GameState.advance_day()
			_enter(Phase.DAY)
		Phase.GAME_OVER:
			_enter(Phase.TITLE)


func _on_phase_failed() -> void:
	MetaProgress.record_run(GameState.day)
	_free_paused_day()
	_enter(Phase.GAME_OVER)


func _open_fire(can_cancel: bool) -> void:
	_paused_day = _current_scene
	_paused_day.process_mode = Node.PROCESS_MODE_DISABLED
	_enter(Phase.FIRE, {"can_cancel": can_cancel})


func _close_fire() -> void:
	_current_scene.queue_free()
	_current_scene = _paused_day
	_paused_day = null
	_current_scene.process_mode = Node.PROCESS_MODE_INHERIT
	current_phase = Phase.DAY
	EventBus.phase_changed.emit(Phase.find_key(Phase.DAY))


func _enter_night() -> void:
	var day := _paused_day as DayPhase
	_enter(Phase.NIGHT, {"world": day.world, "player": day.player})
	_free_paused_day()


func _free_paused_day() -> void:
	if _paused_day:
		_paused_day.queue_free()
		_paused_day = null
