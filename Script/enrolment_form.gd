extends Control

@export var puzzle_id: String = "enrolment_form"
## The correct value for the "College Unique Id" field.
@export var correct_college_id: String = ""

signal puzzle_solved(puzzle_id)
signal puzzle_closed(puzzle_id)

@export var ERROR_COLOR := Color(1, 0.35, 0.35)

const PANEL := "AspectRatioContainer/Panel/"
const FORM := PANEL + "FormContainer/MarginContainer/VBoxContainer/VBoxContainer/"

@onready var submit_button: Button = get_node(PANEL + "SubmitButton")
@onready var form_container: Control = get_node(PANEL + "FormContainer")
@onready var filled_container: Control = get_node(PANEL + "FormFilledContainer")

@onready var college_option: OptionButton = get_node(FORM + "MarginContainer/HBoxContainer3/VBoxContainer/MarginContainer/OptionButton")
@onready var college_id_edit: LineEdit = get_node(FORM + "MarginContainer/HBoxContainer3/VBoxContainer2/LineEdit")
@onready var name_edit: LineEdit = get_node(FORM + "MarginContainer2/HBoxContainer3/VBoxContainer/MarginContainer/LineEdit")
@onready var gender_option: OptionButton = get_node(FORM + "MarginContainer2/HBoxContainer3/VBoxContainer2/OptionButton")
@onready var email_edit: LineEdit = get_node(FORM + "MarginContainer3/HBoxContainer3/VBoxContainer/MarginContainer/LineEdit2")
@onready var phone_edit: LineEdit = get_node(FORM + "MarginContainer3/HBoxContainer3/VBoxContainer2/LineEdit3")
@onready var course_option: OptionButton = get_node(FORM + "MarginContainer4/HBoxContainer3/VBoxContainer/MarginContainer/OptionButton2")

var _fields: Array[Control]


func _ready() -> void:
	_fields = [college_option, college_id_edit, name_edit, gender_option, email_edit, phone_edit, course_option]

	for field in _fields:
		_set_error(field, false)  # strips the "*" from titles until a field is flagged
		if field is LineEdit:
			field.caret_blink = true
			field.caret_blink_interval = 0.5
			field.add_theme_constant_override("caret_width", 4)
			field.add_theme_color_override("caret_color", Color.BLACK)
			field.text_changed.connect(func(_t): _clear_error(field))
		elif field is OptionButton:
			field.item_selected.connect(func(_i): _clear_error(field))

	# The form panels are later siblings and would otherwise cover the button and eat its clicks.
	submit_button.move_to_front()
	submit_button.pressed.connect(_on_submit_pressed)

	if SaveManager.is_puzzle_solved(puzzle_id):
		_show_filled()
	else:
		form_container.visible = true
		filled_container.visible = false
		submit_button.visible = true


func _is_filled(field: Control) -> bool:
	if field is LineEdit:
		return not field.text.strip_edges().is_empty()
	# Item 0 is the disabled "Select ..." placeholder.
	return (field as OptionButton).selected > 0


## `wrong` means the field is filled but incorrect (only used for the unique id).
func _set_error(field: Control, on: bool, wrong := false) -> void:
	field.modulate = ERROR_COLOR if on else Color.WHITE
	# _set_field_text_color(field, on)	

	var header := _header_for(field)
	if header == null:
		return
	var label := header.get_node_or_null("Label") as Label
	if label:
		label.add_theme_color_override("font_color", ERROR_COLOR if on else Color.BLACK)

	# Notes next to the title stay hidden until the field is flagged.
	var required_note := header.get_node_or_null("requiredText") as Label
	var incorrect_note := header.get_node_or_null("IncorrectText") as Label
	if required_note:
		required_note.visible = on
		required_note.add_theme_color_override("font_color", ERROR_COLOR)
	if incorrect_note:
		if not incorrect_note.has_meta("wrong_text"):
			incorrect_note.set_meta("wrong_text", incorrect_note.text)
		# The unique id has no requiredText node, so reuse its note for "empty" too.
		incorrect_note.text = incorrect_note.get_meta("wrong_text") if wrong else "(field Required)"
		incorrect_note.visible = on
		incorrect_note.add_theme_color_override("font_color", ERROR_COLOR)


## Modulate alone leaves black text black, so recolor the field's own text too.
func _set_field_text_color(field: Control, on: bool) -> void:
	if field is LineEdit:
		for item in ["font_color", "font_placeholder_color"]:
			if on:
				field.add_theme_color_override(item, ERROR_COLOR)
			else:
				field.remove_theme_color_override(item)
	elif field is OptionButton:
		for item in ["font_color", "font_focus_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
			field.add_theme_color_override(item, ERROR_COLOR if on else Color.BLACK)


## The HBoxContainer holding a field's title label and its note label.
func _header_for(field: Control) -> Node:
	var holder := field.get_parent()
	if holder is MarginContainer:
		holder = holder.get_parent()
	return holder.get_node_or_null("HBoxContainer")


func _clear_error(field: Control) -> void:
	_set_error(field, false)

    
func _on_submit_pressed() -> void:
	var all_filled := true
	for field in _fields:
		var ok := _is_filled(field)
		_set_error(field, not ok)
		all_filled = all_filled and ok
	if not all_filled:
		return

	var entered := college_id_edit.text.strip_edges().to_lower()
	if correct_college_id.strip_edges().is_empty() or entered != correct_college_id.strip_edges().to_lower():
		_set_error(college_id_edit, true, true)
		return

	_show_filled()
	await get_tree().create_timer(2.5).timeout
	puzzle_solved.emit(puzzle_id)


func _show_filled() -> void:
	form_container.visible = false
	filled_container.visible = true
	submit_button.visible = false


func _on_close_button_pressed() -> void:
	puzzle_closed.emit(puzzle_id)
