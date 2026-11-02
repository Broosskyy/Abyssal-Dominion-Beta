class_name ShipyardVisualResolver
extends RefCounted

static func model_slot_for(ship_id: String) -> String:
	if ship_id.begins_with("ship_main_"):
		return ship_id
	return {
		"barco_low":"ship_small",
		"clipper":"ship_medium",
		"chalupa":"ship_large",
	}.get(ship_id, "ship_medium")

static func fallback_model_slot_for(ship_id: String) -> String:
	if not ship_id.begins_with("ship_main_"):
		return model_slot_for(ship_id)
	var fallback := MainProgressionFleet.fallback_profile(ship_id)
	return {
		"barco_low":"ship_small",
		"clipper":"ship_medium",
		"chalupa":"ship_large",
	}.get(fallback, "ship_medium")

static func install_preview(parent: Node3D, ship_id: String) -> Node3D:
	var direct_slot := model_slot_for(ship_id)
	var replacement := VisualAssetCatalog.model_override(direct_slot)
	if not replacement.is_empty():
		return _install_direct_override(parent, direct_slot, replacement)
	return AssetVisualLibrary.install(parent, fallback_model_slot_for(ship_id))

static func _install_direct_override(parent: Node3D, slot_id: String, replacement: Dictionary) -> Node3D:
	var path := str(replacement.get("path",""))
	if path.is_empty() or not ResourceLoader.exists(path): return null
	var packed := load(path) as PackedScene
	if packed == null: return null
	var instance := packed.instantiate() as Node3D
	if instance == null or not AssetVisualLibrary.visual_only(instance):
		if instance != null: instance.free()
		return null
	var visual := Node3D.new()
	visual.name = "AssetVisual"
	instance.name = "Model"
	instance.scale = replacement.get("scale", Vector3.ONE)
	instance.position = replacement.get("offset", Vector3.ZERO)
	instance.rotation_degrees = replacement.get("rotation_degrees", Vector3.ZERO)
	visual.add_child(instance)
	var previous := parent.get_node_or_null("AssetVisual")
	if previous != null:
		parent.remove_child(previous)
		previous.queue_free()
	visual.set_meta("asset_id", slot_id)
	visual.set_meta("source_path", path)
	visual.set_meta("classification", "USER_REPLACEMENT")
	parent.add_child(visual)
	parent.set_meta("hud_visual_bounds", AssetVisualLibrary.bounds_of(visual))
	return visual

static func card_slot_for(ship_id: String) -> String:
	if ship_id.begins_with("ship_main_"):
		return "ship_card_main_" + ship_id.trim_prefix("ship_main_")
	return "ship_card_" + ship_id
