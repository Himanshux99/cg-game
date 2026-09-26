extends StaticBody2D

@export var target_scene: PackedScene
@export var target_spawn_id := "default"

@onready var interaction_area: InteractionArea = $InteractionArea


func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")


func _on_interact() -> void:
	if target_scene:
		SceneManager.change_scene(target_scene, target_spawn_id)
