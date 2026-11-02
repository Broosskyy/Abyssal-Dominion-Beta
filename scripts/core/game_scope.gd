class_name GameScope
extends RefCounted

static func owner_of(node: Node) -> Node:
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor.is_in_group("gameplay_root"):
			return ancestor
		ancestor = ancestor.get_parent()
	return node.get_tree().current_scene if node.get_tree().current_scene != null else node.get_parent()
