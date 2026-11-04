extends Node
func _ready() -> void:
	var fleet := JSON.parse_string(FileAccess.get_file_as_string("res://data/main_progression_fleet.json"))
	var regions := JSON.parse_string(FileAccess.get_file_as_string("res://data/pl6_15_regions.json"))
	var payloads := JSON.parse_string(FileAccess.get_file_as_string("res://data/support_payloads.json"))
	var qa := JSON.parse_string(FileAccess.get_file_as_string("res://data/production_qa_scenes.json"))
	assert(fleet.designs.size() == 50)
	assert(fleet.designs[0].ship_mastery_levels == 10)
	assert(regions.regions.size() == 3)
	assert(payloads.harpoon_payloads.size() == 3)
	assert(payloads.support_ammo.size() == 3)
	assert(qa.scenes.size() == 5)
	assert(ShipCatalog.has_ship("ship_main_01"))
	print("M46_RUNTIME_CONTRACT_PASS")
