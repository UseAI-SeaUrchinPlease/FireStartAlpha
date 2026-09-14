extends Node

const ASH_PER_DAY := 5

var save_path := "user://meta.json"
var ash: int = 0
var best_day: int = 0
var last_ash_gain: int = 0
var unlocks: Dictionary[StringName, bool] = {}

var _unlock_types: Array[UnlockData] = []


func _ready() -> void:
	for resource in DataDir.load_all("res://data/unlocks"):
		_unlock_types.append(resource as UnlockData)
	load_from_disk()


func all_unlocks() -> Array[UnlockData]:
	return _unlock_types


func is_unlocked(unlock: UnlockData) -> bool:
	return unlocks.has(unlock.id)


func active_unlocks() -> Array[UnlockData]:
	return _unlock_types.filter(is_unlocked)


func can_buy(unlock: UnlockData) -> bool:
	return not is_unlocked(unlock) and ash >= unlock.cost


func buy_unlock(unlock: UnlockData) -> bool:
	if not can_buy(unlock):
		return false
	ash -= unlock.cost
	unlocks[unlock.id] = true
	save_to_disk()
	return true


func record_run(days_survived: int) -> void:
	last_ash_gain = days_survived * ASH_PER_DAY
	ash += last_ash_gain
	best_day = maxi(best_day, days_survived)
	save_to_disk()


func reset_progress() -> void:
	ash = 0
	best_day = 0
	last_ash_gain = 0
	unlocks.clear()


func load_from_disk() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not (data is Dictionary):
		return
	ash = int(data.get("ash", 0))
	best_day = int(data.get("best_day", 0))
	unlocks.clear()
	for key: String in data.get("unlocks", []):
		unlocks[StringName(key)] = true


func save_to_disk() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	var unlock_names: Array[String] = []
	for key: StringName in unlocks:
		unlock_names.append(String(key))
	file.store_string(JSON.stringify({
		"ash": ash,
		"best_day": best_day,
		"unlocks": unlock_names,
	}))
