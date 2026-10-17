class_name TimingBar
extends Control
## 横に流れるカーソルを、当たり範囲に重なったときに止めるタイミングバー。

signal judged(hit: bool)

const SWEEP_SECONDS := 0.9
const ZONE_WIDTH := 0.16
const FLASH_SECONDS := 0.25
const BG_COLOR := Color(0.15, 0.12, 0.1)
const ZONE_COLOR := Color(1.0, 0.55, 0.15)
const CURSOR_COLOR := Color(1.0, 0.95, 0.6)
const HIT_COLOR := Color(0.5, 1.0, 0.5)
const MISS_COLOR := Color(1.0, 0.3, 0.3)

var running := false
var _position := 0.0
var _direction := 1.0
var _zone_start := 0.5 - ZONE_WIDTH / 2.0
var _flash := 0.0
var _flash_color := Color.WHITE


func start() -> void:
	running = true
	_position = 0.0
	_direction = 1.0
	_zone_start = randf_range(0.35, 1.0 - ZONE_WIDTH - 0.05)
	queue_redraw()


func stop() -> void:
	running = false
	queue_redraw()


## カーソルを止めて判定する。当たり範囲に入っていれば true。
func press() -> bool:
	if not running:
		return false
	var hit := _in_zone()
	_flash = FLASH_SECONDS
	_flash_color = HIT_COLOR if hit else MISS_COLOR
	judged.emit(hit)
	return hit


func _process(delta: float) -> void:
	if running:
		_position += _direction * delta / SWEEP_SECONDS
		if _position >= 1.0:
			_position = 1.0
			_direction = -1.0
		elif _position <= 0.0:
			_position = 0.0
			_direction = 1.0
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()


func _in_zone() -> bool:
	return _position >= _zone_start and _position <= _zone_start + ZONE_WIDTH


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)
	draw_rect(Rect2(_zone_start * size.x, 0.0, ZONE_WIDTH * size.x, size.y), ZONE_COLOR)
	var cursor_color := _flash_color if _flash > 0.0 else CURSOR_COLOR
	draw_rect(Rect2(_position * size.x - 2.0, -3.0, 4.0, size.y + 6.0), cursor_color)
