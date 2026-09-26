extends Node2D

@onready var sprite_2d: Sprite2D = $BG/InteractionArea/Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $BG/InteractionArea/CollisionShape2D

var tween: Tween

@export var puzzle_scene: PackedScene
@export var object_id := "desktop"

@onready var interaction_area: InteractionArea = $BG/InteractionArea

func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")


func _on_interact() -> void:
	if puzzle_scene:
		PuzzleManager.open_puzzle(puzzle_scene)



func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# 1. Kill any existing tween first to clear old animations safely
		if tween and tween.is_valid():
			tween.kill()
		
		# 2. Start the looping glow
		tween = create_tween().set_loops()
		tween.tween_property(sprite_2d, "self_modulate", Color(3, 3, 3, 1), 1.0)
		tween.tween_property(sprite_2d, "self_modulate", Color(1, 1, 1, 1), 1.0)	


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# 1. Instantly kill the looping tween so it stops bouncing back and forth
		if tween and tween.is_valid():
			tween.kill()
		
		# 2. Create a BRAND NEW, non-looping tween to fade smoothly back to normal
		tween = create_tween()
		tween.tween_property(sprite_2d, "self_modulate", Color(1, 1, 1, 1), 0.5) # Fades out over 0.5 seconds
