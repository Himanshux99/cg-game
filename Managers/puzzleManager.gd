extends CanvasLayer

var current_puzzle: Control


func open_puzzle(puzzle_scene: PackedScene) -> void:
	if current_puzzle:
		return

	current_puzzle = puzzle_scene.instantiate()
	add_child(current_puzzle)
	UIManager.set_group_visible("MobileControlUi", false)
	current_puzzle.puzzle_solved.connect(_on_puzzle_solved)
	current_puzzle.puzzle_closed.connect(_on_puzzle_closed)

	get_tree().paused = true
	current_puzzle.process_mode = Node.PROCESS_MODE_ALWAYS


func close_puzzle() -> void:
	if current_puzzle:
		current_puzzle.queue_free()
		current_puzzle = null
	UIManager.set_group_visible("MobileControlUi", true)
	get_tree().paused = false


func _on_puzzle_solved(puzzle_id: String) -> void:
	print(puzzle_id + " Puzzle solved!")

	GameManager.puzzle_solved(puzzle_id)

	close_puzzle()


func _on_puzzle_closed(puzzle_id: String) -> void:
	print(puzzle_id + " Puzzle closed!")

	close_puzzle()
