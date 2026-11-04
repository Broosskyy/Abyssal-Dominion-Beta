class_name ReferencePortAdapter
extends Node

const ROOT := "res://assets/recovered_test/m8/"


func _ready() -> void:
	_build_visual.call_deferred()


func _build_visual() -> void:
	if not is_inside_tree():
		return
	var owner_port := get_parent() as Node3D
	if AssetVisualLibrary.placeholders(get_tree()) and AssetVisualLibrary.install(owner_port, P0VisualSlotResolver.harbor_slot(owner_port)) != null:
		var dock := owner_port.get_node_or_null("Dock/Pier") as Node3D
		if dock != null: dock.hide()
		for child in owner_port.get_children():
			if child is MeshInstance3D: child.hide()
		return
	var mesh_path := ROOT + "harbor/wooden_pier.obj"
	if not ResourceLoader.exists(mesh_path):
		return
	var port := get_parent() as Node3D
	var procedural_pier := port.get_node_or_null("Dock/Pier") as MeshInstance3D
	if procedural_pier != null:
		procedural_pier.visible = false
	var mesh := load(mesh_path) as Mesh
	if mesh == null:
		return
	var instance := MeshInstance3D.new()
	instance.name = "RecoveredWoodenPier"
	instance.mesh = mesh
	instance.scale = Vector3.ONE * 0.42
	instance.position.y = 0.55
	var texture_path := ROOT + "textures/wooden_pier.png"
	instance.material_override = RecoveredMaterialCache.surface(texture_path, "", Color.WHITE, 0.8)
	instance.set_meta("classification", "RECOVERED_TEST_ASSET")
	port.add_child(instance)
	_add_lighthouse(port)


func _add_lighthouse(port: Node3D) -> void:
	var mesh_path := ROOT + "harbor/lighthouse.obj"
	if not ResourceLoader.exists(mesh_path):
		return
	var mesh := load(mesh_path) as Mesh
	if mesh == null:
		return
	for child in port.get_children():
		if child is MeshInstance3D and child.name == "Lighthouse":
			child.visible = false
	var instance := MeshInstance3D.new()
	instance.name = "RecoveredLighthouse"
	instance.mesh = mesh
	instance.scale = Vector3.ONE * 0.48
	instance.position = Vector3(-3.0, 0.55, -1.4)
	instance.material_override = RecoveredMaterialCache.surface("", "", Color("d9d0ba"), 0.72)
	instance.set_meta("classification", "RECOVERED_TEST_ASSET")
	port.add_child(instance)
