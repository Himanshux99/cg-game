extends Sprite2D
## Receptionist of the queue room. Talking to her starts a short dialogue and then the
## queue-prediction mini-game. Once the game is solved she only confirms the player is first.

@export var puzzle_scene: PackedScene
@export var puzzle_id := "queue_prediction"
@export_file("*.json") var intro_dialogue := "res://Script/Dialogues/ReceptionConvo.json"
@export_file("*.json") var solved_dialogue := "res://Script/Dialogues/ReceptionSolvedConvo.json"
@export_file("*.json") var done_dialogue := "res://Script/Dialogues/ReceptionDoneConvo.json"

@onready var interaction_area: InteractionArea = $InteractionArea


func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")


func _on_interact() -> void:
	if SaveManager.is_puzzle_solved(puzzle_id):
		Dialogue.start_dialogue_from_json(done_dialogue)
		await Dialogue.dialogue_ended
		ComingSoon.show_over(self)
		return
	Dialogue.start_dialogue_from_json(intro_dialogue)
	await Dialogue.dialogue_ended
	_open_puzzle()


func _open_puzzle() -> void:
	if puzzle_scene == null:
		return
	PuzzleManager.open_puzzle(puzzle_scene)
	if PuzzleManager.current_puzzle:
		PuzzleManager.current_puzzle.puzzle_solved.connect(_on_puzzle_solved)


## PuzzleManager has already stored the result and closed the game when this runs.
func _on_puzzle_solved(_id: String) -> void:
	Dialogue.start_dialogue_from_json(solved_dialogue)
	await Dialogue.dialogue_ended
	ComingSoon.show_over(self)
