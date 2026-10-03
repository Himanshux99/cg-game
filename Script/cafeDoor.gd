extends StaticBody2D

@export var puzzle_scene: PackedScene
@export var object_id := "cafe_door"

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D

var glow_tween: Tween


func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")
	add_to_group("cafe_door")
	# Already talked to the security guard in an earlier session: keep glowing
	if SaveManager.get_object_state("security_guard").get("talked", false):
		startGlow()


func startGlow() -> void:
	if glow_tween and glow_tween.is_valid():
		return
	glow_tween = create_tween().set_loops()
	glow_tween.tween_property($Sprite2D, "self_modulate", Color(3, 3, 3, 1), 1.0)
	glow_tween.tween_property($Sprite2D, "self_modulate", Color(1, 1, 1, 1), 1.0)


func _on_interact() -> void:
	if puzzle_scene:
		PuzzleManager.open_puzzle(puzzle_scene)
