extends Node

signal inventory_changed

const START_HP := 10

var day: int = 1
var hp: int = START_HP
var max_hp: int = START_HP
var inventory: Dictionary[ItemData, int] = {}
var upgrade_levels: Dictionary[StringName, int] = {}


func reset() -> void:
	day = 1
	max_hp = START_HP
	hp = max_hp
	inventory.clear()
	upgrade_levels.clear()
	inventory_changed.emit()


func advance_day() -> void:
	day += 1


func add_item(item: ItemData, count: int = 1) -> void:
	inventory[item] = inventory.get(item, 0) + count
	inventory_changed.emit()
