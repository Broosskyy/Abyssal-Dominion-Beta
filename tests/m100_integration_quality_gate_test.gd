extends Node
func _ready()->void:
	var a:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m100_integration_quality_gate.json"))
	assert(bool(a.regressions_corrected.npc_hull_hidden_at_shadow_distance))
	assert(bool(a.regressions_corrected.nameplate_quality_distance_wired))
	assert(bool(a.regressions_corrected.selected_target_exception))
	assert(int(a.permanent_world.island_hero_cap)==1)
	assert(not bool(a.permanent_world.harbor_module_count_increased))
	assert(bool(a.guild.objective_visual_only))
	assert(not bool(a.guild.capture_authority))
	assert(not bool(a.guild.persistent_state))
	var slots:=JSON.parse_string(FileAccess.get_file_as_string("res://data/visual_slots.json"))
	for id in ["nature_island_small_cliff_01","nature_island_long_hook_01","nature_island_split_rock_01","prop_harbor_pirate_lantern_02","prop_harbor_skull_sign_01","guild_shield_core_01","guild_shield_node_01"]:
		assert(str(slots.models[id].status)=="active")
	var harbor:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m71_havens_reach_composition.json"))
	assert(harbor.modules.size()==30)
	print("M100_INTEGRATION_QUALITY_GATE_PASS")
