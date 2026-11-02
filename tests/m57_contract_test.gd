extends Node
func _ready() -> void:
	var c := JSON.parse_string(FileAccess.get_file_as_string("res://data/m57_combat_contribution_contract.json"))
	var p := JSON.parse_string(FileAccess.get_file_as_string("res://data/m57_asset_production_kickoff.json"))
	assert(c.categories.size() == 7)
	assert(c.balance_status == "TBD_AFTER_PLAYTESTS")
	assert(p.wave_a.size() == 13)
	assert(p.first_glb == "ship_small")
	assert(p.glb_contract.water_in_glb == false)
	print("M57_CONTRACT_PASS")
