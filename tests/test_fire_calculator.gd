extends SceneTree

var _failures := 0


func _init() -> void:
	var fuel := _item(ItemData.FireRole.FUEL, 30.0)
	var igniter := _item(ItemData.FireRole.IGNITER, 20.0)
	var rare_igniter := _item(ItemData.FireRole.IGNITER, 30.0)

	var empty: Dictionary[ItemData, int] = {}
	_check(FireCalculator.temperature(empty) == 0.0, "nothing gives no heat")
	var fuel_only: Dictionary[ItemData, int] = {fuel: 3}
	_check(FireCalculator.temperature(fuel_only) == 90.0, "temperature is a plain sum and no longer needs an igniter")
	var full: Dictionary[ItemData, int] = {fuel: 3, igniter: 2}
	_check(FireCalculator.temperature(full) == 130.0, "heat is the sum of item heat times count")

	_check(FireCalculator.reward_points(100.0, 100.0) == 0, "meeting the target exactly gives no points")
	_check(FireCalculator.reward_points(109.0, 100.0) == 0, "less than 10 degrees over gives no points")
	_check(FireCalculator.reward_points(135.0, 100.0) == 3, "every full 10 degrees over the target adds a point")
	_check(FireCalculator.reward_points(80.0, 100.0) == 0, "falling short never gives negative points")

	var any_igniter := _requirement(1, ItemData.FireRole.IGNITER, null, 1)
	var named_igniter := _requirement(3, ItemData.FireRole.IGNITER, rare_igniter, 1)
	var fuel_day3 := _requirement(3, ItemData.FireRole.FUEL, fuel, 3)
	var more_named := _requirement(8, ItemData.FireRole.IGNITER, rare_igniter, 2)
	var all: Array[FireRequirement] = [more_named, fuel_day3, named_igniter, any_igniter]

	_check(FireCalculator.active_requirements(all, 1) == [any_igniter], "day 1 only has the any-igniter requirement")
	_check(FireCalculator.active_requirements(all, 2) == [any_igniter], "a requirement is not active before its day")
	_check(FireCalculator.active_requirements(all, 3) == [fuel_day3, named_igniter], "the newest requirement per role replaces the older one, fuel listed first")
	_check(FireCalculator.active_requirements(all, 50) == [fuel_day3, more_named], "late days keep the newest requirement of each role")
	_check(FireCalculator.upcoming_requirements(all, 1) == [fuel_day3, named_igniter], "upcoming lists the next change of each role")
	_check(FireCalculator.upcoming_requirements(all, 3) == [more_named], "roles without a future change are left out of upcoming")

	var with_plain: Dictionary[ItemData, int] = {igniter: 1}
	_check(FireCalculator.unmet_requirements(with_plain, [any_igniter]).is_empty(), "any igniter satisfies an any-igniter requirement")
	_check(FireCalculator.unmet_requirements(with_plain, [named_igniter]) == [named_igniter], "a named requirement is not satisfied by another item of the same role")
	var zero_count: Dictionary[ItemData, int] = {igniter: 0}
	_check(FireCalculator.unmet_requirements(zero_count, [any_igniter]) == [any_igniter], "a count of zero does not satisfy a requirement")
	var mixed: Dictionary[ItemData, int] = {igniter: 1, rare_igniter: 1}
	var two_any := _requirement(1, ItemData.FireRole.IGNITER, null, 2)
	_check(FireCalculator.unmet_requirements(mixed, [two_any]).is_empty(), "different items of the role add up for an any-role requirement")
	_check(FireCalculator.unmet_requirements(mixed, [more_named]) == [more_named], "a named requirement needs its own count")

	_check_requirement_data()

	if _failures == 0:
		print("test_fire_calculator: OK")
	quit(1 if _failures > 0 else 0)


## 実データ(data/fire_requirements)の整合性。
func _check_requirement_data() -> void:
	var seen := {}
	var has_day_one_igniter := false
	for resource in DataDir.load_all("res://data/fire_requirements"):
		var requirement := resource as FireRequirement
		var key := "%d/%d" % [requirement.role, requirement.min_day]
		_check(not seen.has(key), "only one requirement per role and day: " + resource.resource_path)
		seen[key] = true
		_check(requirement.count > 0, "requirement counts are positive: " + resource.resource_path)
		if requirement.item != null:
			_check(requirement.item.fire_role == requirement.role, "a named item belongs to its requirement's role: " + resource.resource_path)
		if requirement.role == ItemData.FireRole.IGNITER and requirement.min_day == 1:
			has_day_one_igniter = true
	_check(has_day_one_igniter, "day 1 needs an igniter")


func _item(role: ItemData.FireRole, heat: float) -> ItemData:
	var item := ItemData.new()
	item.fire_role = role
	item.heat = heat
	return item


func _requirement(min_day: int, role: ItemData.FireRole, item: ItemData, count: int) -> FireRequirement:
	var requirement := FireRequirement.new()
	requirement.min_day = min_day
	requirement.role = role
	requirement.item = item
	requirement.count = count
	return requirement


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
