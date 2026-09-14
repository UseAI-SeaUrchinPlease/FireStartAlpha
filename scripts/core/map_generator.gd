class_name MapGenerator
extends RefCounted

const FOREST_FREQUENCY := 0.08
const FOREST_THRESHOLD := 0.25
const ROCK_FREQUENCY := 0.12
const ROCK_THRESHOLD := 0.4
const DIRT_FREQUENCY := 0.05
const DIRT_THRESHOLD := 0.3
const GRASS_TUFT_CHANCE := 0.04
const SPAWN_CLEARANCE := 3


static func generate(map_seed: int, width: int, height: int) -> MapData:
	var forest := _noise(map_seed, FOREST_FREQUENCY)
	var rocks := _noise(map_seed + 1, ROCK_FREQUENCY)
	var dirt := _noise(map_seed + 2, DIRT_FREQUENCY)
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed

	var data := MapData.new()
	data.width = width
	data.height = height
	data.spawn_cell = Vector2i(Vector2(width, height) * 0.5)

	for y in height:
		for x in width:
			var cell := Vector2i(x, y)
			data.ground[cell] = &"dirt_floor" if dirt.get_noise_2d(x, y) > DIRT_THRESHOLD else &"grass_floor"
			var tuft := rng.randf() < GRASS_TUFT_CHANCE
			if x == 0 or y == 0 or x == width - 1 or y == height - 1:
				data.cells[cell] = &"wall"
			elif cell.distance_to(data.spawn_cell) <= SPAWN_CLEARANCE:
				continue
			elif forest.get_noise_2d(x, y) > FOREST_THRESHOLD:
				data.cells[cell] = &"tree"
			elif rocks.get_noise_2d(x, y) > ROCK_THRESHOLD:
				data.cells[cell] = &"rock"
			elif tuft:
				data.cells[cell] = &"grass"
	return data


static func _noise(noise_seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = frequency
	return noise
