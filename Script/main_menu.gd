extends Control
## Title screen: Continue / New Game / Settings / Quit.

const GAME_SCENE := "res://Scene/Part-1.tscn"

@onready var continue_button: Button = $Buttons/Continue
@onready var new_game_button: Button = $Buttons/NewGame
@onready var options_button: Button = $Buttons/Options
@onready var quit_button: Button = $Buttons/Quit
@onready var settings_menu: Control = $SettingsMenu
@onready var logo: Control = $Logo
@onready var buttons: Control = $Buttons


func _ready() -> void:
	continue_button.disabled = not FileAccess.file_exists(SaveManager.SAVE_PATH)
	if continue_button.disabled:
		new_game_button.grab_focus()
	else:
		continue_button.grab_focus()
	# Phones have no quit convention
	if OS.has_feature("mobile"):
		quit_button.hide()

	continue_button.pressed.connect(_continue_game)
	new_game_button.pressed.connect(_new_game)
	options_button.pressed.connect(settings_menu.show)
	quit_button.pressed.connect(get_tree().quit)
	_play_intro()


## Fades the buttons in and keeps the logo gently floating.
func _play_intro() -> void:
	buttons.modulate.a = 0.0
	create_tween().tween_property(buttons, "modulate:a", 1.0, 0.5).set_delay(0.15)
	# Sub-pixel motion; the logo texture has mipmaps so the downscale doesn't shimmer
	var base_y := logo.position.y
	var bob := create_tween().set_loops()
	bob.tween_property(logo, "position:y", base_y - 14.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(logo, "position:y", base_y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _new_game() -> void:
	GameManager.delete_save()
	_start_game()


func _continue_game() -> void:
	var saved_scene := SaveManager.peek_saved_scene()
	_start_game(saved_scene if saved_scene != "" else GAME_SCENE)


func _start_game(scene_path: String = GAME_SCENE) -> void:
	GameManager.game_loaded = false
	GameManager.player = null
	SceneManager.reset()
	get_tree().change_scene_to_file(scene_path)
