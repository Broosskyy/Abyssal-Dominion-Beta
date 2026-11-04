class_name P1RegionalPresentationAdapter
extends RefCounted

static func apply_entity(entity: Node3D, region_id: String, role: String, hero: bool = false) -> void:
	if entity == null: return
	var profile := P1RegionalRuntimeCatalog.region(region_id)
	if profile.is_empty(): return
	var platform := P1RegionalRuntimeCatalog.platform()
	entity.set_meta("m149_region", region_id)
	entity.set_meta("m149_material_profile", (profile.get("material", {}) as Dictionary).duplicate(true))
	entity.set_meta("m149_vfx_profile", str((profile.get("vfx", {}) as Dictionary).get("admiral" if hero else "ship", "")))
	entity.set_meta("m149_lod", str(platform.get("hero_lod" if hero else "standard_lod", "LOD1")))
	_apply_budget(entity, platform, hero)
	var family := "monster" if role == "monster" or str(entity.get_meta("encounter_kind", "")) == "monster" else "ship"
	_apply_placeholder_material(entity, region_id, family)
	if hero: _hero_accent(entity, profile, region_id)

static func apply_harbor(port: Node3D, region_id: String) -> void:
	if port == null: return
	var profile := P1RegionalRuntimeCatalog.region(region_id)
	if profile.is_empty(): return
	port.set_meta("m149_region", region_id)
	port.set_meta("m149_vfx_profile", str((profile.get("vfx", {}) as Dictionary).get("harbor", "")))
	port.set_meta("m149_lod", str(P1RegionalRuntimeCatalog.platform().get("hero_lod", "LOD1")))
	_apply_placeholder_material(port, region_id, "harbor")
	_hero_accent(port, profile, region_id)

static func apply_world_asset(root: Node3D, region_id: String, family: String = "world") -> void:
	if root == null: return
	root.set_meta("m149_region", region_id)
	_apply_placeholder_material(root, region_id, family)

static func _apply_budget(root: Node, platform: Dictionary, hero: bool) -> void:
	var shadow_on := str(platform.get("shadow_mode", "ON")) == "ON"
	var visibility_end := float(platform.get("visibility_end", 0.0))
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow_on else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if visibility_end > 0.0 and not hero: (mesh as MeshInstance3D).visibility_range_end = visibility_end

static func _hero_accent(parent: Node3D, profile: Dictionary, region_id: String) -> void:
	if parent.get_node_or_null("M149RegionalAccent") != null: return
	var material_profile := profile.get("material", {}) as Dictionary
	var accent := MeshInstance3D.new()
	accent.name = "M149RegionalAccent"
	var ring := TorusMesh.new(); ring.inner_radius = 2.9; ring.outer_radius = 3.06
	accent.mesh = ring; accent.position.y = -0.43
	var mat := StandardMaterial3D.new()
	var color := Color(str(material_profile.get("emissive", "63c8d2")))
	mat.albedo_color = Color(color, 0.34); mat.emission_enabled = true; mat.emission = color; mat.emission_energy_multiplier = 0.72
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	accent.material_override = mat; accent.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	accent.set_meta("visual_only", true); accent.set_meta("region", region_id)
	parent.add_child(accent)

static func _apply_placeholder_material(root: Node3D, region_id: String, family: String) -> void:
	var visual := root.get_node_or_null("AssetVisual")
	if visual == null:
		var matches := root.find_children("AssetVisual", "Node3D", true, false)
		if not matches.is_empty(): visual = matches[0]
	if visual == null or str(visual.get_meta("classification", "")) not in ["ORIGINAL_PLACEHOLDER_NOT_UNITY", "M151_PROCEDURAL_SILHOUETTE_FALLBACK"]: return
	var path := P1RegionalVisualAcceptanceCatalog.material_path(region_id, family)
	var material: Material = null
	if not path.is_empty(): material = load(path) as Material
	if material == null: return
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = material
	visual.set_meta("m150_material_variant", "%s:%s" % [region_id, family])
