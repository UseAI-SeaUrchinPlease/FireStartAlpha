class_name EnemyData
extends Resource

@export var id: StringName
@export var display_name: String
@export var sprite: Texture2D
@export var max_hp: int = 3
@export var damage: int = 1
@export var speed: float = 45.0
@export var aggro_range: float = 180.0
@export var min_day: int = 1
## Seconds before it can hurt the player again after landing a hit.
@export var attack_interval: float = 0.0
## HP it must lose since its last knockback before it is knocked back again; 1 means every hit.
@export var knockback_threshold: int = 1
@export var knockback_speed: float = 120.0
@export var knockback_duration: float = 0.15
## Seconds of continuous contact it takes to break a block, relative to its hardness; 0 means it cannot break blocks.
@export var break_speed: float = 0.0
