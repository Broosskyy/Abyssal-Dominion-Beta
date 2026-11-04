extends Node
func _ready()->void:
	assert(SectorGraph.validate_progression_path(1,50).is_empty())
	for level in range(46,51):assert(Pl46To50ProgressionCatalog.map_xp_goal(level)>0)
	assert(Pl46To50ProgressionCatalog.requires_trial(50))
	var trial:=PirateTrialRuntime.new()
	assert(trial.stages(50).size()>=5)
	print("M124_FINAL_BAND_PASS")
