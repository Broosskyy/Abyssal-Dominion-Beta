extends Node
func _ready() -> void:
	var c := JSON.parse_string(FileAccess.get_file_as_string("res://data/m62_world_interaction_contract.json"))
	var h := JSON.parse_string(FileAccess.get_file_as_string("res://data/m62_havens_reach_services.json"))
	var d := JSON.parse_string(FileAccess.get_file_as_string("res://data/m62_world_marker_density.json"))
	assert(c.features.havens_reach_services == 5)
	assert(h.services.size() == 5)
	assert(d.rules.minimum_marker_px >= 24)
	for id in ["world_interact","world_safe_harbor","marker_quest","marker_objective","marker_loot","marker_repair","marker_monster","marker_elite","marker_admiral","service_shipyard","service_repair","service_market","service_arsenal","service_quests","minimap_player","minimap_port"]:
		assert(not VisualAssetCatalog.info("ui",id).is_empty())
	print("M62_WORLD_INTERACTION_PASS")
