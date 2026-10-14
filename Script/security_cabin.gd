extends Node2D

@export_file("*.json") var dialogue_file: String
## Played the first time the player comes back with the enrollment form.
@export_file("*.json") var approved_dialogue_file: String = "res://Script/Dialogues/securityApprovedConvo.json"
## Sibling node in the level that blocks the college gate.
@export var gate_blocker_name := "EnteryClosed"
var isEntered = false

func _ready() -> void:
	_open_gate_if_admitted()
	# The save is loaded after this node is ready, so check again then.
	InventoryManager.inventory_reloaded.connect(_open_gate_if_admitted)


func _open_gate_if_admitted() -> void:
	if _is_admitted():
		_open_gate()


func _is_admitted() -> bool:
	return SaveManager.get_object_state("security_guard").get("admitted", false)


func _open_gate() -> void:
	var blocker := get_parent().get_node_or_null(gate_blocker_name)
	if blocker == null:
		return
	for child in blocker.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and isEntered:
		start_dialogue()
	pass

func start_dialogue() -> void:
	if _is_admitted():
		return
	if InventoryManager.has_item("form"):
		if not Dialogue.dialogue_ended.is_connected(_on_approved_dialogue_ended):
			Dialogue.dialogue_ended.connect(_on_approved_dialogue_ended, CONNECT_ONE_SHOT)
		Dialogue.start_dialogue_from_json(approved_dialogue_file)
		return
	if not Dialogue.dialogue_ended.is_connected(_on_dialogue_ended):
		Dialogue.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)
	Dialogue.start_dialogue_from_json(dialogue_file)


func _on_dialogue_ended() -> void:
	# Chat finished: remember it and make the cafe door glow to point the player there
	GameManager.object_changed("security_guard", {"talked": true})
	get_tree().call_group("cafe_door", "startGlow")

func _on_approved_dialogue_ended() -> void:
	GameManager.object_changed("security_guard", {"talked": true, "admitted": true})
	_open_gate()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		isEntered = true


func _on_2d_body_entered_clg_gate(body: Node2D) -> void:
	if body.is_in_group("Player"):
		start_dialogue()
