extends Node
func _ready()->void:
	assert(Pl16To20ProgressionCatalog.data().get("levels",{}).size()==5)
	assert(Pl16To20ProgressionCatalog.requires_trial(20))
	var p:=PostBeginnerProgress.new()
	p.add_map_xp(20,999999);p.record_boss_clear(20)
	assert(not p.trial_ready(20))
	for i in range(Pl16To20ProgressionCatalog.hunter_required(20)):p.record_hunter(20)
	for i in range(Pl16To20ProgressionCatalog.region_required(20)):p.record_region_objective(20)
	assert(p.trial_ready(20));assert(not p.level_complete(20))
	assert(p.claim_trial(20));assert(p.level_complete(20))
	print("M111_PL16_20_PROGRESSION_PASS")
