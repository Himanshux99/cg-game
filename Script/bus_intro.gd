extends Node2D

## Opening cutscene for Part-1: a bus rolls in, drops the player off, keeps
## driving off-screen (and deletes itself), then after a short beat the
## start monologue plays and control is handed over.
##
## Attach this script to a Node2D in Part-1.tscn (the "Part-1" root works
## fine) and wire up the exports below in the Inspector.

@export var player: CharacterBody2D
@export var bus: Sprite2D
@export var monologue_path: String = "res://Script/Dialogues/startMonologue.json"

@export var animate_bus_arrival: bool = true
@export var bus_enter_offset: Vector2 = Vector2(900, 0)
@export var bus_travel_time: float = 2.0

# How far past the drop point the bus keeps driving before it's deleted.
# Make sure this clears the camera view at your zoom level.
@export var bus_exit_offset: Vector2 = Vector2(900, 0)
@export var bus_exit_time: float = 2.0

# Beat between the player being dropped off and the monologue starting.
@export var pre_dialogue_delay: float = 1.0

# --- DROP POINT -----------------------------------------------------------
# This is where the player ends up after being dropped off.
# Add a Marker2D anywhere in the scene named "startPosition" (at the bus
# stop) and it will be found automatically. You can also assign a specific
# node here directly, which takes priority over the name lookup.
# If neither is found, it falls back to the bus's own position.
@export var drop_point: NodePath
const DROP_MARKER_NAME := "startPosition"
# ---------------------------------------------------------------------------

const INTRO_STATE_ID := "part1_bus_intro"
const MOBILE_UI_GROUP := "MobileControlUi"

var _camera: Camera2D


func _ready() -> void:
	if SaveManager.get_object_state(INTRO_STATE_ID).get("played", false):
		bus.queue_free()
		return

	_play_intro()


func _play_intro() -> void:
	UIManager.set_group_visible(MOBILE_UI_GROUP, false)

	player.visible = false
	player.set_physics_process(false)
	player.set_process(false)

	# The gameplay camera lives under the player - hand it over to the bus
	# for the cutscene so it tracks the bus arriving, then hand it back.
	_camera = player.get_node_or_null("Camera2D")
	if _camera and bus:
		_camera.reparent(bus, false)
		_camera.position = Vector2.ZERO

	if animate_bus_arrival and bus:
		var drop_position := bus.position
		bus.position = drop_position + bus_enter_offset
		var tween := create_tween()
		tween.tween_property(bus, "position", drop_position, bus_travel_time)
		tween.finished.connect(_on_bus_dropped_off)
	else:
		_on_bus_dropped_off()


func _on_bus_dropped_off() -> void:
	player.global_position = _get_drop_position()
	player.visible = true

	# Cut back to the player so the bus visibly drives off out of frame.
	if _camera:
		_camera.reparent(player, false)
		_camera.position = Vector2.ZERO

	_send_bus_off()

	await get_tree().create_timer(pre_dialogue_delay).timeout
	_start_monologue()


func _send_bus_off() -> void:
	if not bus:
		return
	var exit_tween := create_tween()
	exit_tween.tween_property(bus, "position", bus.position + bus_exit_offset, bus_exit_time)
	exit_tween.finished.connect(bus.queue_free)


func _start_monologue() -> void:
	Dialogue.dialogue_ended.connect(_on_monologue_ended, CONNECT_ONE_SHOT)
	Dialogue.start_dialogue_from_json(monologue_path)


func _on_monologue_ended() -> void:
	player.set_physics_process(true)
	player.set_process(true)

	GameManager.object_changed(INTRO_STATE_ID, {"played": true})


func _get_drop_position() -> Vector2:
	if not drop_point.is_empty():
		var assigned := get_node_or_null(drop_point)
		if assigned:
			return assigned.global_position

	var named := _find_node_by_name(get_tree().current_scene, DROP_MARKER_NAME)
	if named:
		return named.global_position

	return bus.global_position


func _find_node_by_name(node: Node, target_name: String) -> Node2D:
	for child in node.get_children():
		if child.name == target_name:
			return child
		var found := _find_node_by_name(child, target_name)
		if found:
			return found
	return null


func _on_2d_body_entered_closedarea(body: Node2D) -> void:
	pass # Replace with function body.
