class_name WorldVisualProfileCatalog
extends RefCounted
const PROFILE_PATH := "res://data/m67_world_visual_profiles.json"
const LOD_PATH := "res://data/m67_world_lod_contract.json"
static var _profiles: Dictionary = {}
static var _lod: Dictionary = {}

static func _ensure() -> void:
	if not _profiles.is_empty(): return
	var p: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
	_profiles = p.get("profiles",{}) if p is Dictionary else {}
	var l: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOD_PATH))
	_lod = l.get("tiers",{}) if l is Dictionary else {}

static func profile(id: String) -> Dictionary:
	_ensure()
	return _profiles.get(id,{}).duplicate(true)

static func quality(tree: SceneTree) -> Dictionary:
	_ensure()
	var id := str(tree.root.get_meta("quality_tier","high")) if tree != null else "high"
	return _lod.get(id,_lod.get("high",{})).duplicate(true)

static func apply_fallback(root: Node3D, id: String, user_replacement: bool) -> void:
	if root == null: return
	_ensure()
	var p: Dictionary = _profiles.get(id,{})
	if p.is_empty(): return
	if not user_replacement:
		var a: Array = p.get("scale",[1,1,1])
		if a.size() == 3: root.scale *= Vector3(float(a[0]),float(a[1]),float(a[2]))
		root.rotation.y += deg_to_rad(float(p.get("rotation_y_deg",0)))
	var q := quality(root.get_tree())
	var bias := minf(float(p.get("lod_bias",1.0)),float(q.get("island_lod_bias",1.0)))
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		(mesh as MeshInstance3D).lod_bias = bias
	root.set_meta("m67_world_profile",id)
	root.set_meta("m67_palette",str(p.get("palette","")))
