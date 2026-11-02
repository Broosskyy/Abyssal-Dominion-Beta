extends Node
func _ready() -> void:
	var contract := JSON.parse_string(FileAccess.get_file_as_string("res://data/m53_shipyard_ux_contract.json"))
	var reward_hooks := JSON.parse_string(FileAccess.get_file_as_string("res://data/mastery_reward_hooks.json"))
	assert(contract.shipyard_ux.responsive_portrait_single_column == true)
	assert(contract.shipyard_ux.responsive_landscape_two_column == true)
	assert(contract.shipyard_ux.stat_bars == 5)
	assert(contract.mastery_hooks.economy_rewards_invented == false)
	assert(reward_hooks.authority == "presentation_hooks_only")
	assert(MasteryRewardHooks.presentation_for(10).reward_bound == false)
	print("M53_SHIPYARD_UX_CONTRACT_PASS")
