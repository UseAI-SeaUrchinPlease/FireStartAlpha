extends Node

const START_HP := 10

var day: int = 1
var hp: int = START_HP
var max_hp: int = START_HP
var inventory: Dictionary[StringName, int] = {}
var upgrade_levels: Dictionary[StringName, int] = {}


func reset() -> void:
	day = 1
	max_hp = START_HP
	hp = max_hp
	inventory.clear()
	upgrade_levels.clear()


func advance_day() -> void:
	day += 1
