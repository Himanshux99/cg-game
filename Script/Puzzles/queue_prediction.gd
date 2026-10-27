extends Control
## Receptionist's queue game: the tokens called so far are shown and the player guesses the
## next ones. All guesses of an attempt must be right; a wrong submission fails the whole attempt
## and the queue is regenerated. The rules and state live in SequenceGame, this script is the UI.

@export var puzzle_id: String = "queue_prediction"
signal puzzle_solved(puzzle_id)
signal puzzle_closed(puzzle_id)

## 0 = two simple families, 3 = hardest families with 5 predictions (see SequenceConfig.for_difficulty).
@export_range(0, 3) var difficulty := 0
## Optional custom settings. When set, the difficulty preset is ignored.
@export var config: SequenceConfig
## Seconds the player waits after submitting before the answers are checked.
@export var submit_delay := 5.0
## Seconds the "wrong" message stays up before a new queue starts.
@export var fail_message_time := 2.0

const FRAME_TEXTURE := preload("res://Assets/UI/Spritesheet_UI_Flat.png")
const BUTTON_TEXTURES := {
	"blue": preload("res://Assets/UI/blue.png"),
	"green": preload("res://Assets/UI/green.png"),
	"red": preload("res://Assets/UI/red.png"),
	"grey": preload("res://Assets/UI/grey.png"),
	"yellow": preload("res://Assets/UI/yellow.png"),
}
const TEXT_DARK := Color(0.07, 0.09, 0.14)
const TEXT_LIGHT := Color.WHITE
const TEXT_BAD := Color(0.75, 0.05, 0.1)

var game: SequenceGame

var _styles := {}
var _chip_row: HFlowContainer
var _question_row: HBoxContainer
var _message_label: Label
var _submit_button: Button
var _action_button: Button
var _option_buttons: Array = []
var _revealed := false
var _waiting := false
var _finished := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = load("res://GlobalTheme.tres")
	game = SequenceGame.new(config if config != null else SequenceConfig.for_difficulty(difficulty))
	_build_ui()
	_show_attempt()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


# --------------------------------------------------
# UI CONSTRUCTION
# --------------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1180, 560)
	var frame := StyleBoxTexture.new()
	frame.texture = FRAME_TEXTURE
	frame.region_rect = Rect2(32, 32, 96, 64)
	_set_margins(frame, 4.0)
	panel.add_theme_stylebox_override("panel", frame)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _make_label("QUEUE TOKEN CHALLENGE", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := _make_button("X", "red", TEXT_LIGHT, 18)
	close_button.custom_minimum_size = Vector2(52, 44)
	close_button.pressed.connect(_close)
	header.add_child(close_button)

	_chip_row = HFlowContainer.new()
	_chip_row.alignment = FlowContainer.ALIGNMENT_CENTER
	_chip_row.add_theme_constant_override("h_separation", 10)
	_chip_row.add_theme_constant_override("v_separation", 10)
	column.add_child(_chip_row)

	_question_row = HBoxContainer.new()
	_question_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_question_row.add_theme_constant_override("separation", 26)
	_question_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_question_row)

	_message_label = _make_label("", 16, TEXT_BAD)
	_message_label.custom_minimum_size = Vector2(0, 24)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_message_label)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(footer)
	_submit_button = _make_button("SUBMIT", "green", TEXT_LIGHT, 20)
	_submit_button.custom_minimum_size = Vector2(280, 52)
	_submit_button.pressed.connect(_on_submit_pressed)
	footer.add_child(_submit_button)
	_action_button = _make_button("TRY AGAIN", "blue", TEXT_LIGHT, 20)
	_action_button.custom_minimum_size = Vector2(280, 52)
	_action_button.pressed.connect(_on_action_pressed)
	footer.add_child(_action_button)


func _make_label(text: String, font_size: int, color: Color = TEXT_DARK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text: String, style_key: String, font_color: Color, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	_style_button(button, style_key, font_color)
	return button


func _style_button(button: Button, style_key: String, font_color: Color) -> void:
	var style := _texture_style(style_key)
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, font_color)


func _texture_style(style_key: String) -> StyleBoxTexture:
	if not _styles.has(style_key):
		var style := StyleBoxTexture.new()
		style.texture = BUTTON_TEXTURES[style_key]
		_set_margins(style, 4.0)
		_styles[style_key] = style
	return _styles[style_key]


func _set_margins(style: StyleBoxTexture, amount: float) -> void:
	style.texture_margin_left = amount
	style.texture_margin_top = amount
	style.texture_margin_right = amount
	style.texture_margin_bottom = amount


func _make_chip(text: String, style_key: String, font_color: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(80, 50)
	chip.add_theme_stylebox_override("panel", _texture_style(style_key))
	var label := _make_label(text, 22, font_color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(label)
	return chip


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


# --------------------------------------------------
# ATTEMPT DISPLAY
# --------------------------------------------------

## Draws the current attempt from scratch so nothing of a previous attempt is left behind.
func _show_attempt() -> void:
	_revealed = false
	_waiting = false
	_clear(_chip_row)
	for number in game.attempt["revealed"]:
		_chip_row.add_child(_make_chip(str(number), "blue", TEXT_LIGHT))
	for i in range(game.question_count()):
		_chip_row.add_child(_make_chip("?", "yellow", TEXT_DARK))

	_clear(_question_row)
	_option_buttons.clear()
	for q in range(game.question_count()):
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		_question_row.add_child(column)
		column.add_child(_make_label("TOKEN %d" % (q + 1), 14))
		var buttons: Array = []
		var options: Array = game.attempt["questions"][q]["options"]
		for i in range(options.size()):
			var button := _make_button(str(options[i]), "blue", TEXT_LIGHT, 20)
			button.custom_minimum_size = Vector2(190, 46)
			button.pressed.connect(_on_option_pressed.bind(q, i))
			column.add_child(button)
			buttons.append(button)
		_option_buttons.append(buttons)

	_refresh_options()
	_message_label.text = ""
	_submit_button.text = "SUBMIT"
	_submit_button.visible = true
	_submit_button.disabled = true
	_action_button.visible = false


func _refresh_options() -> void:
	for q in range(_option_buttons.size()):
		var correct_index: int = game.attempt["questions"][q]["correct_index"]
		for i in range(_option_buttons[q].size()):
			var button: Button = _option_buttons[q][i]
			var picked: bool = game.selections[q] == i
			if _revealed:
				button.disabled = true
				if i == correct_index:
					_style_button(button, "green", TEXT_LIGHT)
				elif picked:
					_style_button(button, "red", TEXT_LIGHT)
				else:
					_style_button(button, "grey", TEXT_DARK)
			else:
				# Choices are locked while the submitted answers are being checked.
				button.disabled = _waiting
				_style_button(button, "green" if picked else "blue", TEXT_LIGHT)


# --------------------------------------------------
# PLAYER ACTIONS
# --------------------------------------------------

func _on_option_pressed(question: int, option_index: int) -> void:
	if _finished or _waiting or not game.select_option(question, option_index):
		return
	_refresh_options()
	_submit_button.disabled = not game.is_complete()


## Submitting locks the answers and starts the countdown; they are checked when it ends.
func _on_submit_pressed() -> void:
	if _finished or _waiting or not game.is_complete():
		return
	_waiting = true
	_submit_button.disabled = true
	_refresh_options()
	var seconds_left := ceili(submit_delay)
	while seconds_left > 0:
		_submit_button.text = "WAIT %d" % seconds_left
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree() or _finished:
			return
		seconds_left -= 1
	_waiting = false
	_check_answers()


func _check_answers() -> void:
	var result := game.submit()
	if not result["accepted"]:
		_show_attempt()
		return
	if game.state == SequenceGame.State.PASSED:
		_revealed = true
		_refresh_options()
		_submit_button.visible = false
		_action_button.visible = true
		_action_button.text = "CONTINUE"
		# Saved right away, so the progress is kept even if the player closes the window.
		GameManager.puzzle_solved(puzzle_id)
	else:
		_show_failure()


## A wrong attempt only says it was wrong: nothing about which answers were right is shown.
func _show_failure() -> void:
	_waiting = true
	_submit_button.visible = false
	_message_label.text = "WRONG ANSWERS! A NEW QUEUE IS STARTING..."
	await get_tree().create_timer(fail_message_time).timeout
	if not is_inside_tree() or _finished:
		return
	if game.state == SequenceGame.State.EXHAUSTED:
		_close()
		return
	game.start_new_attempt()
	_show_attempt()


func _on_action_pressed() -> void:
	match game.state:
		SequenceGame.State.PASSED:
			_finish_solved()


func _finish_solved() -> void:
	if _finished:
		return
	_finished = true
	puzzle_solved.emit(puzzle_id)


func _close() -> void:
	if game.state == SequenceGame.State.PASSED:
		_finish_solved()
		return
	if _finished:
		return
	_finished = true
	puzzle_closed.emit(puzzle_id)
