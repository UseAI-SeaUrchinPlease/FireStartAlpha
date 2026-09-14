class_name UpgradeData
extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var cost: int = 1
## 0 means it can be bought any number of times.
@export var max_level: int = 3
@export var max_hp_bonus: int = 0
@export var attack_bonus: int = 0
@export var dig_speed_bonus: float = 0.0
@export var heal: int = 0
