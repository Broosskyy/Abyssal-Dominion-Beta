class_name HarborModuleVisualAdapter
extends Node

func apply_to_port(port: Node3D) -> void:
	if port == null: return
	for socket_name in ["WorkshopSocket","MerchantSocket","RepairYardSocket","SupportPierSocket"]:
		var socket := port.get_node_or_null(socket_name) as Node3D
		if socket == null: continue
		var slot := str(socket.get_meta("production_slot",""))
		var override := VisualAssetCatalog.model_override(slot)
		if override.is_empty(): continue
		var scene := load(str(override.path)) as PackedScene
		if scene == null: continue
		var old := socket.get_node_or_null("Placeholder")
		if old != null: old.queue_free()
		var visual := scene.instantiate() as Node3D
		if visual == null: continue
		visual.name = "ReplacementVisual"
		visual.scale = override.scale
		visual.position = override.offset
		visual.rotation_degrees = override.rotation_degrees
		socket.add_child(visual)
