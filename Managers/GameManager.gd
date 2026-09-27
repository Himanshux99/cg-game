extends Node

var player: CharacterBody2D = null
var game_loaded := false


func register_player(player_node: CharacterBody2D):
	player = player_node

	if not game_loaded:
		load_game()


func load_game():
	if player == null:
		print("Cannot load: Player not registered")
		return

	SaveManager.load_game(player)
	game_loaded = true


func save_game():
	if player == null:
		print("Cannot save: Player not registered")
		return

	SaveManager.set_player_position(player.global_position)
	SaveManager.save_game()


func delete_save():
	SaveManager.clear_save()


func puzzle_solved(puzzle_id: String):
	SaveManager.set_puzzle_solved(puzzle_id)
	save_game()


func object_changed(object_id: String, state: Dictionary):
	SaveManager.set_object_state(object_id, state)
	save_game()
