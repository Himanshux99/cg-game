extends Control

@export var puzzle_id: String = "where_is_block"

signal puzzle_solved(puzzle_id)
signal puzzle_closed(puzzle_id)

const CELL_SCENE := preload("res://Assets/UI/Components/cell.tscn")

## Target order across levels. Level N uses the first N letters.
## Levels beyond the length of this array are NOT defined: they need an additional target sequence.
@export var target_sequence: Array[String] = ["a", "g", "b", "f", "c", "d", "v", "m", "x", "y"]
@export var grid_size: int = 25
@export_group("Timing (seconds)")
## Delay between pressing Start (or advancing/retrying) and the first flash of a sequence.
@export var start_delay: float = 1.5
## How long each target cell stays lit.
@export var show_time: float = 0.6
## Pause between two flashes.
@export var gap_time: float = 0.2
## Pause after a correct level before the next one begins.
@export var level_complete_delay: float = 1.0
## Pause after a wrong click before returning to the start screen.
@export var wrong_delay: float = 1.0
## Pause after the final level before puzzle_solved is emitted.
@export var solved_delay: float = 1.5
@export_group("Colors")
@export var color_highlight := Color(1, 0.85, 0.2)
@export var color_right := Color(0.6, 0.9, 0.6)
@export var color_wrong := Color(1, 0.45, 0.45)

@onready var grid: GridContainer = $FullScreen/GamePanel/Panel/MarginContainer/Grid
@onready var start_panel: Control = $FullScreen/StartPanel
@onready var start_button: Button = $FullScreen/StartPanel/Panel/MarginContainer/VBoxContainer/StartButton
@onready var text_panel: Control = $FullScreen/TextPanel
@onready var game_panel: Control = $FullScreen/GamePanel
@onready var info: Label = $FullScreen/TextPanel/Panel/InfoLabel

var idle_color := Color.WHITE  # read from cell.tscn
var letters: Array[String] = []   # letters[i] is the letter of grid cell i, fixed for the playthrough
var cells: Array[Control] = []
var level := 1
var step := 0
var accepting_input := false
var _run_id := 0   # invalidates in-flight sequence playback


func _ready() -> void:
	_build_grid()
	info.text = "Press Start when you are ready."
	text_panel.hide()
	game_panel.hide()
	start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	start_panel.hide()
	text_panel.show()
	game_panel.show()
	level = 1
	_start_level()


## Failure: back to the start screen. Pressing Start begins a new playthrough (new grid, level 1).
func _return_to_start() -> void:
	_run_id += 1
	accepting_input = false
	text_panel.hide()
	game_panel.hide()
	start_panel.show()
	_build_grid()
	info.text = "Press Start when you are ready."


func _build_grid() -> void:
	for cell in cells:
		cell.queue_free()
	cells.clear()
	letters.clear()
	# 10 targets + 15 distractors, all unique, shuffled once per playthrough.
	var pool: Array[String] = []
	for code in range("a".unicode_at(0), "z".unicode_at(0) + 1):
		var ch := String.chr(code)
		if not target_sequence.has(ch):
			pool.append(ch)
	pool.shuffle()
	letters.assign(target_sequence)
	letters.append_array(pool.slice(0, grid_size - target_sequence.size()))
	letters.shuffle()

	for i in grid_size:
		var cell: Control = CELL_SCENE.instantiate()
		grid.add_child(cell)
		var label := cell.get_node("Label") as Label
		label.text = letters[i]
		# Style comes from cell.tscn; duplicate so each cell can change colour independently.
		cell.add_theme_stylebox_override("panel", cell.get_theme_stylebox("panel").duplicate())
		cell.gui_input.connect(_on_cell_input.bind(i))
		cells.append(cell)
	idle_color = (cells[0].get_theme_stylebox("panel") as StyleBoxFlat).bg_color


func _start_level() -> void:
	_run_id += 1
	var run := _run_id
	step = 0
	accepting_input = false
	_reset_cells()
	info.text = "Level %d / %d\nMemorize the order..." % [level, target_sequence.size()]
	await get_tree().create_timer(start_delay).timeout
	for n in level:
		if run != _run_id:
			return
		var idx := letters.find(target_sequence[n])  # locate by letter, not by index
		_set_color(idx, color_highlight)
		await get_tree().create_timer(show_time).timeout
		_set_color(idx, idle_color)
		await get_tree().create_timer(gap_time).timeout
	if run != _run_id:
		return
	info.text = "Level %d / %d\nYour turn: repeat the order." % [level, target_sequence.size()]
	accepting_input = true


func _on_cell_input(event: InputEvent, index: int) -> void:
	if not accepting_input:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if letters[index] == target_sequence[step]:
		_set_color(index, color_right)
		step += 1
		if step == level:
			accepting_input = false
			_level_complete()
	else:
		accepting_input = false
		_set_color(index, color_wrong)
		info.text = "Wrong! You failed."
		await get_tree().create_timer(wrong_delay).timeout
		_return_to_start()


func _level_complete() -> void:
	if level >= target_sequence.size():
		info.text = "Solved!"
		await get_tree().create_timer(solved_delay).timeout
		puzzle_solved.emit(puzzle_id)
		return
	info.text = "Correct!"
	await get_tree().create_timer(level_complete_delay).timeout
	level += 1
	_start_level()


func _reset_cells() -> void:
	for i in cells.size():
		_set_color(i, idle_color)


func _set_color(index: int, color: Color) -> void:
	var box := cells[index].get_theme_stylebox("panel") as StyleBoxFlat
	box.bg_color = color


func _on_close_pressed() -> void:
	_run_id += 1
	puzzle_closed.emit(puzzle_id)
