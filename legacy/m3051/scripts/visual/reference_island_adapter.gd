class_name ReferenceIslandAdapter
extends Node

const ROOT := "res://assets/recovered_test/m8/"


func _ready() -> void:
	_build_visual.call_deferred()

func _build_visual() -> void:
	if not is_inside_tree() or is_queued_for_deletion(): return
	var island := get_parent() as Node3D
	var profile_name := str(island.get_meta("island_profile", "tropical_04"))
	if AssetVisualLibrary.placeholders(get_tree()):
		var r := float(island.get_meta("island_radius", 5.0))
		var a: Vector2 = island.get_meta("island_aspect", Vector2.ONE)
		var id := P0VisualSlotResolver.island_slot(island, profile_name)
		if AssetVisualLibrary.install(island, id, Vector3(r * a.x, r, r * a.y)) != null:
			for child in island.get_children():
				if child is MeshInstance3D and not child.is_in_group("shoreline_foam"): child.visible = false
			return
	var profile: Dictionary = _profile(profile_name)
	var main_path := str(profile.get("main", ""))
	if not ResourceLoader.exists(main_path):
		return
	var radius := float(island.get_meta("island_radius", 5.0))
	var aspect: Vector2 = island.get_meta("island_aspect", Vector2.ONE)
	var reference_scale := radius * 2.0 / float(profile.get("reference_size", 90.0))
	var root := Node3D.new()
	root.name = "RecoveredIsland_%s" % profile_name
	root.scale = Vector3(reference_scale * aspect.x, reference_scale, reference_scale * aspect.y)
	root.position.y = float(profile.get("waterline", 0.1))
	root.set_meta("classification", "RECOVERED_TEST_ASSET")
	island.add_child.call_deferred(root)
	var keep_procedural: Array = profile.get("keep_procedural", [])
	for child in island.get_children():
		if child is MeshInstance3D and not keep_procedural.has(str(child.name)):
			child.visible = false
	var parts: Array = profile.get("parts", [])
	for part_value in parts:
		var part: Dictionary = part_value
		var tint: Color = part.get("tint", Color.WHITE)
		_add_part.call_deferred(
			root,
			str(part.get("name", "Part")),
			str(part.get("mesh", "")),
			str(part.get("texture", "")),
			tint,
		)


func _profile(profile_name: String) -> Dictionary:
	var sand := ROOT + "textures/underwater_sand.png"
	var coast := ROOT + "textures/island_color.png"
	match profile_name:
		"tropical_01":
			return {
				"main": ROOT + "islands/tropical_island_01_main.obj",
				"reference_size": 36.0,
				"waterline": 0.08,
				"keep_procedural": [],
				"parts": [
					{"name": "Main", "mesh": ROOT + "islands/tropical_island_01_main.obj", "texture": ROOT + "textures/tropical_island_01.png", "tint": Color.WHITE},
					{"name": "Coast", "mesh": ROOT + "islands/tropical_island_01_coast.obj", "texture": coast, "tint": Color("ead39a")},
					{"name": "Bottom", "mesh": ROOT + "islands/tropical_island_01_bottom.obj", "texture": sand, "tint": Color("8c7654")},
				],
			}
		"desert_06":
			return {
				"main": ROOT + "islands/desert_island_06_main.obj",
				"reference_size": 90.0,
				"waterline": 0.1,
				"keep_procedural": ["Underside", "Coast"],
				"parts": [{"name": "Main", "mesh": ROOT + "islands/desert_island_06_main.obj", "texture": ROOT + "textures/desert_island_06.png", "tint": Color.WHITE}],
			}
		"snow_02":
			return {
				"main": ROOT + "islands/snow_island_02_main.obj",
				"reference_size": 50.0,
				"waterline": 0.08,
				"keep_procedural": [],
				"parts": [
					{"name": "Main", "mesh": ROOT + "islands/snow_island_02_main.obj", "texture": ROOT + "textures/snow_island_02.png", "tint": Color.WHITE},
					{"name": "Coast", "mesh": ROOT + "islands/snow_island_02_coast.obj", "texture": coast, "tint": Color("d9e7e9")},
					{"name": "Bottom", "mesh": ROOT + "islands/snow_island_02_bottom.obj", "texture": sand, "tint": Color("87959d")},
				],
			}
		_:
			return {
				"main": ROOT + "islands/tropical_island_04_main.obj",
				"reference_size": 90.0,
				"waterline": 0.12,
				"keep_procedural": [],
				"parts": [
					{"name": "Main", "mesh": ROOT + "islands/tropical_island_04_main.obj", "texture": ROOT + "textures/tropical_island_04.png", "tint": Color.WHITE},
					{"name": "Coast", "mesh": ROOT + "islands/tropical_island_04_coast.obj", "texture": coast, "tint": Color("e8d09a")},
					{"name": "Bottom", "mesh": ROOT + "islands/tropical_island_04_bottom.obj", "texture": sand, "tint": Color("8c7654")},
				],
			}


func _add_part(parent: Node3D, part_name: String, mesh_path: String, texture_path: String, tint: Color) -> void:
	if not ResourceLoader.exists(mesh_path):
		return
	var mesh := load(mesh_path) as Mesh
	if mesh == null:
		return
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	if part_name == "Coast":
		instance.material_override = _coast_material()
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(instance)
		return
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	instance.material_override = RecoveredMaterialCache.surface(texture_path, "", tint, 0.78)
	parent.add_child(instance)


func _coast_material() -> ShaderMaterial:
	# Unity coast_new01 (material 53) uses Foam (texture 270), not a rock atlas.
	# Recovered UV scale/tint alpha/speed; shader math is a Godot approximation.
	return RecoveredMaterialCache.coast()
