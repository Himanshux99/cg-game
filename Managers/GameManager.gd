extends Node

signal stage_changed(stage: Stage)

enum Stage { PART_1, MAP, CAFE, CABIN, PART_2 }

const STAGE_IDS := {
	Stage.PART_1: "part_1",
	Stage.MAP: "map",
	Stage.CAFE: "cafe",
	Stage.CABIN: "cabin",
	Stage.PART_2: "part_2",
}

## Which stage each scene belongs to. Scenes not listed (e.g. puzzles) keep the current stage.
const SCENE_STAGES := {
	"res://Scene/Part-1.tscn": Stage.PART_1,
	"res://Scene/Map.tscn": Stage.MAP,
	"res://Scene/InsideCafe.tscn": Stage.CAFE,
	"res://Scene/Cabin Scene/SecurityCabin.tscn": Stage.CABIN,
	"res://Scene/Part-2.tscn": Stage.PART_2,
}

var player: CharacterBody2D = null
var game_loaded := false


func get_stage() -> Stage:
	var id: String = SaveManager.get_stage()
	var key = STAGE_IDS.find_key(id)
	return Stage.PART_1 if key == null else key


func set_stage(stage: Stage) -> void:
	if get_stage() == stage:
		return
	SaveManager.set_stage(STAGE_IDS[stage])
	stage_changed.emit(stage)


## Called by SceneManager after every scene change.
func update_stage_for_scene(scene_path: String) -> void:
	if SCENE_STAGES.has(scene_path):
		set_stage(SCENE_STAGES[scene_path])


func register_player(player_node: CharacterBody2D):
	player = player_node

	if not game_loaded:
		load_game()

	# The player is placed at its spawn point by now, so this records the new scene,
	# position and stage every time a scene is entered.
	save_game()


func load_game():
	if player == null:
		print("Cannot load: Player not registered")
		return

	SaveManager.load_game(player)
	InventoryManager.inventory_reloaded.emit()
	game_loaded = true


func save_game():
	if player == null:
		print("Cannot save: Player not registered")
		return

	SaveManager.set_scene_path(get_tree().current_scene.scene_file_path)
	SaveManager.set_player_position(player.global_position)
	SaveManager.save_game()


func delete_save():
	SaveManager.clear_save()


## Wipes the save and sends the game back to the very start (main scene),
## as if it were launched fresh. Call this from a "Restart" button.
func restart_game():
	delete_save()
	game_loaded = false
	player = null
	SceneManager.reset()
	get_tree().change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))


func puzzle_solved(puzzle_id: String):
	SaveManager.set_puzzle_solved(puzzle_id)
	save_game()


func object_changed(object_id: String, state: Dictionary):
	SaveManager.set_object_state(object_id, state)
	save_game()
