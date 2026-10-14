extends Control
## Title screen: Continue / New Game / Options / Quit.

const GAME_SCENE := "res://Scene/Part-1.tscn"

@onready var continue_button: Button = $Buttons/Continue
@onready var new_game_button: Button = $Buttons/NewGame
@onready var options_button: Button = $Buttons/Options
@onready var quit_button: Button = $Buttons/Quit
@onready var options_panel: Control = $OptionsPanel
@onready var music_slider: HSlider = $OptionsPanel/Box/MusicSlider
@onready var fullscreen_check: CheckButton = $OptionsPanel/Box/Fullscreen
@onready var back_button: Button = $OptionsPanel/Box/Back


func _ready() -> void:
	continue_button.disabled = not FileAccess.file_exists(SaveManager.SAVE_PATH)
	if continue_button.disabled:
		new_game_button.grab_focus()
	else:
		continue_button.grab_focus()
	# Phones have no windowed mode and no quit convention
	if OS.has_feature("mobile"):
		quit_button.hide()
		fullscreen_check.hide()

	var bus := AudioServer.get_bus_index("Master")
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus))
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	continue_button.pressed.connect(_start_game)
	new_game_button.pressed.connect(_new_game)
	options_button.pressed.connect(options_panel.show)
	back_button.pressed.connect(options_panel.hide)
	quit_button.pressed.connect(get_tree().quit)
	music_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)


func _new_game() -> void:
	GameManager.delete_save()
	_start_game()


func _start_game() -> void:
	GameManager.game_loaded = false
	GameManager.player = null
	SceneManager.reset()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_volume_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	AudioServer.set_bus_mute(bus, value <= 0.0)


func _on_fullscreen_toggled(on: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and options_panel.visible:
		options_panel.hide()
