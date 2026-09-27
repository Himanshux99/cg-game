extends Node

var _pending_spawn_id := ""
var _return_scene_path := ""
var _return_spawn_id := ""


func change_scene(scene: PackedScene, spawn_id: String = "default") -> void:
	_pending_spawn_id = spawn_id
	get_tree().change_scene_to_packed(scene)


## Enter a scene through a gate, remembering the current scene + return_spawn_id
## so a return door on the other side can send the player back with go_back().
func enter_scene(scene: PackedScene, spawn_id: String, return_spawn_id: String) -> void:
	_return_scene_path = get_tree().current_scene.scene_file_path
	_return_spawn_id = return_spawn_id
	change_scene(scene, spawn_id)


func go_back() -> void:
	if _return_scene_path == "":
		return
	change_scene(load(_return_scene_path), _return_spawn_id)


func consume_pending_spawn_id() -> String:
	var id = _pending_spawn_id
	_pending_spawn_id = ""
	return id
