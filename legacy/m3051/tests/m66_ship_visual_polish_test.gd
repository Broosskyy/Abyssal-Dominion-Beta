extends Node
func _ready() -> void:
	var p := JSON.parse_string(FileAccess.get_file_as_string("res://data/m66_p0_ship_visual_profiles.json"))
	var l := JSON.parse_string(FileAccess.get_file_as_string("res://data/m66_ship_lod_contract.json"))
	assert(p.profiles.size() == 8)
	assert(l.tiers.low.mesh_lod_threshold > l.tiers.high.mesh_lod_threshold)
	for id in p.profiles:
		assert(not ShipVisualProfileCatalog.profile(str(id)).is_empty())
	print("M66_SHIP_VISUAL_POLISH_PASS")
