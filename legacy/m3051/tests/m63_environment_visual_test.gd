extends Node
func _ready() -> void:
	var c := JSON.parse_string(FileAccess.get_file_as_string("res://data/m63_environment_visual_contract.json"))
	var b := JSON.parse_string(FileAccess.get_file_as_string("res://data/m63_world_visual_budgets.json"))
	assert(c.ship_water_fx.wake_slot == "vfx_ship_wake")
	assert(b.tiers.low.water_subdivisions < b.tiers.high.water_subdivisions)
	for id in ["vfx_ship_wake","vfx_bow_foam","vfx_shoreline_foam","vfx_shallow_water_edge","vfx_water_impact","vfx_hull_impact","vfx_safe_zone_ring","vfx_safe_zone_beacon"]:
		assert(not VisualAssetCatalog.info("vfx",id).is_empty())
	print("M63_ENVIRONMENT_VISUAL_PASS")
