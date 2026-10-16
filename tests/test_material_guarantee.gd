extends SceneTree

var _failures := 0


func _init() -> void:
	var grass_item := _item(&"grass_item", ItemData.FireRole.IGNITER, 10.0)
	var flint := _item(&"flint", ItemData.FireRole.IGNITER, 15.0)
	var iron := _item(&"iron", ItemData.FireRole.IGNITER, 30.0)
	var wood := _item(&"wood", ItemData.FireRole.FUEL, 20.0)
	var items: Array[ItemData] = [iron, wood, flint, grass_item]
	var grass := _block(&"grass", grass_item, 1)
	var rock := _block(&"rock", flint, 1)
	var ore := _block(&"ore", iron, 1)
	var tree := _block(&"tree", wood, 2)
	var blocks: Array[BlockData] = [grass, rock, ore, tree]

	_check(MaterialGuarantee.weakest_item(items, ItemData.FireRole.IGNITER) == grass_item, "the weakest igniter is the one with the lowest heat")

	var any_igniter: Array[FireRequirement] = [_requirement(ItemData.FireRole.IGNITER, null, 2)]
	_check(MaterialGuarantee.block_minimums(any_igniter, blocks, items) == {&"grass": 6}, "an any-role requirement guarantees the weakest item's block, count times 3")

	var named: Array[FireRequirement] = [
		_requirement(ItemData.FireRole.IGNITER, iron, 1),
		_requirement(ItemData.FireRole.IGNITER, iron, 2),
	]
	_check(MaterialGuarantee.block_minimums(named, blocks, items) == {&"ore": 6}, "the largest count among requirements for the same item is used")

	var by_drop: Array[FireRequirement] = [_requirement(ItemData.FireRole.FUEL, wood, 3)]
	_check(MaterialGuarantee.block_minimums(by_drop, blocks, items) == {&"tree": 5}, "blocks dropping several items need fewer copies, rounded up")

	_check_real_data()

	if _failures == 0:
		print("test_material_guarantee: OK")
	quit(1 if _failures > 0 else 0)


## 実データで、全ての必須素材の条件が保証できる(素材を落とすブロックがある)こと。
func _check_real_data() -> void:
	var blocks: Array[BlockData] = []
	blocks.assign(DataDir.load_all("res://data/blocks"))
	var items: Array[ItemData] = []
	items.assign(DataDir.load_all("res://data/items"))
	var requirements: Array[FireRequirement] = []
	requirements.assign(DataDir.load_all("res://data/fire_requirements"))
	var expected: Dictionary[StringName, int] = {&"grass": 3, &"birch": 3, &"iron_ore": 6, &"tree": 9, &"pine": 3, &"coal_seam": 6}
	var actual := MaterialGuarantee.block_minimums(requirements, blocks, items)
	_check(actual == expected, "the real data guarantees the minimums in DEVELOPMENT.md 8.3 (got %s)" % actual)
	for requirement in requirements:
		var resource := requirement
		var item := requirement.item if requirement.item != null else MaterialGuarantee.weakest_item(items, requirement.role)
		_check(item != null and MaterialGuarantee.source_block(blocks, item) != null, "some block drops the item needed by " + resource.resource_path)


func _item(id: StringName, role: ItemData.FireRole, heat: float) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.fire_role = role
	item.heat = heat
	return item


func _block(id: StringName, drop: ItemData, drop_count: int) -> BlockData:
	var block := BlockData.new()
	block.id = id
	block.drop_item = drop
	block.drop_count = drop_count
	return block


func _requirement(role: ItemData.FireRole, item: ItemData, count: int) -> FireRequirement:
	var requirement := FireRequirement.new()
	requirement.role = role
	requirement.item = item
	requirement.count = count
	return requirement


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
