extends Control
## Settings popup: sound controls, fullscreen and a Home button back to the title screen.
## Used in-game (opened from the gear button) and on the main menu (Options). Sound
## goes through the MusicController autoload.

const MAIN_MENU_SCENE := "res://Scene/MainMenu.tscn"

## True when opened over the running game: the game freezes behind the popup and the
## Home button is shown. The main menu turns this off.
@export var in_game := true

@onready var _master_toggle: CheckButton = %MasterToggle
@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_toggle: CheckButton = %MusicToggle
@onready var _music_slider: HSlider = %MusicSlider
@onready var _click_toggle: CheckButton = %ClickToggle
@onready var _click_slider: HSlider = %ClickSlider
@onready var _fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var _display_box: Control = %DisplayBox
@onready var _close_button: Button = %CloseButton
@onready var _home_button: Button = %HomeButton
@onready var _resume_button: Button = %ResumeButton
@onready var _save_box: Control = %SaveBox
@onready var _restart_button: Button = %RestartButton
@onready var _delete_button: Button = %DeleteButton


var _was_paused := false


func _ready() -> void:
	# Stay usable while the tree is paused (puzzles and dialogue pause the game)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_master_toggle.button_pressed = MusicController.master_enabled
	_master_slider.value = MusicController.master_volume
	_music_toggle.button_pressed = MusicController.music_enabled
	_music_slider.value = MusicController.music_volume
	_click_toggle.button_pressed = MusicController.click_enabled
	_click_slider.value = MusicController.click_volume
	_update_slider_state()

	_master_toggle.toggled.connect(_on_master_toggled)
	_master_slider.value_changed.connect(MusicController.set_master_volume)
	_music_toggle.toggled.connect(_on_music_toggled)
	_music_slider.value_changed.connect(MusicController.set_music_volume)
	_click_toggle.toggled.connect(_on_click_toggled)
	_click_slider.value_changed.connect(MusicController.set_click_volume)
	# Let the player hear the new click volume once they let go of the slider
	_click_slider.drag_ended.connect(func(_changed: bool) -> void: MusicController.play_click_sound())

	# Phones have no windowed mode
	_display_box.visible = not OS.has_feature("mobile")
	_fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

	_home_button.visible = in_game
	_resume_button.text = "Resume" if in_game else "Back"
	_close_button.pressed.connect(close)
	_resume_button.pressed.connect(close)
	_home_button.pressed.connect(_go_home)
	# Save wiping only makes sense mid-game; the title screen has New Game
	_save_box.visible = in_game
	_restart_button.pressed.connect(_restart)
	_delete_button.pressed.connect(GameManager.delete_save)
	visibility_changed.connect(_on_visibility_changed)


func toggle() -> void:
	visible = not visible


func close() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Freezes the game behind the popup while it is open.
func _on_visibility_changed() -> void:
	if not in_game:
		return
	if visible:
		_was_paused = get_tree().paused
		get_tree().paused = true
	else:
		# Only unfreeze if nothing else (a puzzle, dialogue) had paused the game before
		get_tree().paused = _was_paused


## Saves the run, then returns to the title screen where Continue picks it back up.
func _go_home() -> void:
	GameManager.save_game()
	get_tree().paused = false
	GameManager.game_loaded = false
	GameManager.player = null
	SceneManager.reset()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


## Wipes the save and starts over from the splash screen.
func _restart() -> void:
	get_tree().paused = false
	GameManager.restart_game()


func _on_master_toggled(on: bool) -> void:
	MusicController.set_master_enabled(on)
	_update_slider_state()


func _on_music_toggled(on: bool) -> void:
	MusicController.set_music_enabled(on)
	_update_slider_state()


func _on_click_toggled(on: bool) -> void:
	MusicController.set_click_enabled(on)
	_update_slider_state()


func _on_fullscreen_toggled(on: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


func _update_slider_state() -> void:
	_set_slider_enabled(_master_slider, _master_toggle.button_pressed)
	_set_slider_enabled(_music_slider, _music_toggle.button_pressed)
	_set_slider_enabled(_click_slider, _click_toggle.button_pressed)


func _set_slider_enabled(slider: HSlider, enabled: bool) -> void:
	slider.editable = enabled
	slider.modulate.a = 1.0 if enabled else 0.5
