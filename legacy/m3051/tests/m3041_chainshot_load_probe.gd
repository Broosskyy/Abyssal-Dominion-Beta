extends SceneTree
## Identify the FIRST failing class in the complete Godot inheritance chain.
func _initialize() -> void:
	var scripts: Array[String] = [
		"m3035_render_adapter",
		"m3035_seabattles_core",
		"m3036_unified_sea_map",
		"m3037_combat_sea_map",
		"m3038_visual_combat_sea_map",
		"m3039_world_ship_pass",
		"m304_shipyard_hud",
		"m3041_chainshot_combat",
		"m3042_navigation_hud_stability"
	]
	for filename in scripts:
		var path := "res://scripts/classic/" + filename + ".gd"
		var script := load(path) as GDScript
		print("SCRIPT_PROBE ", filename, " loaded=", script != null,
			" valid=", script != null,
			" can_instance=", script != null and script.can_instantiate())
	quit(0)
