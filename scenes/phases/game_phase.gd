class_name GamePhase
extends Node

signal finished
signal failed


func finish() -> void:
	finished.emit()


func fail() -> void:
	failed.emit()
