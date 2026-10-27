extends Control
## Credits popup shown over the main menu. Tap Close (or the dimmed backdrop) to dismiss.


func _ready() -> void:
	$Backdrop.gui_input.connect(_on_backdrop_input)
	$Center/Panel/Margin/Content/CloseButton.pressed.connect(hide)


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
