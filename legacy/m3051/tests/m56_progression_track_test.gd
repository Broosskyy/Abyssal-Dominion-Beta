extends Node
func _ready() -> void:
	var contract := JSON.parse_string(FileAccess.get_file_as_string("res://data/m56_progression_track_contract.json"))
	var rewards := JSON.parse_string(FileAccess.get_file_as_string("res://data/pl6_15_ship_rewards.json"))
	assert(contract.progression_track.mobile_panel == true)
	assert(contract.progression_track.eligibility_separate == true)
	assert(contract.reward_history.persisted_in_ship_roster == true)
	assert(contract.reward_history.server_audit_claimed == false)
	assert(rewards.boss_rewards.size() == 5)
	print("M56_PROGRESSION_TRACK_CONTRACT_PASS")
