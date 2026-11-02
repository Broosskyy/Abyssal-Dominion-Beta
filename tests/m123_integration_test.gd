extends Node
func _ready()->void:
	assert(SectorGraph.validate_progression_path(1,45).is_empty())
	assert(RuntimeQualityBudget.max_npcs()>0)
	var trial:=PirateTrialRuntime.new()
	var d:=trial.data()
	assert((d.get("trials",{}) as Dictionary).has("40"))
	assert((d.get("trials",{}) as Dictionary).has("45"))
	var prep:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m123_pl46_50_preproduction.json"))
	assert(prep.get("status","")=="slots_only_no_unlock")
	print("M123_INTEGRATION_PASS")
