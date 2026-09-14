class_name BlockData
extends Resource

@export var id: StringName
@export var display_name: String
@export var atlas_coords: Vector2i
## Seconds of holding "dig" to break it; 0 means it can never be dug.
@export var hardness: float = 0.5
@export var drop_item: ItemData
@export var drop_count: int = 1
