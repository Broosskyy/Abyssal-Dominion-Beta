class_name MonsterVisualProfileCatalog
extends RefCounted
const PROFILE_PATH := "res://data/m68_monster_visual_profiles.json"
const BUDGET_PATH := "res://data/m68_monster_visual_budgets.json"
static var _profiles: Dictionary = {}
static var _budgets: Dictionary = {}

static func _ensure() -> void:
	if not _profiles.is_empty(): return
	var p: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
	_profiles = p.get("profiles",{}) if p is Dictionary else {}
	var b: Variant = JSON.parse_string(FileAccess.get_file_as_string(BUDGET_PATH))
	_budgets = b.get("tiers",{}) if b is Dictionary else {}

static func profile(id: String) -> Dictionary:
	_ensure()
	return _profiles.get(id,{}).duplicate(true)

static func budget(tree: SceneTree) -> Dictionary:
	_ensure()
	var tier := str(tree.root.get_meta("quality_tier","high")) if tree != null else "high"
	return _budgets.get(tier,_budgets.get("high",{})).duplicate(true)

static func apply_visual_only(root: Node3D, id: String, user_replacement: bool) -> void:
	var p := profile(id)
	if root == null or p.is_empty(): return
	if not user_replacement:
		var a: Array = p.get("fallback_scale",[1,1,1])
		if a.size() == 3: root.scale *= Vector3(float(a[0]),float(a[1]),float(a[2]))
		root.rotation.y += deg_to_rad(float(p.get("rotation_y_deg",0)))
	var q := budget(root.get_tree())
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		(mesh as MeshInstance3D).lod_bias = float(q.get("monster_lod_bias",0.94))
	root.set_meta("m68_monster_profile",id)
