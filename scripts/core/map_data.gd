class_name MapData
extends RefCounted

var width: int
var height: int
var ground: Dictionary[Vector2i, StringName] = {}
var cells: Dictionary[Vector2i, StringName] = {}
var spawn_cell: Vector2i
