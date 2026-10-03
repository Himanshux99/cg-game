extends CanvasLayer


@onready var char_sprite: TextureRect = $Control/CharSprite
@onready var name_label: Label = $Control/NameLabel
@onready var text_label: RichTextLabel = $Control/DialogueText
@onready var next_button: Button = $Control/NextButton
@onready var prev_button: Button = $Control/PrevButton

signal dialogue_started
signal dialogue_ended

# Change this path to the folder where you are saving your .tres files
const PORTRAIT_FOLDER_PATH = "res://Assets/portraits/"

var current_dialogue_data: Array = []
var current_line_index: int = 0

## Played on a loop while the dialogue box is open.
@export var talking_stream: AudioStream = preload("res://Assets/Sound/Talking.mp3")
@export var talking_volume_db := 0.0
## Seconds to skip at the start of the talking sound each time it (re)starts.
@export var talking_start_time := 0.0

var talking_player: AudioStreamPlayer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	talking_player = AudioStreamPlayer.new()
	talking_player.stream = talking_stream
	talking_player.volume_db = talking_volume_db
	add_child(talking_player)
	# Loop by restarting each time it ends, only while a dialogue is open
	talking_player.finished.connect(_on_talking_finished)
	next_button.pressed.connect(_on_next_pressed)
	prev_button.pressed.connect(_on_prev_pressed)

func start_dialogue_from_json(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		push_error("Dialogue JSON file not found: " + file_path)
		return
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		if typeof(json.data) == TYPE_ARRAY:
			current_dialogue_data = json.data
			current_line_index = 0
			visible = true
			get_tree().paused = true
			UIManager.set_group_visible("MobileControlUi", false)
			emit_signal("dialogue_started")
			talking_player.play(talking_start_time)
			show_line()
		else:
			push_error("JSON root must be an Array [ ]")
	else:
		push_error("JSON Parse Error: ", json.get_error_message())

func show_line() -> void:
	if current_line_index < current_dialogue_data.size() and current_line_index >= 0:
		var line_data = current_dialogue_data[current_line_index]
		
		name_label.text = str(line_data.get("name", "???"))
		text_label.text = str(line_data.get("text", ""))
		
		# Load the custom resource (.tres) file matching the JSON key
		var sprite_key = line_data.get("sprite", "")
		if sprite_key != "":
			# Note the extension is changed to .tres here
			var full_sprite_path = PORTRAIT_FOLDER_PATH + sprite_key + ".tres"
			
			if ResourceLoader.exists(full_sprite_path):
				char_sprite.texture = load(full_sprite_path)
			else:
				char_sprite.texture = null
				push_warning("Could not find portrait resource at: " + full_sprite_path)
		else:
			char_sprite.texture = null
			
		prev_button.visible = (current_line_index > 0)
		
		# Check if it is the last dialogue line to turn the button green
		if current_line_index == current_dialogue_data.size() - 1:
			next_button.modulate = Color(0.2, 1.0, 0.2, 1.0)
		else:
			next_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		end_dialogue()

func _on_next_pressed() -> void:
	current_line_index += 1
	show_line()

func _on_prev_pressed() -> void:
	if current_line_index > 0:
		current_line_index -= 1
		show_line()

func _on_talking_finished() -> void:
	if visible:
		talking_player.play(talking_start_time)

func end_dialogue() -> void:
	talking_player.stop()
	visible = false
	get_tree().paused = false
	UIManager.set_group_visible("MobileControlUi", true)
	emit_signal("dialogue_ended")
	current_dialogue_data.clear()
