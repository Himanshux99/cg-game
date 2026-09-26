extends StaticBody2D

@export var puzzle_scene: PackedScene
@export var object_id := "cafe_door"

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")
	
	
func startGlow() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "self_modulate", Color(3, 3, 3, 1), 1.0)
	tween.tween_property($Sprite2D, "self_modulate", Color(1, 1, 1, 1), 1.0)	


func _on_interact() -> void:
	if puzzle_scene:
		PuzzleManager.open_puzzle(puzzle_scene)
