extends Node

const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")
const ZOMBIE_DATA: EnemyData = preload("res://data/enemies/zombie.tres")
const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const DAY_PHASE_SCRIPT := preload("res://scenes/phases/day_phase.gd")
## これより長く止まっていたら「引っかかった」とみなす
const STALL_LIMIT := 0.5
const MOVE_SECONDS := 12.0

var _failures := 0


func _ready() -> void:
	_run()


func _run() -> void:
	GameState.reset()
	var day1 := await _spawn()
	_check(day1._hp == ZOMBIE_DATA.max_hp, "day 1 has the base HP")
	_check(day1._damage == ZOMBIE_DATA.damage, "day 1 has the base damage")
	_check(is_equal_approx(day1._speed, ZOMBIE_DATA.speed), "day 1 has the base speed")
	day1.queue_free()

	GameState.day = 5
	var day5 := await _spawn()
	var offset := 4
	_check(
		day5._hp == int(ZOMBIE_DATA.max_hp + ZOMBIE_DATA.hp_growth_per_day * offset),
		"hp grows with days elapsed"
	)
	_check(
		day5._damage == int(ZOMBIE_DATA.damage + ZOMBIE_DATA.damage_growth_per_day * offset),
		"damage grows with days elapsed"
	)
	_check(
		is_equal_approx(day5._speed, ZOMBIE_DATA.speed + ZOMBIE_DATA.speed_growth_per_day * offset),
		"speed grows with days elapsed"
	)
	day5.queue_free()

	GameState.day = 50
	var day50 := await _spawn()
	_check(
		is_equal_approx(day50._speed, ZOMBIE_DATA.max_speed),
		"speed growth is capped at max_speed on a very late day"
	)
	day50.queue_free()

	await _check_steering()
	await _check_moves_around_obstacles()

	_check(
		ZOMBIE_DATA.aggro_range >= DAY_PHASE_SCRIPT.SPAWN_MAX_DISTANCE + GameWorld.TILE_SIZE,
		"a zombie chases from anywhere it can spawn (aggro_range covers the spawn distance plus cell snapping)"
	)

	if _failures == 0:
		print("test_enemy: OK")
	get_tree().quit(1 if _failures > 0 else 0)


## 次のセルの中心へ向かうので、列の中心からずれていれば戻る成分を持つこと。
func _check_steering() -> void:
	GameState.reset()
	var world: GameWorld = WORLD_SCENE.instantiate()
	add_child(world)
	var map := MapData.new()
	map.width = 10
	map.height = 5
	world.build(map)
	var target := Node2D.new()
	world.add_child(target)
	target.global_position = world.cell_center(Vector2i(8, 2))
	world.flow_field = world.compute_flow_field(Vector2i(8, 2), 10)

	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = ZOMBIE_DATA
	enemy.target = target
	enemy.world = world
	world.add_child(enemy)
	enemy.set_physics_process(false)
	await get_tree().process_frame
	enemy.global_position = world.cell_center(Vector2i(3, 2)) + Vector2(0.0, 5.0)
	var velocity := enemy._compute_velocity()
	_check(velocity.x > 0.0 and velocity.y < 0.0, "an enemy off its row's center steers back toward it while moving along the row (got %s)" % velocity)
	_check(is_equal_approx(velocity.length(), enemy._speed), "steering keeps the enemy's speed")

	enemy.global_position = world.cell_center(Vector2i(8, 2)) + Vector2(-6.0, 0.0)
	velocity = enemy._compute_velocity()
	_check(velocity.x > 0.0 and is_zero_approx(velocity.y), "in the player's own cell the enemy heads straight for the player (got %s)" % velocity)
	world.queue_free()

	# 一度追い始めたら、迂回などで直線距離が aggro_range を超えても追い続ける
	var long_world: GameWorld = WORLD_SCENE.instantiate()
	add_child(long_world)
	var long_map := MapData.new()
	long_map.width = 40
	long_map.height = 3
	long_world.build(long_map)
	var far_target := Node2D.new()
	long_world.add_child(far_target)
	far_target.global_position = long_world.cell_center(Vector2i(38, 1))
	long_world.flow_field = long_world.compute_flow_field(Vector2i(38, 1), 40)
	var chaser := await _spawn_in(long_world, far_target)
	chaser.global_position = long_world.cell_center(Vector2i(20, 1))
	chaser._compute_velocity()
	chaser.global_position = long_world.cell_center(Vector2i(2, 1))
	_check(chaser._compute_velocity() != Vector2.ZERO, "an enemy that started chasing keeps chasing beyond aggro_range")
	var idle := await _spawn_in(long_world, far_target)
	idle.global_position = long_world.cell_center(Vector2i(2, 1))
	_check(idle._compute_velocity() == Vector2.ZERO, "an enemy that never got close does not start chasing from beyond aggro_range")
	long_world.queue_free()


func _spawn_in(world: GameWorld, target: Node2D) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = ZOMBIE_DATA
	enemy.target = target
	enemy.world = world
	world.add_child(enemy)
	enemy.set_physics_process(false)
	await get_tree().process_frame
	return enemy


## 実際に動かして、壁の隙間・単独のブロックの角・U字の囲いを抜けてゴールに着き、
## 途中で STALL_LIMIT 以上止まらないこと (PR #11 レビュー: 角に引っかかって止まる)。
func _check_moves_around_obstacles() -> void:
	GameState.reset()
	var world: GameWorld = WORLD_SCENE.instantiate()
	add_child(world)
	var map := MapData.new()
	map.width = 24
	map.height = 14
	for y in range(1, 13):
		if y != 7:
			map.cells[Vector2i(12, y)] = &"rock"   # 隙間1マスだけの壁
	for cell in [Vector2i(5, 3), Vector2i(6, 8), Vector2i(8, 5), Vector2i(9, 11), Vector2i(16, 4), Vector2i(17, 10), Vector2i(15, 7)]:
		map.cells[cell] = &"tree"   # 単独のブロック
	for cell in [Vector2i(4, 9), Vector2i(4, 10), Vector2i(4, 11), Vector2i(5, 11), Vector2i(6, 11), Vector2i(7, 9), Vector2i(7, 10), Vector2i(7, 11)]:
		map.cells[cell] = &"rock"   # 上が開いた U字
	world.build(map)
	var goal := Vector2i(20, 7)
	var target := Node2D.new()
	world.add_child(target)
	target.global_position = world.cell_center(goal)
	world.flow_field = world.compute_flow_field(goal, 30)

	var enemies: Array[Enemy] = []
	for start in [Vector2i(1, 1), Vector2i(2, 6), Vector2i(1, 12), Vector2i(5, 10), Vector2i(9, 2), Vector2i(10, 12), Vector2i(3, 4)]:
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.data = ZOMBIE_DATA
		enemy.target = target
		enemy.world = world
		world.add_child(enemy)
		enemy.global_position = world.cell_center(start) + Vector2(3.0, -2.0)
		enemies.append(enemy)

	var last_positions: Array[Vector2] = []
	var stalled: Array[float] = []
	var longest: Array[float] = []
	for enemy in enemies:
		last_positions.append(enemy.global_position)
		stalled.append(0.0)
		longest.append(0.0)
	var step := 1.0 / Engine.physics_ticks_per_second
	for frame in int(MOVE_SECONDS * Engine.physics_ticks_per_second):
		await get_tree().physics_frame
		for i in enemies.size():
			var enemy := enemies[i]
			var arrived := world.cell_at(enemy.global_position).distance_to(goal) <= 1.0
			if arrived or enemy.global_position.distance_to(last_positions[i]) > 0.05:
				stalled[i] = 0.0
			else:
				stalled[i] += step
				longest[i] = maxf(longest[i], stalled[i])
			last_positions[i] = enemy.global_position

	for i in enemies.size():
		var enemy := enemies[i]
		_check(world.cell_at(enemy.global_position).distance_to(goal) <= 1.0, "enemy %d reaches the goal around the obstacles (ended at %s)" % [i, world.cell_at(enemy.global_position)])
		_check(longest[i] < STALL_LIMIT, "enemy %d never stalls on a corner for %.1fs or more (longest %.2fs)" % [i, STALL_LIMIT, longest[i]])
	world.queue_free()


func _spawn() -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = ZOMBIE_DATA
	add_child(enemy)
	await get_tree().process_frame
	return enemy


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
