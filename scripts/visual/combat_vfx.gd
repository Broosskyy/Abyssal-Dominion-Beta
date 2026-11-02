class_name CombatVfx
extends RefCounted
## M42 lightweight visual-only feedback. It never computes gameplay values.

const CONTRACT := "res://data/combat_visual_contract.json"
static var _data: Dictionary = {}

static func _read() -> Dictionary:
	if not _data.is_empty(): return _data
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT)) if FileAccess.file_exists(CONTRACT) else {}
	_data = parsed if parsed is Dictionary else {}
	return _data

static func color_for(kind: String, id: String) -> Color:
	var group: Dictionary = _read().get(kind, {})
	var entry: Dictionary = group.get(id, {})
	return Color(str(entry.get("color", "#d7a94f")))


static func _spawn_replacement(tree: SceneTree, slot_id: String, position: Vector3) -> bool:
	var resource := VisualAssetCatalog.resource_override("vfx", slot_id, ["tscn"])
	if not resource is PackedScene or tree == null or tree.current_scene == null:
		return false
	var node := (resource as PackedScene).instantiate()
	if node is Node3D:
		(node as Node3D).global_position = position
	tree.current_scene.add_child(node)
	return true

static func _visual_budget_available(tree: SceneTree) -> bool:
	if tree == null or tree.current_scene == null:
		return false
	var limit := roundi(WorldVisualBudgetCatalog.int_value(tree, "max_transient_combat_vfx", 44) * maxf(0.15, _effect_intensity(tree)))
	return tree.get_nodes_in_group("transient_combat_vfx").size() < limit

static func _effect_intensity(tree: SceneTree) -> float:
	var settings := ClientSettings.current(tree) if tree != null else null
	return clampf(float(settings.values.effect_intensity), 0.0, 1.0) if settings != null else 1.0

static func _motion_profile(tree: SceneTree) -> Dictionary:
	var settings := ClientSettings.current(tree) if tree != null else null
	return {"duration": 0.55 if settings != null and bool(settings.values.reduced_motion) else 1.0,
		"scale": 0.72 if settings != null and bool(settings.values.reduced_motion) else 1.0,
		"burst": 0.35 if settings != null and bool(settings.values.reduced_flashes) else 1.0}

static func _authored_profile(tree: SceneTree, id: String) -> Dictionary:
	var catalog := M175FeedbackPresentationCatalog.current(tree)
	return catalog.vfx_profile(id) if catalog != null else {}

static func _tag_transient(node: Node) -> void:
	node.add_to_group("transient_combat_vfx")

static func ammo_impact(tree: SceneTree, effect_id: String, position: Vector3, ammo_id: String = "") -> void:
	if _effect_intensity(tree) <= 0.0:return
	var id := ammo_id if not ammo_id.is_empty() else effect_id
	if _spawn_replacement(tree, "ammo_%s_impact" % id, position): return
	var color := color_for("ammo", id)
	match id:
		"chain":
			_spawn_ring(tree, position, color, 1.0)
		"piercing":
			_spawn_burst(tree, position, color, 0.8, 4)
		"ember":
			_spawn_pulse(tree, position, color, 1.45)
			_spawn_burst(tree, position, color, 1.0, 7)
		"venom":
			_spawn_pulse(tree, position, color, 1.2)
			_spawn_ring(tree, position, color, 0.85)
		"shatter":
			_spawn_burst(tree, position, color, 1.15, 8)
		"spectral":
			_spawn_ring(tree, position, color, 1.35)
			_spawn_pulse(tree, position, color, 1.55)
		"explosive":
			_spawn_pulse(tree, position, color, 1.35)
			_spawn_burst(tree, position, color, 1.05, 6)
		"gravefire":
			_spawn_pulse(tree, position, Color("9bd65b"), 1.28)
			_spawn_ring(tree, position, Color("d56b31"), 1.05)
			_spawn_burst(tree, position, Color("8fcf58"), 0.92, 5)
		_:
			_spawn_pulse(tree, position, color, 1.0)

static func action(tree: SceneTree, id: String, origin: Vector3, target: Node3D = null) -> void:
	if tree == null:return
	if _effect_intensity(tree) <= 0.0:return
	var viewport_size:=tree.root.get_visible_rect().size
	var limit:=MobilePresentationBudget.int_value(viewport_size,float(DisplayServer.screen_get_dpi()),"transient_feedback",7)
	if tree.get_nodes_in_group("transient_combat_vfx").size()>=limit:return
	var replacement_map := {
		"npc_provoked":"vfx_npc_provoked",
		"loot_common":"vfx_loot_common", "loot_uncommon":"vfx_loot_uncommon",
		"loot_rare":"vfx_loot_rare", "loot_epic":"vfx_loot_epic",
		"loot_legendary":"vfx_loot_legendary", "loot_repair":"vfx_loot_repair",
		"admiral_arrival":"vfx_admiral_arrival", "monster_arrival":"vfx_monster_arrival",
		"halloween_portal":"vfx_halloween_portal", "halloween_boss_arrival":"vfx_halloween_boss_arrival",
	}
	var replacement_slot := str(replacement_map.get(id,""))
	if not replacement_slot.is_empty() and _spawn_replacement(tree, replacement_slot, origin):
		return
	var profile := _authored_profile(tree, id)
	var color := Color(str(profile.get("color", color_for("action_items", id).to_html(false))))
	var strength := float(profile.get("strength", 1.2)) * maxf(0.35, _effect_intensity(tree))
	_spawn_pulse(tree, origin, color, strength)
	if target != null and is_instance_valid(target):
		_spawn_pulse(tree, target.global_position, color, strength * 0.84)

static func _spawn_pulse(tree: SceneTree, position: Vector3, color: Color, strength: float) -> void:
	if _effect_intensity(tree) <= 0.0 or not _visual_budget_available(tree): return
	var motion := _motion_profile(tree)
	var mesh := MeshInstance3D.new()
	mesh.name = "CombatVfxPulse"
	var sphere := SphereMesh.new()
	sphere.radius = 0.55
	sphere.height = 1.1
	mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(color.r, color.g, color.b, 0.58)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.6
	mesh.material_override = material
	mesh.global_position = position + Vector3(0, 0.7, 0)
	mesh.scale = Vector3.ONE * 0.35
	_tag_transient(mesh)
	tree.current_scene.add_child(mesh)
	var tween := mesh.create_tween()
	tween.set_parallel(true)
	var duration := 0.42 * float(motion.duration)
	tween.tween_property(mesh, "scale", Vector3.ONE * (1.5 * strength * float(motion.scale)), duration)
	tween.tween_property(material, "albedo_color", Color(material.albedo_color.r, material.albedo_color.g, material.albedo_color.b, 0.0), duration)
	tween.chain().tween_callback(mesh.queue_free)

static func _spawn_ring(tree: SceneTree, position: Vector3, color: Color, strength: float) -> void:
	if _effect_intensity(tree) <= 0.0 or not _visual_budget_available(tree): return
	var motion := _motion_profile(tree)
	var ring := MeshInstance3D.new()
	ring.name = "CombatVfxRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.42
	torus.outer_radius = 0.5
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(color.r, color.g, color.b, 0.72)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.1
	ring.material_override = mat
	ring.global_position = position + Vector3(0, 0.22, 0)
	ring.scale = Vector3.ONE * 0.25
	_tag_transient(ring)
	tree.current_scene.add_child(ring)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	var duration := 0.5 * float(motion.duration)
	tween.tween_property(ring, "scale", Vector3.ONE * (1.5 * strength * float(motion.scale)), duration)
	tween.tween_property(mat, "albedo_color", Color(mat.albedo_color.r, mat.albedo_color.g, mat.albedo_color.b, 0.0), duration)
	tween.chain().tween_callback(ring.queue_free)

static func _spawn_burst(tree: SceneTree, position: Vector3, color: Color, strength: float, count: int) -> void:
	if _effect_intensity(tree) <= 0.0 or not _visual_budget_available(tree): return
	var motion := _motion_profile(tree)
	var visible_count := maxi(1, roundi(count * float(motion.burst) * maxf(0.35, _effect_intensity(tree))))
	for i in visible_count:
		var shard := MeshInstance3D.new()
		shard.name = "CombatVfxShard"
		var box := BoxMesh.new()
		box.size = Vector3(0.06, 0.06, 0.22)
		shard.mesh = box
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.6
		shard.material_override = mat
		shard.global_position = position + Vector3(0, 0.45, 0)
		shard.rotation_degrees.y = 360.0 * float(i) / maxf(1.0, float(visible_count))
		_tag_transient(shard)
		tree.current_scene.add_child(shard)
		var angle := TAU * float(i) / maxf(1.0, float(visible_count))
		var target := shard.global_position + Vector3(cos(angle), 0.25 + 0.05 * (i % 2), sin(angle)) * (1.0 + strength)
		var tween := shard.create_tween()
		tween.set_parallel(true)
		var duration := 0.38 * float(motion.duration)
		tween.tween_property(shard, "global_position", target, duration)
		tween.tween_property(mat, "albedo_color", Color(mat.albedo_color.r, mat.albedo_color.g, mat.albedo_color.b, 0.0), duration)
		tween.chain().tween_callback(shard.queue_free)
