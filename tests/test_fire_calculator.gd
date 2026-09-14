extends SceneTree

var _failures := 0


func _init() -> void:
	var fuel := _item(ItemData.FireRole.FUEL, 30.0)
	var tinder := _item(ItemData.FireRole.TINDER, 10.0)
	var igniter := _item(ItemData.FireRole.IGNITER, 20.0)

	var empty: Dictionary[ItemData, int] = {}
	_check(FireCalculator.temperature(empty) == 0.0, "nothing gives no heat")

	var no_igniter: Dictionary[ItemData, int] = {fuel: 3, tinder: 2}
	_check(FireCalculator.temperature(no_igniter) == 0.0, "no igniter gives no heat")

	var no_tinder: Dictionary[ItemData, int] = {fuel: 3, igniter: 1}
	_check(FireCalculator.temperature(no_tinder) == 0.0, "no tinder gives no heat")

	var zero_tinder: Dictionary[ItemData, int] = {fuel: 3, tinder: 0, igniter: 1}
	_check(FireCalculator.temperature(zero_tinder) == 0.0, "a tinder count of zero does not count")

	var full: Dictionary[ItemData, int] = {fuel: 3, tinder: 2, igniter: 1}
	_check(FireCalculator.temperature(full) == 130.0, "heat is the sum of item heat times count")

	_check(FireCalculator.reward_points(100.0, 100.0) == 1, "meeting the target gives one point")
	_check(FireCalculator.reward_points(135.0, 100.0) == 4, "every 10 degrees over the target adds a point")

	if _failures == 0:
		print("test_fire_calculator: OK")
	quit(1 if _failures > 0 else 0)


func _item(role: ItemData.FireRole, heat: float) -> ItemData:
	var item := ItemData.new()
	item.fire_role = role
	item.heat = heat
	return item


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
