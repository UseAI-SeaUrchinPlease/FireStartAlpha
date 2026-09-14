extends Node

signal inventory_changed
signal hp_changed

const START_HP := 10
const BASE_TARGET_TEMPERATURE := 100.0
const TARGET_TEMPERATURE_PER_DAY := 30.0

var day: int = 1
var hp: int = START_HP
var max_hp: int = START_HP
var fire_points: int = 0
var inventory: Dictionary[ItemData, int] = {}
var upgrade_levels: Dictionary[StringName, int] = {}


func reset() -> void:
	day = 1
	max_hp = START_HP
	hp = max_hp
	fire_points = 0
	inventory.clear()
	upgrade_levels.clear()
	inventory_changed.emit()


func advance_day() -> void:
	day += 1


func target_temperature() -> float:
	return BASE_TARGET_TEMPERATURE + TARGET_TEMPERATURE_PER_DAY * (day - 1)


func attack_damage() -> int:
	return 1 + upgrade_levels.get(&"attack", 0)


func damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	hp_changed.emit()


func add_item(item: ItemData, count: int = 1) -> void:
	inventory[item] = inventory.get(item, 0) + count
	inventory_changed.emit()


func remove_item(item: ItemData, count: int) -> void:
	var left: int = inventory.get(item, 0) - count
	if left <= 0:
		inventory.erase(item)
	else:
		inventory[item] = left
	inventory_changed.emit()
