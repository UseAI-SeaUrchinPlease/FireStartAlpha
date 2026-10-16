class_name BlockData
extends Resource

@export var id: StringName
@export var display_name: String
@export var atlas_coords: Vector2i
## 壊すのに必要な叩く回数。0 なら掘れない(外周の岩壁など)。
@export var hits: int = 10
## これ未満の道具レベルでは叩いても掘れない (DEVELOPMENT.md 8.4)。
@export var required_tool_level: int = 0
@export var drop_item: ItemData
@export var drop_count: int = 1
@export_group("Rare placement")
## 空でなければレアブロック。MapGenerator が生成した replaces のブロックを
## replace_chance の確率でこのブロックに置き換える (DEVELOPMENT.md 8.3)。
@export var replaces: StringName = &""
@export_range(0.0, 1.0) var replace_chance: float = 0.0
