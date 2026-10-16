class_name BlockData
extends Resource

@export var id: StringName
@export var display_name: String
@export var atlas_coords: Vector2i
## Seconds of holding "dig" to break it; 0 means it can never be dug.
@export var hardness: float = 0.5
@export var drop_item: ItemData
@export var drop_count: int = 1
@export_group("Rare placement")
## 空でなければレアブロック。MapGenerator が生成した replaces のブロックを
## replace_chance の確率でこのブロックに置き換える (DEVELOPMENT.md 8.3)。
@export var replaces: StringName = &""
@export_range(0.0, 1.0) var replace_chance: float = 0.0
