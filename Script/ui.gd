extends CanvasLayer

func _on_interact_button_pressed() -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)

func _on_save_pressed() -> void:
	GameManager.save_game()


func _on_delete_pressed() -> void:
	GameManager.delete_save()


func _on_setting_button_pressed() -> void:
	pass # Replace with function body.


func _on_save_button_pressed() -> void:
	GameManager.save_game()
