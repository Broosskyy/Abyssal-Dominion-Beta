extends Node
func _ready()->void:
	var data:=Pl6To10ProgressionCatalog.data()
	assert(data.levels.size()==5)
	assert(Pl6To10ProgressionCatalog.requires_trial(10))
	assert(str(Pl6To10ProgressionCatalog.level(6).ship_reward)=="ship_main_01")
	assert(str(Pl6To10ProgressionCatalog.level(8).ship_reward)=="ship_main_02")
	assert(str(Pl6To10ProgressionCatalog.level(10).ship_reward)=="ship_main_03")
	assert(Pl6To10ProgressionCatalog.mastery_xp(6,true,false)>Pl6To10ProgressionCatalog.mastery_xp(6,false,false))
	var p:=PostBeginnerProgress.new()
	p.add_map_xp(6,999999);p.record_boss_clear(6);assert(p.level_complete(6))
	p.add_map_xp(10,999999);p.record_boss_clear(10);assert(p.trial_ready(10));assert(not p.level_complete(10));assert(p.claim_trial(10));assert(p.level_complete(10))
	print("M109_PL6_10_PROGRESSION_PASS")
