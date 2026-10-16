extends Node

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	GameState.reset()
	var world: GameWorld = WORLD_SCENE.instantiate()
	add_child(world)
	world.set_physics_process(false) # 時間はテストから clock で進める
	var map := MapData.new()
	map.width = 12
	map.height = 6
	var tree := Vector2i(1, 1)
	var other_tree := Vector2i(2, 1)
	var ore := Vector2i(3, 1)
	var wall := Vector2i(4, 1)
	map.cells = {tree: &"tree", other_tree: &"tree", ore: &"iron_ore", wall: &"wall"}
	world.build(map)
	var tree_hits := world.get_block(tree).hits
	var dug: Array[Vector2i] = []
	world.block_dug.connect(func(cell: Vector2i, _block: BlockData) -> void: dug.append(cell))

	for i in tree_hits - 1:
		world.hit(tree, 0)
	_check(world.hit_count(tree) == tree_hits - 1, "each hit adds one to the cell's count")
	_check(world.get_block(tree) != null and dug.is_empty(), "the block survives until the last hit")
	_check(world.hit(tree, 0) == GameWorld.HitResult.BROKEN, "the hit reaching the block's count breaks it")
	_check(world.get_block(tree) == null and dug == [tree], "breaking removes the block and reports it")

	world.hit(other_tree, 0)
	world.hit(other_tree, 0)
	world.hit(ore, 1)
	_check(world.hit_count(other_tree) == 2, "hitting another cell keeps the first cell's count")
	world.clock += GameWorld.HIT_RESET_TIME - 0.1
	_check(world.hit_count(other_tree) == 2, "the count is kept while the reset time has not passed")
	world.clock += 0.2
	_check(world.hit_count(other_tree) == 0, "the count resets after the reset time without hits")
	world.hit(other_tree, 0)
	_check(world.hit_count(other_tree) == 1, "hitting again after a reset starts from one")

	_check(world.hit(ore, 0) == GameWorld.HitResult.BLOCKED, "a block needing a better tool is blocked")
	world.clock += GameWorld.HIT_RESET_TIME + 1.0
	world.hit(ore, 0)
	_check(world.hit_count(ore) == 0, "a blocked hit does not count")
	_check(world.hit(ore, 1) == GameWorld.HitResult.HIT, "the required tool level lets the hit through")
	_check(world.hit(wall, 99) == GameWorld.HitResult.NONE, "walls can never be dug")

	await _check_auto_repeat(world)

	if _failures == 0:
		print("test_digging: OK")
	get_tree().quit(1 if _failures > 0 else 0)


## 押しっぱなしで一定間隔ごとに叩き、連打してもその間隔より速くならないこと。
func _check_auto_repeat(world: GameWorld) -> void:
	var target := Vector2i(6, 3)
	world.map.cells[target] = &"rock"
	world.build(world.map)
	var player: Player = PLAYER_SCENE.instantiate()
	player.world = world
	world.add_child(player)
	player.global_position = world.cell_center(target + Vector2i(0, 1))
	player.set("_facing", Vector2.UP)

	# 物理は 60Hz なので、0.3秒 = 18フレーム。押してからの経過フレームで、叩いたタイミングを1回ずつ確認する
	var holding := func(_frame: int) -> bool: return true
	var frames := await _hit_frames(world, target, 37, holding)
	_check(frames == [0, 18, 36], "holding hits every 18 frames from the first press (got %s)" % [frames])

	var dig: UpgradeData = load("res://data/upgrades/dig.tres")
	GameState.upgrades[dig] = 4
	frames = await _hit_frames(world, target, 37, holding)
	_check(frames == [0, 9, 18, 27, 36], "max dig speed halves the interval to 9 frames (got %s)" % [frames])

	# 1Lv の 0.24秒 = 14.4フレームは、余りを繰り越して 0, 14.4, 28.8, 43.2, 57.6 の切り上げで叩く
	GameState.upgrades[dig] = 1
	frames = await _hit_frames(world, target, 60, holding)
	_check(frames == [0, 15, 29, 44, 58], "a fractional-frame interval keeps its average by carrying the remainder (got %s)" % [frames])
	GameState.upgrades.clear()

	# どんな押し方をしても、1回ごとの間隔が18フレームより短くならない
	var patterns: Dictionary[String, Callable] = {
		"1/1": func(frame: int) -> bool: return frame % 2 == 0,
		"2/2": func(frame: int) -> bool: return frame % 4 < 2,
		"3/1": func(frame: int) -> bool: return frame % 4 < 3,
		"18/1": func(frame: int) -> bool: return frame % 19 < 18,
		"1/16": func(frame: int) -> bool: return frame % 17 == 0,
	}
	for pattern: String in patterns:
		frames = await _hit_frames(world, target, 120, patterns[pattern])
		var shortest := 999
		for i in range(1, frames.size()):
			shortest = mini(shortest, frames[i] - frames[i - 1])
		_check(frames.size() >= 2 and shortest >= 18, "mashing %s never makes a gap shorter than 18 frames (got %s)" % [pattern, frames])
	GameState.upgrades.clear()
	player.queue_free()


## 待ち時間と叩いた回数を戻してから、frames フレームの間 pressed_at(経過フレーム) に従って
## 掘るボタンを押し、叩いたフレームの一覧を返す。
func _hit_frames(world: GameWorld, target: Vector2i, frames: int, pressed_at: Callable) -> Array[int]:
	Input.action_release("dig")
	world.clock += GameWorld.HIT_RESET_TIME + 1.0
	await _frames(20)
	var hits: Array[int] = []
	var last := world.hit_count(target)
	for frame in frames:
		if pressed_at.call(frame):
			Input.action_press("dig")
		else:
			Input.action_release("dig")
		await get_tree().physics_frame
		var count := world.hit_count(target)
		if count > last:
			hits.append(frame)
		last = count
	Input.action_release("dig")
	return hits


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
