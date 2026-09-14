class_name GamePhase
extends Node

signal finished


func finish() -> void:
	finished.emit()
