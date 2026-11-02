class_name P0VisualPolish
extends RefCounted

const PATH := "res://data/m146_visual_polish_profiles.json"
const P0_RUNTIME_IDS := ["ship_small","ship_medium","ship_large","npc_friendly_coastal_sloop","npc_scout_01","npc_raider_01","npc_gunship_01","npc_heavy_01","harbor_havens_reach","island_tropical_small","island_tropical_medium","island_cliff_cove","island_sandbar_long","monster_early_01"]
static var config: Dictionary = {}

static func apply(visual: Node3D, id: String, compact: bool, user_replacement: bool) -> void:
	if visual == null or id not in P0_RUNTIME_IDS: return
	_ensure()
	var profile_id := "web_preview" if OS.has_feature("web") else ("mobile" if compact else "desktop")
	var profile: Dictionary = config.get(profile_id, {})
	var lod_cap := float(profile.get("lod_bias_cap", 1.0))
	var visibility_end := float(profile.get("visibility_end", 0.0))
	var shadows := bool(profile.get("cast_shadows", true))
	for child in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		mesh.lod_bias = minf(mesh.lod_bias, lod_cap)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if visibility_end > 0.0:
			mesh.visibility_range_end = visibility_end
			mesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	visual.set_meta("m146_visual_polish", profile_id)
	visual.set_meta("m146_user_replacement", user_replacement)
	visual.set_meta("m146_gameplay_geometry_untouched", true)
	visual.set_meta("m146_vfx_density", float(profile.get("vfx_density", 1.0)))

static func _ensure() -> void:
	if not config.is_empty(): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	config = parsed if parsed is Dictionary else {}
