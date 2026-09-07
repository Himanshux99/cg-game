extends StaticBody2D

@export var puzzle_scene: PackedScene
@export var object_id := "locker_01"

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")


func _on_interact() -> void:
	if puzzle_scene:
		PuzzleManager.open_puzzle(puzzle_scene)
