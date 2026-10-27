class_name ComingSoon
extends CanvasLayer
## Full-screen "coming soon" notice shown once the last available puzzle is solved.
## Use ComingSoon.show_over(node) to add it to the running scene.

const MAIN_MENU_SCENE := "res://Scene/MainMenu.tscn"


static func show_over(host: Node) -> void:
	host.get_tree().root.add_child(ComingSoon.new())


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	UIManager.set_group_visible("MobileControlUi", false)

	var root := Control.new()
	root.theme = load("res://GlobalTheme.tres")
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.04, 0.08, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)

	column.custom_minimum_size = Vector2(minf(720.0, get_viewport().get_visible_rect().size.x - 80.0), 0)
	column.add_child(_make_label("COMING SOON", 48, Color.WHITE))
	column.add_child(_make_label("You've reached the end of the current version.", 18, Color(0.8, 0.85, 0.95)))
	column.add_child(_make_label("The story continues in the next update.\nThanks for playing!", 18, Color(0.8, 0.85, 0.95)))

	var style := StyleBoxTexture.new()
	style.texture = load("res://Assets/UI/green.png")
	style.texture_margin_left = 4.0
	style.texture_margin_top = 4.0
	style.texture_margin_right = 4.0
	style.texture_margin_bottom = 4.0
	var button := Button.new()
	button.text = "MAIN MENU"
	button.custom_minimum_size = Vector2(240, 52)
	button.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(_go_home)
	var row := CenterContainer.new()
	row.add_child(button)
	column.add_child(row)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Saves the run, then returns to the title screen where Continue picks it back up.
func _go_home() -> void:
	GameManager.save_game()
	get_tree().paused = false
	GameManager.game_loaded = false
	GameManager.player = null
	SceneManager.reset()
	UIManager.set_group_visible("MobileControlUi", true)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	queue_free()
