class_name MobileLodController
extends RefCounted
## M100: visual quality policy. Never confuses object visibility with shadow distance.

static func apply(tree: SceneTree) -> void:
	if tree == null:return
	var q:=ShipVisualProfileCatalog.quality(tree)
	tree.root.mesh_lod_threshold=float(q.get("mesh_lod_threshold",1.0))

static func apply_visibility(node:GeometryInstance3D,tree:SceneTree,category:String)->void:
	if node==null or tree==null:return
	var q:=ShipVisualProfileCatalog.quality(tree)
	# Visibility ranges are valid for optional visuals only, never for whole NPC hulls/shadow policy.
	var key:String=str({"minor_vfx":"minor_vfx_distance"}.get(category,""))
	if key.is_empty():return
	var distance:=float(q.get(key,0))
	if distance<=0:return
	node.visibility_range_end=distance
	node.visibility_range_end_margin=3.0
	node.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

static func apply_ship(ship:Node3D,tree:SceneTree)->void:
	if ship==null or tree==null:return
	var q:=ShipVisualProfileCatalog.quality(tree)
	var shadow_hint:=float(q.get("npc_shadow_distance",0.0))
	for child in ship.find_children("*","GeometryInstance3D",true,false):
		var geometry:=child as GeometryInstance3D
		if geometry==null:continue
		# Godot GeometryInstance3D has no generic "shadow distance only" field here.
		# Keep hull visibility independent; expose hint for a later renderer/camera shadow policy.
		if not ship.is_in_group("player"):
			geometry.set_meta("shadow_distance_hint",shadow_hint)
			geometry.set_meta("m100_shadow_hint_not_visibility",true)

static func nameplate_distance(tree:SceneTree)->float:
	if tree==null:return 55.0
	var graphics:=MobileGraphicsProfile.current(tree)
	if graphics.has("nameplate_distance"):
		return float(graphics.get("nameplate_distance",55.0))
	var q:=ShipVisualProfileCatalog.quality(tree)
	return float(q.get("nameplate_distance",55.0))
