extends Node
func _ready()->void:
	assert(Pl11To15ProgressionCatalog.data().levels.size()==5)
	assert(Pl11To15ProgressionCatalog.requires_trial(15))
	var p:=PostBeginnerProgress.new()
	p.add_map_xp(15,999999);p.record_boss_clear(15)
	assert(not p.trial_ready(15))
	p.record_hunter(15)
	for i in range(Pl11To15ProgressionCatalog.region_required(15)):p.record_region_objective(15)
	assert(p.trial_ready(15));assert(not p.level_complete(15));assert(p.claim_trial(15));assert(p.level_complete(15))
	assert(Pl11To15ProgressionCatalog.mastery_xp(12,true,false)>Pl11To15ProgressionCatalog.mastery_xp(12,false,false))
	print("M110_PL11_15_PROGRESSION_PASS")
