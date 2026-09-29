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
@export var hp_growth_per_day: float = 0.0
@export var speed_growth_per_day: float = 0.0
@export var damage_growth_per_day: float = 0.0
## speed_growth_per_day を適用した後の上限。プレイヤーの移動速度を超えて
## 回避不能にならないよう、速度の成長にのみ上限を設けている (issue #7)。
@export var max_speed: float = 999.0
