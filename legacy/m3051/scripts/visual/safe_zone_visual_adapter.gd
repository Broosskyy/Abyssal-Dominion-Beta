class_name SafeZoneVisualAdapter
extends RefCounted

static func install_if_available(parent: Node3D, slot_id: String) -> Node3D:
	var resource := VisualAssetCatalog.resource_override("vfx", slot_id, ["tscn"])
	if not resource is PackedScene:
		return null
	var node := (resource as PackedScene).instantiate()
	if not node is Node3D:
		if node != null: node.queue_free()
		return null
	var visual := node as Node3D
	visual.name = "VfxOverride_" + slot_id
	parent.add_child(visual)
	return visual
