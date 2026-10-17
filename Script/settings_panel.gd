extends Panel
## Settings popup opened from the gear button. The Sound tab controls the music and
## button-click volume and on/off state through the MusicController autoload.

@onready var _master_toggle: CheckButton = %MasterToggle
@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_toggle: CheckButton = %MusicToggle
@onready var _music_slider: HSlider = %MusicSlider
@onready var _click_toggle: CheckButton = %ClickToggle
@onready var _click_slider: HSlider = %ClickSlider
@onready var _close_button: Button = %CloseButton


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
	_close_button.pressed.connect(hide)
	visibility_changed.connect(_on_visibility_changed)


func toggle() -> void:
	visible = not visible


## Blurs the game behind the popup and freezes it while the popup is open.
func _on_visibility_changed() -> void:
	var blur := get_node_or_null("../SettingsBlur") as Control
	if blur:
		blur.visible = visible
	if visible:
		_was_paused = get_tree().paused
		get_tree().paused = true
	else:
		# Only unfreeze if nothing else (a puzzle, dialogue) had paused the game before
		get_tree().paused = _was_paused


func _on_master_toggled(on: bool) -> void:
	MusicController.set_master_enabled(on)
	_update_slider_state()


func _on_music_toggled(on: bool) -> void:
	MusicController.set_music_enabled(on)
	_update_slider_state()


func _on_click_toggled(on: bool) -> void:
	MusicController.set_click_enabled(on)
	_update_slider_state()


func _update_slider_state() -> void:
	_master_slider.editable = _master_toggle.button_pressed
	_music_slider.editable = _music_toggle.button_pressed
	_click_slider.editable = _click_toggle.button_pressed
