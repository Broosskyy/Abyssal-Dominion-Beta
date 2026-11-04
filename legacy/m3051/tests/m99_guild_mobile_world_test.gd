extends Node
func _ready()->void:
	var ux:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m99_guild_mobile_world_ux.json"))
	assert(int(ux.minimum_map_level)==2)
	assert(bool(ux.input.touch_detail_row_focus))
	assert(bool(ux.input.mouse_detail_row_focus))
	assert(str(ux.input.gamepad_cycle).contains("ship_previous"))
	assert(not bool(ux.fortifications.collision_authority))
	assert(not bool(ux.fortifications.permanent_destruction))
	var slots:=JSON.parse_string(FileAccess.get_file_as_string("res://data/visual_slots.json"))
	for id in ["m99_guild_dock","m99_guild_facilities","m99_guild_range","m99_guild_defense","m99_guild_hall","m99_guild_focus"]:
		assert(slots.ui.has(id))
	for id in ["guild_wall_straight_01","guild_wall_corner_01","guild_wall_gate_01","guild_watch_platform_01"]:
		assert(slots.models.has(id))
	var prod:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m99_asset_production_wave.json"))
	assert(prod.master_first_13.size()==13)
	print("M99_GUILD_MOBILE_WORLD_PASS")
