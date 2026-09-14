class_name FireCalculator
extends RefCounted

const REWARD_STEP := 10.0


static func temperature(contributions: Dictionary[ItemData, int]) -> float:
	if not _has_role(contributions, ItemData.FireRole.TINDER):
		return 0.0
	if not _has_role(contributions, ItemData.FireRole.IGNITER):
		return 0.0
	var total := 0.0
	for item: ItemData in contributions:
		total += item.heat * contributions[item]
	return total


static func reward_points(reached: float, target: float) -> int:
	return 1 + int(floor((reached - target) / REWARD_STEP))


static func _has_role(contributions: Dictionary[ItemData, int], role: ItemData.FireRole) -> bool:
	for item: ItemData in contributions:
		if item.fire_role == role and contributions[item] > 0:
			return true
	return false
