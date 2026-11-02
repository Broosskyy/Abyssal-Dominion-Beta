extends Node
func _ready() -> void:
	var harbor := JSON.parse_string(FileAccess.get_file_as_string("res://data/regional_harbor_economy.json"))
	var contract := JSON.parse_string(FileAccess.get_file_as_string("res://data/m48_runtime_contract.json"))
	assert(harbor.harbors.size() == 3)
	assert(harbor.materials.size() == 5)
	assert(EquipmentEconomyContracts.recipe("barbed_payload_batch").size() > 0)
	assert(RegionalHarborEconomy.region_for_level(6) == "stormreach")
	assert(RegionalHarborEconomy.region_for_level(10) == "ember_shoals")
	assert(RegionalHarborEconomy.region_for_level(14) == "veil_sea")
	assert(contract.runtime.support_ally_prototype == true)
	print("M48_RUNTIME_CONTRACT_PASS")
