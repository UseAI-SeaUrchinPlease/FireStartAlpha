class_name ItemPickup
extends Area2D

var item: ItemData
var count: int = 1

@onready var _sprite: Sprite2D = %Sprite


func _ready() -> void:
	_sprite.texture = item.icon
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		Audio.play(&"pickup")
		GameState.add_item(item, count)
		queue_free()
