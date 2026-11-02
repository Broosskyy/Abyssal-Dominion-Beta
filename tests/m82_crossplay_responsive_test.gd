extends Node
func _ready()->void:
	var crossplay:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m82_crossplay_intent_contract.json"))
	var responsive:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m82_responsive_acceptance.json"))
	var cadence:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m82_pl1_5_encounter_cadence.json"))
	var production:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m82_asset_production_wave.json"))
	assert(crossplay.status=="ARCHITECTURE_READY_NO_NETWORK_TRANSPORT")
	assert(GameplayIntentContract.is_gameplay("fire"))
	assert(not GameplayIntentContract.is_gameplay("camera_zoom"))
	assert(responsive.targets.size()>=7)
	assert(bool(cadence.levels["3"].monster))
	assert(not bool(cadence.levels["1"].elite))
	assert(production.master_first_13.size()==13)
	print("M82_CROSSPLAY_RESPONSIVE_PASS")
