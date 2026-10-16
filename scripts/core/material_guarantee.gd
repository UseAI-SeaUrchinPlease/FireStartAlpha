## 必須素材の条件から、マップに最低限置くブロックの数を計算する。
## MapGenerator が火起こしのデータを知らずに済むよう、ここで
## 「ブロック id → 最低数」に変換してから渡す (DEVELOPMENT.md 8.3)。
class_name MaterialGuarantee
extends RefCounted

## 必要数ちょうどだと、遠い場所や囲まれた飛び地にあるだけで集めきれなくなるための余裕。
const FACTOR := 3


static func block_minimums(requirements: Array[FireRequirement], blocks: Array[BlockData], items: Array[ItemData]) -> Dictionary[StringName, int]:
	var needed: Dictionary[ItemData, int] = {}
	for requirement in requirements:
		var item := requirement.item if requirement.item != null else weakest_item(items, requirement.role)
		if item != null:
			needed[item] = maxi(needed.get(item, 0), requirement.count)
	var result: Dictionary[StringName, int] = {}
	for item: ItemData in needed:
		var block := source_block(blocks, item)
		if block != null:
			result[block.id] = maxi(result.get(block.id, 0), ceili(float(needed[item] * FACTOR) / block.drop_count))
	return result


## 「どれでも」の条件は、その役割で最も発熱量の低い(序盤の)素材として数える。
static func weakest_item(items: Array[ItemData], role: ItemData.FireRole) -> ItemData:
	var weakest: ItemData = null
	for item in items:
		if item.fire_role != role:
			continue
		if weakest == null or item.heat < weakest.heat or (item.heat == weakest.heat and item.id < weakest.id):
			weakest = item
	return weakest


static func source_block(blocks: Array[BlockData], item: ItemData) -> BlockData:
	var source: BlockData = null
	for block in blocks:
		if block.drop_item == item and block.drop_count > 0 and (source == null or block.id < source.id):
			source = block
	return source
