extends Node
## Autoload that owns the background music and the UI click sound.

## Seconds to skip at the start of the click sound (cuts leading silence).
@export var click_start_time := 0.6

@onready var bgm_player: AudioStreamPlayer2D = $BGMPlayer
@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer


func _ready() -> void:
	# Keep playing while the tree is paused (puzzles and dialogue pause the game)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	# Buttons that already exist when this autoload starts
	_hook_existing_buttons.call_deferred(get_tree().root)


func _hook_existing_buttons(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_hook_existing_buttons(child)


func _on_node_added(node: Node) -> void:
	if node is Button and not node.pressed.is_connected(play_click_sound):
		node.pressed.connect(play_click_sound)


func play_click_sound() -> void:
	# Restart from the offset so rapid clicks each get heard from the same point
	sfx_player.play(click_start_time)
