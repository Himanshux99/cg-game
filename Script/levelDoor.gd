extends Node

@export_file("*.tscn") var target_scene_path: String
@export var target_spawn_id := "default"

## Only used on entry doors: the SpawnPoint id in *this* scene, right in front
## of this door, that a return door on the other side should send the player back to.
@export var return_spawn_id := ""

## Check this on an exit/return door instead of setting target_scene_path -
## it sends the player back to whichever gate they entered from.
@export var is_return_door := false

@onready var interaction_area: InteractionArea = _find_interaction_area()


func _find_interaction_area() -> InteractionArea:
	if has_node("InteractionArea"):
		return $InteractionArea
	var parent := get_parent()
	if parent is InteractionArea:
		return parent
	return null


func _ready() -> void:
	if interaction_area:
		interaction_area.interact = Callable(self, "_on_interact")
	else:
		push_error("LevelDoor '%s' has no InteractionArea (as a child or parent)" % name)


func _on_interact() -> void:
	if is_return_door:
		SceneManager.go_back()
	elif target_scene_path != "":
		var target_scene: PackedScene = load(target_scene_path)
		SceneManager.enter_scene(target_scene, target_spawn_id, return_spawn_id)
