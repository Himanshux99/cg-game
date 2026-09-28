extends Node2D

@export_file("*.json") var dialogue_file: String
var isEntered = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and isEntered:
		start_dialogue()
	pass

func start_dialogue() -> void:
	Dialogue.start_dialogue_from_json(dialogue_file)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		isEntered = true


func _on_2d_body_entered_clg_gate(body: Node2D) -> void:
	if body.is_in_group("Player"):
		start_dialogue()
