extends CanvasLayer

@onready var _items_box: HBoxContainer = $InvetoryPanel/MarginContainer/ItemHBoxContainer


func _ready() -> void:
	InventoryManager.item_added.connect(_show_item)
	# Items are saved: redraw now, and again once the save file has loaded.
	InventoryManager.inventory_reloaded.connect(_refresh_inventory)
	_refresh_inventory()


## Clears the container and redraws every owned item.
func _refresh_inventory() -> void:
	for child in _items_box.get_children():
		_items_box.remove_child(child)
		child.queue_free()
	for item_id in InventoryManager.get_items():
		_show_item(item_id)


## Adds the item's UI component to the inventory row.
func _show_item(item_id: String) -> void:
	for child in _items_box.get_children():
		if child.get_meta("item_id", "") == item_id:
			return
	var item := InventoryManager.create_item_node(item_id)
	item.set_meta("item_id", item_id)
	_items_box.add_child(item)


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
	$SettingsPanel.toggle()


func _on_save_button_pressed() -> void:
	GameManager.save_game()
