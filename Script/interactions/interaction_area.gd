extends Area2D
class_name InteractionArea

@export var action_name: String = "Interact"

## Toggle to lock/unlock this interaction at runtime. While disabled, the
## "Press [ ] to ..." prompt never shows and the area can't be interacted
## with, even if the player is standing inside it.
@export var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled:
			InteractionManager.unregister_area(self)
		elif _body_inside:
			InteractionManager.register_area(self)

var interact: Callable = func():
	pass

var _body_inside := false

func _on_body_entered(_body: Node2D) -> void:
	_body_inside = true
	if enabled:
		InteractionManager.register_area(self)

func _on_body_exited(_body: Node2D) -> void:
	_body_inside = false
	InteractionManager.unregister_area(self)
