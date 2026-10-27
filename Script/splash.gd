extends Control

const NEXT_SCENE := "res://Scene/MainMenu.tscn"
const FADE := 0.8
const HOLD := 1.6

@onready var studio_group: Control = $StudioGroup
@onready var presents: Label = $StudioGroup/Presents
@onready var game_logo: TextureRect = $GameLogo

var _leaving := false


func _ready() -> void:
	studio_group.modulate.a = 0.0
	presents.modulate.a = 0.0
	game_logo.modulate.a = 0.0

	var t := create_tween()
	t.tween_interval(0.3)
	t.tween_property(studio_group, "modulate:a", 1.0, FADE)
	t.tween_interval(0.4)
	t.tween_property(presents, "modulate:a", 1.0, FADE)
	t.tween_interval(HOLD)
	t.tween_property(studio_group, "modulate:a", 0.0, FADE)
	t.tween_interval(0.3)
	t.tween_property(game_logo, "modulate:a", 1.0, FADE)
	t.tween_interval(HOLD)
	t.tween_property(game_logo, "modulate:a", 0.0, FADE)
	t.tween_interval(0.3)
	t.tween_callback(_go_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event is InputEventMouseMotion:
		return
	if event is InputEventKey and event.echo:
		return
	_go_to_menu()


func _go_to_menu() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file(NEXT_SCENE)
