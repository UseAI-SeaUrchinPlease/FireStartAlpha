## 火をつけるための必須素材の条件。役割ごとに有効日の違う条件を並べ、
## その日に有効なもののうち最も新しい1つだけを使う (DEVELOPMENT.md 8.2)。
class_name FireRequirement
extends Resource

@export var min_day: int = 1
@export var role: ItemData.FireRole = ItemData.FireRole.IGNITER
## 空なら role の素材ならどれでもよい。
@export var item: ItemData
@export var count: int = 1


func accepts(candidate: ItemData) -> bool:
	if item != null:
		return candidate == item
	return candidate.fire_role == role


func describe() -> String:
	var target := item.display_name if item != null else "%s(どれでも)" % ItemData.ROLE_NAMES[role]
	return "%s ×%d" % [target, count]
