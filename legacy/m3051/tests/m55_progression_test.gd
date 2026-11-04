extends Node
func _ready() -> void:
	var contract := JSON.parse_string(FileAccess.get_file_as_string("res://data/m55_progression_contract.json"))
	var rewards := JSON.parse_string(FileAccess.get_file_as_string("res://data/pl6_15_ship_rewards.json"))
	assert(contract.progression.map_level_auto_ownership_removed == true)
	assert(contract.progression.eligibility_separate_from_ownership == true)
	assert(rewards.boss_rewards.size() == 5)
	assert(MainShipRewardCatalog.reward_ship_for_boss(6) == "ship_main_01")
	assert(MainShipRewardCatalog.reward_ship_for_boss(14) == "ship_main_05")
	assert(MainProgressionFleet.is_eligible("ship_main_01",6))
	assert(not MainProgressionFleet.is_eligible("ship_main_02",6))
	print("M55_PROGRESSION_CONTRACT_PASS")
