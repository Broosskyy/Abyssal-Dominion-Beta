extends Node
func _ready()->void:
	var c:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m89_guild_island_map2_contract.json"))
	assert(int(c.minimum_map_level)==2)
	assert(c.early_island.interactions.size()>=6)
	assert(not bool(c.tower_contract.broadside_angle_damage))
	assert(not bool(c.tower_contract.damage_states_authoritative))
	var a:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m98_guild_island_depth_audit.json"))
	assert(a.map2_guild_island.actions.has("range_preview"))
	assert(a.visual_states.tower.has("disabled"))
	assert(not bool(a.visual_states.permanent_destruction))
	assert(not bool(a.backend_boundary.ownership))
	assert(not bool(a.backend_boundary.war))
	var slots:=JSON.parse_string(FileAccess.get_file_as_string("res://data/visual_slots.json"))
	for id in ["guild_tower_state_intact_01","guild_tower_state_damaged_01","guild_tower_state_disabled_01"]:
		assert(slots.models.has(id))
	print("M98_GUILD_ISLAND_DEPTH_PASS")
