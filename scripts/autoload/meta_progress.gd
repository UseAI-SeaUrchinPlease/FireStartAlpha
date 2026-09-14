extends Node

const SAVE_PATH := "user://meta.json"

var ash: int = 0
var best_day: int = 0
var unlocks: Dictionary[StringName, bool] = {}


func _ready() -> void:
	load_from_disk()


func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not (data is Dictionary):
		return
	ash = int(data.get("ash", 0))
	best_day = int(data.get("best_day", 0))
	unlocks.clear()
	for key: String in data.get("unlocks", []):
		unlocks[StringName(key)] = true


func save_to_disk() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var unlock_names: Array[String] = []
	for key: StringName in unlocks:
		unlock_names.append(String(key))
	file.store_string(JSON.stringify({
		"ash": ash,
		"best_day": best_day,
		"unlocks": unlock_names,
	}))
