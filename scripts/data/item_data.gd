class_name ItemData
extends Resource

enum FireRole { NONE, FUEL, IGNITER }

const ROLE_NAMES: Dictionary[FireRole, String] = {
	FireRole.FUEL: "燃料",
	FireRole.IGNITER: "着火",
}

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var fire_role: FireRole = FireRole.NONE
@export var heat: float = 0.0
