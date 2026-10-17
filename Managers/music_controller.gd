extends Node
## Autoload that owns the background music and the UI click sound.
## Volume and on/off state for both are set from the settings panel and saved to disk.

const SETTINGS_PATH := "user://audio_settings.cfg"

## Seconds to skip at the start of the click sound (cuts leading silence).
@export var click_start_time := 0.6

## Linear volumes, 0.0 to 1.0.
var master_volume := 1.0
var music_volume := 1.0
var click_volume := 1.0
var master_enabled := true
var music_enabled := true
var click_enabled := true

@onready var bgm_player: AudioStreamPlayer2D = $BGMPlayer
@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer
# Volumes set in the scene; the sliders scale relative to these.
@onready var _bgm_base_db := bgm_player.volume_db
@onready var _sfx_base_db := sfx_player.volume_db


func _ready() -> void:
	# Keep playing while the tree is paused (puzzles and dialogue pause the game)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	# Buttons that already exist when this autoload starts
	_hook_existing_buttons.call_deferred(get_tree().root)
	_load_settings()
	_apply_master()
	_apply_music()


func _hook_existing_buttons(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_hook_existing_buttons(child)


func _on_node_added(node: Node) -> void:
	if node is Button and not node.pressed.is_connected(play_click_sound):
		node.pressed.connect(play_click_sound)


func play_click_sound() -> void:
	if not click_enabled or click_volume <= 0.0:
		return
	sfx_player.volume_db = _sfx_base_db + linear_to_db(click_volume)
	# Restart from the offset so rapid clicks each get heard from the same point
	sfx_player.play(click_start_time)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_master()
	_save_settings()


func set_master_enabled(enabled: bool) -> void:
	master_enabled = enabled
	_apply_master()
	_save_settings()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_music()
	_save_settings()


func set_click_volume(value: float) -> void:
	click_volume = clampf(value, 0.0, 1.0)
	_save_settings()


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_apply_music()
	_save_settings()


func set_click_enabled(enabled: bool) -> void:
	click_enabled = enabled
	_save_settings()


## Scales the Master bus, which every AudioStreamPlayer uses unless given another bus,
## so footsteps, door sounds and any future sound are covered.
func _apply_master() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, maxf(linear_to_db(master_volume), -80.0))
	AudioServer.set_bus_mute(bus, not master_enabled)


func _apply_music() -> void:
	bgm_player.volume_db = maxf(_bgm_base_db + linear_to_db(music_volume), -80.0)
	bgm_player.stream_paused = not music_enabled


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "master_enabled", master_enabled)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "click_volume", click_volume)
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "click_enabled", click_enabled)
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = config.get_value("audio", "master_volume", master_volume)
	master_enabled = config.get_value("audio", "master_enabled", master_enabled)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	click_volume = config.get_value("audio", "click_volume", click_volume)
	music_enabled = config.get_value("audio", "music_enabled", music_enabled)
	click_enabled = config.get_value("audio", "click_enabled", click_enabled)
