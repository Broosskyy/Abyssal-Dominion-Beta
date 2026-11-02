class_name ShipVisualProfileCatalog
extends RefCounted
const PROFILE_PATH := "res://data/m66_p0_ship_visual_profiles.json"
const PALETTE_PATH := "res://data/m66_ship_palette_profiles.json"
const LOD_PATH := "res://data/m66_ship_lod_contract.json"
static var _profiles: Dictionary = {}
static var _palettes: Dictionary = {}
static var _lod: Dictionary = {}

static func _ensure() -> void:
	if _profiles.is_empty():
		var p: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
		_profiles = p.get("profiles",{}) if p is Dictionary else {}
		var c: Variant = JSON.parse_string(FileAccess.get_file_as_string(PALETTE_PATH))
		_palettes = c.get("palettes",{}) if c is Dictionary else {}
		var l: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOD_PATH))
		_lod = l.get("tiers",{}) if l is Dictionary else {}

static func profile(id: String) -> Dictionary:
	_ensure()
	return _profiles.get(id,{}).duplicate(true)

static func palette(id: String) -> Dictionary:
	_ensure()
	var p: Dictionary = _profiles.get(id,{})
	return _palettes.get(str(p.get("palette","")),{}).duplicate(true)

static func quality(tree: SceneTree) -> Dictionary:
	_ensure()
	var id := str(tree.root.get_meta("quality_tier","high")) if tree != null else "high"
	return _lod.get(id,_lod.get("high",{})).duplicate(true)

static func apply_visual_only(root: Node3D, id: String, user_replacement: bool) -> void:
	if root == null: return
	_ensure()
	var p: Dictionary = _profiles.get(id,{})
	if p.is_empty(): return
	# Never distort a user's final GLB: differentiation scale is fallback-only.
	if not user_replacement:
		var values: Array = p.get("scale",[1,1,1])
		if values.size() == 3:
			root.scale *= Vector3(float(values[0]),float(values[1]),float(values[2]))
	var lod_bias := float(p.get("lod_bias",1.0))
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		(mesh as MeshInstance3D).lod_bias = lod_bias
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.set_meta("m66_visual_profile",id)
	root.set_meta("m66_palette",str(p.get("palette","")))
