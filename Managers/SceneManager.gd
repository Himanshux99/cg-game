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


## Plays a one-shot sound that keeps playing across the scene change, because the
## player lives on this autoload instead of the node that triggered it.
func play_sound(stream: AudioStream, volume_db := 0.0, start_time := 0.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play(start_time)


func consume_pending_spawn_id() -> String:
	var id = _pending_spawn_id
	_pending_spawn_id = ""
	return id


func reset() -> void:
	_pending_spawn_id = ""
	_return_scene_path = ""
	_return_spawn_id = ""
