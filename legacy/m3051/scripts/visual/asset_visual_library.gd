class_name AssetVisualLibrary
extends RefCounted
## Only replaces graphics. Collision, gameplay state and sockets belong to wrappers.
const MANIFEST := "res://assets/placeholder_pack/manifest.json"
const M298ShipVisualAnimationRigScript = preload("res://scripts/visual/m298_ship_visual_animation_rig.gd")
static var catalog: Dictionary = {}
static var scenes: Dictionary = {}
static var reference_bounds: Dictionary = {}

static func placeholders(tree: SceneTree) -> bool:
	var settings := ClientSettings.current(tree)
	return settings == null or settings.values.visual_assets == "placeholder"

static func entries() -> Dictionary:
	if catalog.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if data is Dictionary: catalog = data.get("assets", {})
	return catalog

static func ship_slot(profile: String, enemy: bool) -> String:
	if profile == "procedural_monster": return "monster_kraken"
	if enemy: return "npc_admiral" if profile == "chalupa" else "npc_corsair"
	return {"barco_low": "ship_small", "chalupa": "ship_large"}.get(profile, "ship_medium")

static func install(parent: Node3D, id: String, size: Vector3 = Vector3.ONE) -> Node3D:
	var entry: Dictionary = entries().get(id, {})
	if entry.is_empty(): entry = ProductionWaveCatalog.entry(id)
	if entry.is_empty(): entry = P1RegionalAssetCatalog.entry(id)
	if entry.is_empty(): entry = ShipProductionArchitecture.entry(id)
	var fallback:=str(entry.get("path",""))
	var replacement:=VisualAssetCatalog.model_override(id)
	var production_slot:=ProductionPlaceholderContract.slot(id)
	var hero:=str(production_slot.get("priority","P3")) in ["P0","P2"]
	var selected:=VisualQualityResolver.select_path(entry,replacement,hero)
	var path:=str(selected.get("path",fallback))
	var model:=_instantiate(path)
	var m151_fallback := false
	var clean_room_placeholder := str(entry.get("classification", "")).contains("GLB_PLACEHOLDER")
	if model == null and not ShipProductionArchitecture.entry(id).is_empty():
		model = LateFleetSilhouetteFactory.create(entry)
		m151_fallback = model != null
	if model == null or not visual_only(model):
		if model != null: model.free()
		VisualAssetCatalog._note(id + ": invalid visual model; using placeholder")
		model = LateFleetSilhouetteFactory.create(entry) if not ShipProductionArchitecture.entry(id).is_empty() else _instantiate(fallback)
		m151_fallback = model != null and not ShipProductionArchitecture.entry(id).is_empty()
		replacement = {}
		path=fallback
	if model == null: return null
	var visual := Node3D.new()
	visual.name = "AssetVisual"
	model.name = "Model"
	visual.add_child(model)
	if not replacement.is_empty():
		model.rotation_degrees += replacement.rotation_degrees
		var factor := 1.0
		if replacement.fit_reference:
			if not reference_bounds.has(fallback):
				var original := _instantiate(fallback)
				reference_bounds[fallback] = bounds_of(original) if original != null else AABB()
				if original != null: original.free()
			var target: AABB = reference_bounds[fallback]
			var actual := bounds_of(model)
			# Fit the footprint, not the sail height. A tall mast must not shrink the hull.
			if target.size.x > 0.0001 and target.size.z > 0.0001 and actual.size.x > 0.0001 and actual.size.z > 0.0001:
				factor = minf(target.size.x / actual.size.x, target.size.z / actual.size.z)
		model.scale *= replacement.scale * factor
		model.position += replacement.offset
	var previous := parent.get_node_or_null("AssetVisual")
	if previous != null:
		parent.remove_child(previous)
		previous.queue_free()
	visual.scale = size
	visual.set_meta("asset_id", id)
	visual.set_meta("source_path", path)
	visual.set_meta("classification","USER_REPLACEMENT" if not replacement.is_empty() else ("M151_PROCEDURAL_SILHOUETTE_FALLBACK" if m151_fallback else (str(entry.get("classification","CLEAN_ROOM_GLB_PLACEHOLDER")) if clean_room_placeholder else "ORIGINAL_PLACEHOLDER_NOT_UNITY")))
	visual.set_meta("counts_as_final_glb",not m151_fallback and not clean_room_placeholder)
	var compact:bool=InputDeviceProfile.detect(parent.get_viewport().get_visible_rect().size).get("hud_profile","desktop_wide")!="desktop_wide" if parent.is_inside_tree() else false
	var production:=ProductionPlaceholderContract.quality_profile(id,bool(compact))
	visual.set_meta("production_priority",production.get("priority","P3"))
	visual.set_meta("lod_profile",selected.get("lod",production.get("lod","LOD1")))
	visual.set_meta("vfx_quality",selected.get("vfx",production.get("vfx_quality","desktop")))
	visual.set_meta("lod_path_selected",path)
	visual.set_meta("placeholder_replacement_ready",true)
	parent.add_child(visual)
	if ShipAssetAcceptance.is_p0_ship(id):
		ShipVisualProfileCatalog.apply_visual_only(visual, id, not replacement.is_empty())
	if not WorldVisualProfileCatalog.profile(id).is_empty():
		WorldVisualProfileCatalog.apply_fallback(visual, id, not replacement.is_empty())
	if not MonsterVisualProfileCatalog.profile(id).is_empty():
		MonsterVisualProfileCatalog.apply_visual_only(visual, id, not replacement.is_empty())
		MonsterAnimationAdapter.prepare(visual)
	P0NpcFallbackDecorator.apply(visual, id, not replacement.is_empty())
	P0VisualPolish.apply(visual, id, compact, not replacement.is_empty())
	# M298 animates only the complete world-placeholder model below this wrapper.
	# Final user GLBs, previews and the ship's physics/world transform stay untouched.
	if parent is ShipMotor and replacement.is_empty() and M298ShipVisualAnimationRig.supports_slot(id):
		var animation: M298ShipVisualAnimationRig = M298ShipVisualAnimationRigScript.new()
		animation.name = "M298ShipVisualAnimationRig"
		visual.add_child(animation)
	parent.set_meta("hud_visual_bounds", bounds_of(visual))
	return visual

static func _instantiate(path: String) -> Node3D:
	if path.is_empty() or not ResourceLoader.exists(path): return null
	if not scenes.has(path): scenes[path] = load(path) as PackedScene
	var packed := scenes[path] as PackedScene
	return packed.instantiate() as Node3D if packed != null else null

static func visual_only(node: Node) -> bool:
	if node.get_script() != null or node is CollisionObject3D or node is CollisionShape3D or node is NavigationRegion3D or node is Camera3D: return false
	for child in node.get_children():
		if not visual_only(child): return false
	return true

static func bounds_of(root: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D: meshes.append(root)
	for mesh: MeshInstance3D in meshes:
		var relative := Transform3D.IDENTITY
		var node: Node3D = mesh
		while node != null:
			relative = node.transform * relative
			if node == root: break
			node = node.get_parent() as Node3D
		if node == null: continue
		var box := relative * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds
