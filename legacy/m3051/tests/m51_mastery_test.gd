extends Node
func _ready() -> void:
	var mastery := JSON.parse_string(FileAccess.get_file_as_string("res://data/ship_mastery.json"))
	var contract := JSON.parse_string(FileAccess.get_file_as_string("res://data/m51_mastery_contract.json"))
	assert(mastery.max_level == 10)
	assert(mastery.rules.main_progression_designs == 50)
	assert(contract.production.ship_card_slots == 53)
	assert(ShipMasteryCatalog.xp_to_next(1) == 150)
	assert(ShipMasteryCatalog.xp_to_next(9) == 1350)
	assert(ShipMasteryCatalog.xp_to_next(10) == 0)
	print("M51_MASTERY_CONTRACT_PASS")
