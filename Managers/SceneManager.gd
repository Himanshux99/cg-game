extends Node

var _pending_spawn_id := ""


func change_scene(scene: PackedScene, spawn_id: String = "default") -> void:
	_pending_spawn_id = spawn_id
	get_tree().change_scene_to_packed(scene)


func consume_pending_spawn_id() -> String:
	var id = _pending_spawn_id
	_pending_spawn_id = ""
	return id
