extends Node
func _ready()->void:
	var audit:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m97_core_world_event_polish_audit.json"))
	assert(int(audit.core_world.irregular_island_slots_wired)==2)
	assert(not bool(audit.core_world.harbor_object_count_increased))
	assert(int(audit.core_world.wreck_object_count)==3)
	assert(bool(audit.halloween.compact_quest_strip))
	assert(bool(audit.halloween.quest_reward_double_guard))
	assert(not bool(audit.halloween.live_reward_authority))
	assert(bool(audit.admin.category_filter))
	assert(not bool(audit.admin.production_authority))
	var slots:=JSON.parse_string(FileAccess.get_file_as_string("res://data/visual_slots.json"))
	for id in ["nature_island_cliff_bridge_01","nature_island_sharp_reef_01","prop_harbor_pirate_sign_01","prop_harbor_rope_gantry_01","prop_wreck_half_mast_01","npc_pirate_sail_patch_01"]:
		assert(str(slots.models[id].status)=="active")
	var harbor:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m71_havens_reach_composition.json"))
	assert(harbor.modules.size()==30)
	var prod:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m97_asset_production_wave.json"))
	assert(prod.master_first_13.size()==13)
	print("M97_CORE_WORLD_EVENT_POLISH_PASS")
