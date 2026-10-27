extends Node

const SAVE_PATH := "user://savegame.save"

var save_data := {
	"player": {
		"position": {
			"x" : 0.0,
			"y" : 0.0
		}
	},

	"puzzles": {},

	"objects": {},

	"inventory": [],

	"stage": "part_1",

	"scene": ""
}


func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(save_data))
	print("Game Saved")
	file.close()

func clear_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	save_data = {
		"player": {
			"position": {
				"x" : 0.0,
				"y" : 0.0
			}
		},

		"puzzles": {},

		"objects": {},

		"inventory": [],

		"stage": "part_1",

		"scene": ""
	}
	print("Save Deleted")

func load_game(player: Node2D):
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var loaded_data = JSON.parse_string(json_text)

	if loaded_data == null:
		return

	save_data = loaded_data

	player.global_position = Vector2(
		save_data["player"]["position"]["x"],
		save_data["player"]["position"]["y"]
	)

func set_player_position(position: Vector2):
	save_data["player"]["position"]["x"] = position.x
	save_data["player"]["position"]["y"] = position.y

func set_puzzle_solved(puzzle_id: String, solved := true):
	save_data["puzzles"][puzzle_id] = {
		"solved": solved
	}


func is_puzzle_solved(puzzle_id: String) -> bool:
	if not save_data["puzzles"].has(puzzle_id):
		return false

	return save_data["puzzles"][puzzle_id]["solved"]


func set_object_state(object_id: String, state: Dictionary):
	save_data["objects"][object_id] = state


func get_object_state(object_id: String) -> Dictionary:
	return save_data["objects"].get(object_id, {})


func set_scene_path(path: String):
	save_data["scene"] = path


## Reads the scene path straight from disk, so the main menu can use it before load_game().
func peek_saved_scene() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return ""

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var loaded_data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(loaded_data) != TYPE_DICTIONARY:
		return ""

	var path: String = loaded_data.get("scene", "")
	return path if ResourceLoader.exists(path) else ""


func get_stage() -> String:
	return save_data.get("stage", "part_1")


func set_stage(stage_id: String):
	save_data["stage"] = stage_id


func get_inventory() -> Array:
	return save_data.get("inventory", [])


func add_inventory_item(item_id: String):
	if not save_data.has("inventory"):
		save_data["inventory"] = []
	save_data["inventory"].append(item_id)
