extends Node

signal talked

@export_file("*.json") var dialogue_file: String

@onready var interaction_area: InteractionArea = $InteractionArea


func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")


func _on_interact() -> void:
	talked.emit()
	Dialogue.start_dialogue_from_json(dialogue_file)
