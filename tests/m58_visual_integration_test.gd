extends Node
func _ready() -> void:
	var p := JSON.parse_string(FileAccess.get_file_as_string("res://data/m58_asset_import_profiles.json"))
	var c := JSON.parse_string(FileAccess.get_file_as_string("res://data/m58_visual_integration_contract.json"))
	assert(p.profiles.size() == 13)
	assert(p.profiles.has("ship_small"))
	assert(p.profiles.ship_small.coordinate_contract.forward == "+Z")
	assert(p.profiles.ship_small.coordinate_contract.no_embedded_water == true)
	assert(c.features.fallback_preserved == true)
	assert(c.features.visual_only_override == true)
	print("M58_VISUAL_INTEGRATION_PASS")
