class_name DraggableComponent
extends Node

@export var target_node: Control

@export_category("Draggable Settings")
## Controls how fast the object follows your finger (1.0 = instant, lower = slower/smoother)
@export_range(0.05, 1.0, 0.05) var tracking_speed: float = 0.25
## Multiplier for overall touch distance (0.5 = moves half as fast as your finger)
@export_range(0.1, 2.0, 0.1) var sensitivity: float = 1.0

var is_dragging: bool = false
var target_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	if not target_node and get_parent() is Control:
		target_node = get_parent()
		
	if target_node:
		target_node.gui_input.connect(_on_target_gui_input)
		# Initialize the target position to match the current spot
		target_position = target_node.global_position


func _process(_delta: float) -> void:
	if not target_node:
		return
		
	# Smoothly glide the UI node toward the calculated target position
	target_node.global_position = target_node.global_position.lerp(target_position, tracking_speed)


func _on_target_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		is_dragging = true
		# Reset target position to match current position when picked up
		target_position = target_node.global_position
		target_node.accept_event()


func _input(event: InputEvent) -> void:
	if not is_dragging or not target_node:
		return
		
	if event is InputEventScreenTouch and not event.pressed:
		is_dragging = false
		
	elif event is InputEventScreenDrag:
		# Update our intended destination using relative motion multiplied by sensitivity
		target_position += event.relative * sensitivity
