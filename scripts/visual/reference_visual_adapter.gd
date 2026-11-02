class_name ReferenceVisualAdapter
extends Node

const ROOT := "res://assets/recovered_test/m8/"
const M12_ROOT := "res://assets/recovered_test/m12/"


func _ready() -> void:
	var ship := get_parent() as Node3D
	call_deferred("apply_profile", str(ship.get_meta("visual_profile", "clipper")))


func apply_profile(profile_name: String) -> void:
	# Roster setup can run before the ship enters the tree; _ready applies later.
	if not is_inside_tree(): return
	var ship := get_parent() as Node3D
	if ship.get_meta("visual_profile", "") == "procedural_monster": profile_name = "procedural_monster"
	for child in ship.get_children():
		if child is Node3D and (str(child.name).begins_with("RecoveredVisual_") or child.name == "AssetVisual"):
			ship.remove_child(child)
			child.queue_free()
	var procedural := ship.get_node_or_null("Visual") as Node3D
	if AssetVisualLibrary.placeholders(get_tree()):
		var slot := P0VisualSlotResolver.monster_slot(ship) if profile_name == "procedural_monster" else P0VisualSlotResolver.npc_slot(ship, profile_name)
		if not ship.is_in_group("enemies") and profile_name != "procedural_monster":
			slot = AssetVisualLibrary.ship_slot(profile_name, false)
		if AssetVisualLibrary.install(ship, slot) != null:
			if procedural != null:
				for child in procedural.get_children():
					if child is Node3D and child.name != "SelectionRing": child.visible = false
			return
	if profile_name == "procedural_monster": return
	if procedural != null:
		for child in procedural.get_children():
			if child.name != "SelectionRing" and child is Node3D:
				child.visible = true
	var profile: Dictionary = _profile(profile_name)
	var mesh_entries: Array = profile.get("meshes", [])
	if profile.is_empty() or mesh_entries.is_empty():
		return
	var first_mesh: Dictionary = mesh_entries[0]
	if not ResourceLoader.exists(str(first_mesh.get("path", ""))):
		return
	var root := Node3D.new()
	root.name = "RecoveredVisual_%s" % profile_name
	root.scale = Vector3.ONE * float(profile.get("scale", 1.0))
	root.position.y = float(profile.get("waterline_offset", 0.0))
	root.set_meta("classification", "RECOVERED_TEST_ASSET")
	root.set_meta("profile", profile_name)
	ship.add_child(root)
	if procedural != null:
		for child in procedural.get_children():
			if child.name != "SelectionRing" and child is Node3D:
				child.visible = false
	for mesh_value in mesh_entries:
		var mesh_data: Dictionary = mesh_value
		_add_mesh(
			root,
			str(mesh_data.get("name", "Mesh")),
			str(mesh_data.get("path", "")),
			mesh_data.get("texture", ""),
			mesh_data.get("normal", ""),
			mesh_data.get("tint", Color.WHITE),
		)
	var bounds := AABB()
	var first := true
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var box := (root.transform * mesh.transform) * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	if not first:
		ship.set_meta("hud_visual_bounds", bounds)


func _profile(profile_name: String) -> Dictionary:
	match profile_name:
		"procedural_monster":
			return {}
		"barco_low":
			return {
				"scale": 0.72,
				"waterline_offset": 0.05,
				"meshes": [{
					"name": "BarcoLow",
					"path": ROOT + "ships/barco_low.obj",
					"texture": ROOT + "textures/barco_base_color.png",
					"tint": Color.WHITE,
				}],
			}
		"chalupa":
			return {
				"scale": 58.0,
				"waterline_offset": 4.55,
				"meshes": [{
					"name": "NPCChalupa",
					"path": ROOT + "ships/npc_chalupa.obj",
					"texture": ROOT + "textures/npc_chalupa_base_color.png",
					"normal": ROOT + "textures/npc_chalupa_normal.png",
				}],
			}
		_:
			return {
				"scale": 14.0,
				"waterline_offset": -0.2,
				"meshes": [
					{
						"name": "Hull",
						"path": ROOT + "ships/clipper_hull_lod3.obj",
						"texture": M12_ROOT + "clipper_hull.png",
					},
					{
						"name": "Sails",
						"path": ROOT + "ships/clipper_sails_lod3.obj",
						# Original 847 Sails_main_diff has no image payload.
						# Use material 347 tint, not a mismatched frigate atlas.
						"tint": Color(0.784314, 0.364706, 0.435294),
					},
					{
						"name": "PortCannons",
						"path": ROOT + "ships/clipper_cannons_port_lod3.obj",
						"texture": M12_ROOT + "clipper_details.png",
					},
					{
						"name": "StarboardCannons",
						"path": ROOT + "ships/clipper_cannons_starboard_lod3.obj",
						"texture": M12_ROOT + "clipper_details.png",
					},
					{
						"name": "Details",
						"path": M12_ROOT + "clipper_details.obj",
						"texture": M12_ROOT + "clipper_details.png",
					},
					{
						"name": "Flags",
						"path": M12_ROOT + "clipper_flags.obj",
						"tint": Color(0.784314, 0.364706, 0.435294),
					},
				],
			}


func _add_mesh(parent: Node3D, display_name: String, mesh_path: String, texture_path: String, normal_path: String, tint: Color) -> void:
	if not ResourceLoader.exists(mesh_path):
		return
	var mesh_resource := load(mesh_path) as Mesh
	if mesh_resource == null:
		return
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = display_name
	mesh_instance.mesh = mesh_resource
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# M16 mockup-inspired material styling, not recovered original sail pixels.
	if display_name == "Sails":
		tint = Color("9b3028") if get_parent().is_in_group("enemies") else Color("d8cba5")
	elif display_name == "Flags":
		tint = Color("172126")
	mesh_instance.material_override = RecoveredMaterialCache.surface(texture_path, normal_path, tint, 0.86 if display_name == "Sails" else 0.62, display_name in ["Sails", "Flags"])
	parent.add_child(mesh_instance)
