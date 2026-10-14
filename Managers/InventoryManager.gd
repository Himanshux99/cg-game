extends Node
## Single place that knows which items exist and which ones the player owns.
## The UI (ui.gd) listens to the signals and draws the items into the inventory panel.
##
## Adding a new item = add one line to ITEMS, then call InventoryManager.add_item("id").

signal item_added(item_id: String)
## Emitted after the save file is loaded, so the UI can redraw.
signal inventory_reloaded

## item id -> UI component scene shown in the inventory panel.
const ITEMS := {
	"form": preload("res://Assets/UI/Components/FormItem.tscn"),
}

## Ids the player owns, in the order they were collected.
func get_items() -> Array:
	return SaveManager.get_inventory()


func has_item(item_id: String) -> bool:
	return get_items().has(item_id)


## Gives the player an item (ignored if already owned or unknown) and saves.
func add_item(item_id: String) -> void:
	if not ITEMS.has(item_id):
		push_warning("InventoryManager: unknown item '%s' - add it to ITEMS" % item_id)
		return
	if has_item(item_id):
		return
	SaveManager.add_inventory_item(item_id)
	SaveManager.save_game()
	item_added.emit(item_id)


func create_item_node(item_id: String) -> Control:
	return ITEMS[item_id].instantiate()
