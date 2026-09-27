extends Node

## Toggles visibility and input for every node in a group at once.
## To hide a piece of UI during some game state (dialogue, cutscene, etc),
## just add it to the matching group in the editor's Groups tab -
## no script changes needed anywhere.
func set_group_visible(group_name: String, is_visible: bool) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if node.has_method("set_visible"):
			node.visible = is_visible
		node.process_mode = Node.PROCESS_MODE_INHERIT if is_visible else Node.PROCESS_MODE_DISABLED
