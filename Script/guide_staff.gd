extends AnimatedSprite2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var guide_calling_line: Label = $GuideCallingLine

## Puzzle opened once the guide's dialogue is closed.
@export var puzzle_scene: PackedScene
@export var puzzle_id := "where_is_block"
var first_time := true
var _dialogue_start_position := Vector2.ZERO


func _ready() -> void:
	guide_calling_line.hide()
	interaction_area.interact = Callable(self, "_on_interact")
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and first_time:
		guide_calling_line.show()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		guide_calling_line.hide()


func _on_interact() -> void:
	first_time = false
	var player := get_tree().get_first_node_in_group("Player") as Node2D
	if player:
		_dialogue_start_position = player.global_position
	guide_calling_line.hide()
	Dialogue.start_dialogue_from_json("res://Script/Dialogues/AdminBuildingConvo.json")
	await Dialogue.dialogue_ended
	_open_puzzle()


func _open_puzzle() -> void:
	if puzzle_scene == null or SaveManager.is_puzzle_solved(puzzle_id):
		return
	PuzzleManager.open_puzzle(puzzle_scene)
	if PuzzleManager.current_puzzle:
		PuzzleManager.current_puzzle.puzzle_closed.connect(_on_puzzle_closed)


## X pressed: only "not completed" is stored (no level), then Part-2 restarts with the player where the dialogue began.
func _on_puzzle_closed(id: String) -> void:
	if not SaveManager.is_puzzle_solved(id):
		SaveManager.set_puzzle_solved(id, false)
	var scene_path := get_tree().current_scene.scene_file_path
	SceneManager.change_scene_at_position(load(scene_path), _dialogue_start_position)
