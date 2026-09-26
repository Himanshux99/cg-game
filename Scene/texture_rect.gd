extends Control

# Tracks whether this specific UI component is currently being dragged
var is_dragging: bool = false


func _gui_input(event: InputEvent) -> void:
	# Detect initial touch on the UI element
	if event is InputEventScreenTouch and event.pressed:
		is_dragging = true
		# Accept the event so other UI nodes under it don't receive it
		accept_event()


func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
		
	# Handle when finger lifts anywhere on the screen
	if event is InputEventScreenTouch and not event.pressed:
		is_dragging = false
		
	# Handle smooth drag movement using relative distance
	elif event is InputEventScreenDrag:
		global_position += event.relative
