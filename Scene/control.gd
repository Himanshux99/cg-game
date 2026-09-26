extends Control

# Tracks whether this specific UI component is currently being dragged
var is_dragging: bool = false

# Stores the offset between the initial touch point and the UI component's origin
var touch_offset: Vector2 = Vector2.ZERO


func _gui_input(event: InputEvent) -> void:
	# 1. Detect initial touch (Finger pressed down)
	if event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			# Calculate offset so the object doesn't jump to the finger's center position
			touch_offset = global_position - event.position
		else:
			# Finger lifted, stop dragging
			is_dragging = false

	# 2. Detect dragging motion (Finger moving across the screen)
	elif event is InputEventScreenDrag and is_dragging:
		# Update the global position based on finger movement plus our initial offset
		global_position = event.position + touch_offset
