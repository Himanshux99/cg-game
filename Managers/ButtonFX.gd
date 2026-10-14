extends Node
## Gives every Button in the game a small "squish and spring back" scale animation on click.
##
## It hooks the SceneTree's node_added signal, so buttons get the effect automatically,
## including ones created at runtime. No setup is needed per button.
##
## Panels: put a Panel (or any Control) in the "click_anim_panel" group and the buttons
## inside it will animate that panel, background and all, instead of just the button.
##
## Opt a button out by adding it to the "no_click_anim" group, or by calling
## `node.set_meta("no_click_anim", true)`.
## Add the effect manually to a non-Button control with `ButtonFX.attach(control)`.

const OPT_OUT_GROUP := &"no_click_anim"
const PANEL_GROUP := &"click_anim_panel"

## Scale while the button is held down.
const PRESSED_SCALE := Vector2(0.92, 0.92)
## Scale reached for a moment when released, before settling at 1.
const OVERSHOOT_SCALE := Vector2(1.06, 1.06)

const PRESS_TIME := 0.06
const RELEASE_TIME := 0.10
const SETTLE_TIME := 0.08

const META_TWEEN := &"_click_anim_tween"
const META_ATTACHED := &"_click_anim_attached"
const META_BASE_SCALE := &"_click_anim_base_scale"
const META_PIVOT_HOOKED := &"_click_anim_pivot_hooked"


func _ready() -> void:
	# Keep animating while the tree is paused (puzzles and dialogue pause the game)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	# Autoloads created before this one (e.g. Dialogue) are already in the tree
	_attach_existing.call_deferred(get_tree().root)


func _attach_existing(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_attach_existing(child)


func _on_node_added(node: Node) -> void:
	if node is Button:
		attach(node)


## Safe to call more than once on the same control.
func attach(control: Control) -> void:
	if control.has_meta(META_ATTACHED):
		return
	if control.is_in_group(OPT_OUT_GROUP) or control.get_meta("no_click_anim", false):
		return
	control.set_meta(META_ATTACHED, true)

	var target := _find_target(control)
	if not target.has_meta(META_BASE_SCALE):
		target.set_meta(META_BASE_SCALE, target.scale)
	if not target.has_meta(META_PIVOT_HOOKED):
		target.set_meta(META_PIVOT_HOOKED, true)
		_center_pivot(target)
		target.resized.connect(_center_pivot.bind(target))

	if control is BaseButton:
		control.button_down.connect(_on_down.bind(target))
		control.button_up.connect(_on_up.bind(target))


## The nearest ancestor in the panel group, or the control itself.
func _find_target(control: Control) -> Control:
	var node := control.get_parent()
	while node:
		if node is Control and node.is_in_group(PANEL_GROUP):
			return node
		node = node.get_parent()
	return control


## Moves the pivot to the middle without visibly moving the control. Changing the pivot
## shifts a scaled control (a flipped one with scale -1, for example), so compensate.
func _center_pivot(control: Control) -> void:
	var old_pivot := control.pivot_offset
	var new_pivot := control.size / 2.0
	if old_pivot == new_pivot:
		return
	var base: Vector2 = control.get_meta(META_BASE_SCALE, control.scale)
	control.position += (old_pivot - new_pivot) * (Vector2.ONE - base)
	control.pivot_offset = new_pivot


func _on_down(target: Control) -> void:
	var base: Vector2 = target.get_meta(META_BASE_SCALE)
	var tween := _new_tween(target)
	tween.tween_property(target, "scale", base * PRESSED_SCALE, PRESS_TIME).set_ease(Tween.EASE_OUT)


func _on_up(target: Control) -> void:
	var base: Vector2 = target.get_meta(META_BASE_SCALE)
	var tween := _new_tween(target)
	tween.tween_property(target, "scale", base * OVERSHOOT_SCALE, RELEASE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", base, SETTLE_TIME).set_ease(Tween.EASE_IN_OUT)


func _new_tween(target: Control) -> Tween:
	var old: Tween = target.get_meta(META_TWEEN) if target.has_meta(META_TWEEN) else null
	if old and old.is_valid():
		old.kill()
	var tween := target.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	target.set_meta(META_TWEEN, tween)
	return tween
