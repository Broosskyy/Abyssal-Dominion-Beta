class_name RuntimeQualityBudget
extends RefCounted
const PATH:="res://data/m123_runtime_quality_profiles.json"
static func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return v if v is Dictionary else {}
static func profile_name()->String:
	if OS.has_feature("mobile"):
		var size:=DisplayServer.window_get_size()
		return "mobile_low" if mini(size.x,size.y)<800 else "mobile_high"
	return "desktop"
static func current()->Dictionary:
	# M194: gameplay/simulation budgets are canonical and never platform-dependent.
	return data().get("profiles",{}).get("desktop",{})
static func max_npcs()->int:return int(current().get("max_npcs",10))
static func max_major_vfx()->int:return int(current().get("max_major_vfx",2))
static func simulation_distance()->float:return float(current().get("simulation_distance",70.0))
