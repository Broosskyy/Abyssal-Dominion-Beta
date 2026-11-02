extends Node
func _ready() -> void:
	var a := JSON.parse_string(FileAccess.get_file_as_string("res://data/m65_p0_ship_acceptance.json"))
	var s := JSON.parse_string(FileAccess.get_file_as_string("res://data/m65_ship_socket_contract.json"))
	assert(a.ships.size() == 8)
	assert(s.required.size() == 6)
	for id in ["ship_small","ship_medium","ship_large","npc_friendly_coastal_sloop","npc_scout_01","npc_raider_01","npc_gunship_01","npc_heavy_01"]:
		assert(ShipAssetAcceptance.is_p0_ship(id))
	print("M65_P0_SHIP_ACCEPTANCE_PASS")
