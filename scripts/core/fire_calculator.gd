class_name FireCalculator
extends RefCounted

const REWARD_STEP := 10.0


static func temperature(contributions: Dictionary[ItemData, int]) -> float:
	var total := 0.0
	for item: ItemData in contributions:
		total += item.heat * contributions[item]
	return total


static func reward_points(reached: float, target: float) -> int:
	return maxi(0, int(floor((reached - target) / REWARD_STEP)))


## 役割ごとに、day 時点で有効な条件のうち最も新しいものを返す。
static func active_requirements(all: Array[FireRequirement], day: int) -> Array[FireRequirement]:
	var latest: Dictionary[ItemData.FireRole, FireRequirement] = {}
	for requirement in all:
		if requirement.min_day > day:
			continue
		var current: FireRequirement = latest.get(requirement.role)
		if current == null or requirement.min_day > current.min_day:
			latest[requirement.role] = requirement
	return _sorted_by_role(latest)


## 役割ごとに、day より後で最初に切り替わる条件を返す。
static func upcoming_requirements(all: Array[FireRequirement], day: int) -> Array[FireRequirement]:
	var earliest: Dictionary[ItemData.FireRole, FireRequirement] = {}
	for requirement in all:
		if requirement.min_day <= day:
			continue
		var current: FireRequirement = earliest.get(requirement.role)
		if current == null or requirement.min_day < current.min_day:
			earliest[requirement.role] = requirement
	return _sorted_by_role(earliest)


static func unmet_requirements(contributions: Dictionary[ItemData, int], requirements: Array[FireRequirement]) -> Array[FireRequirement]:
	var unmet: Array[FireRequirement] = []
	for requirement in requirements:
		var total := 0
		for item: ItemData in contributions:
			if requirement.accepts(item):
				total += contributions[item]
		if total < requirement.count:
			unmet.append(requirement)
	return unmet


static func _sorted_by_role(by_role: Dictionary[ItemData.FireRole, FireRequirement]) -> Array[FireRequirement]:
	var result: Array[FireRequirement] = []
	for role: ItemData.FireRole in ItemData.ROLE_NAMES:
		if by_role.has(role):
			result.append(by_role[role])
	return result
