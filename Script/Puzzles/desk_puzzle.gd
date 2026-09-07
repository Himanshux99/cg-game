extends Control

@export var puzzle_id: String = "locker_puzzle_01"

signal puzzle_solved(puzzle_id)
signal puzzle_closed(puzzle_id)


@onready var code_input: LineEdit = $Panel/CodeInput
@onready var message: Label = $Panel/Message

func _ready() -> void:
	# This tells the LineEdit to run your function when Enter is pressed
	code_input.text_submitted.connect(_on_text_submitted)
	if SaveManager.is_puzzle_solved(puzzle_id):
		message.text = "Unlocked!"
		code_input.editable = false

func _on_text_submitted(_new_text: String) -> void:
	print(code_input)
	if code_input.text == "4721":
		message.text = "Unlocked!"
		await get_tree().create_timer(2.5).timeout
		puzzle_solved.emit(puzzle_id)
	else:
		message.text = "Wrong code!"


func _on_close_pressed() -> void:
	puzzle_closed.emit(puzzle_id)
	queue_free()


func _on_close_puzzle_button_pressed() -> void:
	puzzle_closed.emit(puzzle_id)
