extends "res://Script/levelDoor.gd"

@onready var sprite: Sprite2D = $Sprite2D

var glow_tween: Tween


func _ready() -> void:
	super._ready()
	add_to_group("cafe_door")
	# Already talked to the security guard in an earlier session: keep glowing
	if SaveManager.get_object_state("security_guard").get("talked", false):
		startGlow()


func startGlow() -> void:
	if glow_tween and glow_tween.is_valid():
		return
	glow_tween = create_tween().set_loops()
	glow_tween.tween_property(sprite, "self_modulate", Color(3, 3, 3, 1), 1.0)
	glow_tween.tween_property(sprite, "self_modulate", Color(1, 1, 1, 1), 1.0)
