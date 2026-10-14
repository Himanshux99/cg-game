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

	"inventory": []
}


func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
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

		"inventory": []
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

func set_puzzle_solved(puzzle_id: String):
	save_data["puzzles"][puzzle_id] = {
		"solved": true
	}


func is_puzzle_solved(puzzle_id: String) -> bool:
	if not save_data["puzzles"].has(puzzle_id):
		return false

	return save_data["puzzles"][puzzle_id]["solved"]


func set_object_state(object_id: String, state: Dictionary):
	save_data["objects"][object_id] = state


func get_object_state(object_id: String) -> Dictionary:
	return save_data["objects"].get(object_id, {})


func get_inventory() -> Array:
	return save_data.get("inventory", [])


func add_inventory_item(item_id: String):
	if not save_data.has("inventory"):
		save_data["inventory"] = []
	save_data["inventory"].append(item_id)
