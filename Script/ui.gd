extends CanvasLayer

func _on_interact_button_pressed() -> void:
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)

	var release := InputEventAction.new()
	release.action = "interact"
	release.pressed = false
	Input.parse_input_event(release)

func _on_save_pressed() -> void:
	GameManager.save_game()


func _on_setting_button_pressed() -> void:
	pass # Replace with function body.


func _on_save_button_pressed() -> void:
	GameManager.save_game()


func _on_delete_button_pressed() -> void:
	GameManager.delete_save()


func _on_restart_button_pressed() -> void:
	GameManager.restart_game()
