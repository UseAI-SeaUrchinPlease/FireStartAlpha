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
var upgrades: Dictionary[UpgradeData, int] = {}


func reset() -> void:
	day = 1
	max_hp = START_HP
	hp = max_hp
	fire_points = 0
	inventory.clear()
	upgrades.clear()
	inventory_changed.emit()
	hp_changed.emit()


func advance_day() -> void:
	day += 1


func target_temperature() -> float:
	return BASE_TARGET_TEMPERATURE + TARGET_TEMPERATURE_PER_DAY * (day - 1)


func attack_damage() -> int:
	var total := 1
	for upgrade: UpgradeData in upgrades:
		total += upgrade.attack_bonus * upgrades[upgrade]
	return total


func dig_speed_multiplier() -> float:
	var total := 1.0
	for upgrade: UpgradeData in upgrades:
		total += upgrade.dig_speed_bonus * upgrades[upgrade]
	return total


func upgrade_level(upgrade: UpgradeData) -> int:
	return upgrades.get(upgrade, 0)


func can_buy(upgrade: UpgradeData) -> bool:
	if fire_points < upgrade.cost:
		return false
	return upgrade.max_level == 0 or upgrade_level(upgrade) < upgrade.max_level


func buy_upgrade(upgrade: UpgradeData) -> bool:
	if not can_buy(upgrade):
		return false
	fire_points -= upgrade.cost
	upgrades[upgrade] = upgrade_level(upgrade) + 1
	max_hp += upgrade.max_hp_bonus
	hp = mini(hp + upgrade.max_hp_bonus + upgrade.heal, max_hp)
	hp_changed.emit()
	return true


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


func damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	hp_changed.emit()
