class_name PostBeginnerProgress
extends Node
signal changed
var map_xp:Dictionary={}
var boss_clears:Dictionary={}
var hunter_clears:Dictionary={}
var region_objectives:Dictionary={}
var trial_clears:Dictionary={}
var status_objectives:Dictionary={}
var build_objectives:Dictionary={}
var corruption_objectives:Dictionary={}
var guardian_fragments:Dictionary={}
var void_elite_chains:Dictionary={}
var sovereign_prestige:Dictionary={}
var legendary_chains:Dictionary={}
var top_material_objectives:Dictionary={}
var w5_elite_chains:Dictionary={}
var dominion_shard_objectives:Dictionary={}
func _goal(level:int)->int:
	if level<=10:return Pl6To10ProgressionCatalog.map_xp_goal(level)
	if level<=15:return Pl11To15ProgressionCatalog.map_xp_goal(level)
	if level<=20:return Pl16To20ProgressionCatalog.map_xp_goal(level)
	if level<=25:return Pl21To25ProgressionCatalog.map_xp_goal(level)
	if level<=30:return Pl26To30ProgressionCatalog.map_xp_goal(level)
	if level<=35:return Pl31To35ProgressionCatalog.map_xp_goal(level)
	if level<=40:return Pl36To40ProgressionCatalog.map_xp_goal(level)
	if level<=45:return Pl41To45ProgressionCatalog.map_xp_goal(level)
	if level<=50:return Pl46To50ProgressionCatalog.map_xp_goal(level)
	return Pl51To60ProgressionCatalog.map_xp_goal(level)
func _trial(level:int)->bool:
	if level<=10:return Pl6To10ProgressionCatalog.requires_trial(level)
	if level<=15:return Pl11To15ProgressionCatalog.requires_trial(level)
	if level<=20:return Pl16To20ProgressionCatalog.requires_trial(level)
	if level<=25:return Pl21To25ProgressionCatalog.requires_trial(level)
	if level<=30:return Pl26To30ProgressionCatalog.requires_trial(level)
	if level<=35:return Pl31To35ProgressionCatalog.requires_trial(level)
	if level<=40:return Pl36To40ProgressionCatalog.requires_trial(level)
	if level<=45:return Pl41To45ProgressionCatalog.requires_trial(level)
	if level<=50:return Pl46To50ProgressionCatalog.requires_trial(level)
	return Pl51To60ProgressionCatalog.requires_trial(level)
func _hunter_goal(level:int)->int:
	if level<=10:return 0
	if level<=15:return Pl11To15ProgressionCatalog.hunter_required(level)
	if level<=20:return Pl16To20ProgressionCatalog.hunter_required(level)
	if level<=25:return Pl21To25ProgressionCatalog.hunter_required(level)
	if level<=30:return Pl26To30ProgressionCatalog.hunter_required(level)
	if level<=35:return Pl31To35ProgressionCatalog.hunter_required(level)
	if level<=40:return Pl36To40ProgressionCatalog.hunter_required(level)
	if level<=45:return Pl41To45ProgressionCatalog.hunter_required(level)
	if level<=50:return Pl46To50ProgressionCatalog.hunter_required(level)
	return Pl51To60ProgressionCatalog.hunter_required(level)
func _region_goal(level:int)->int:
	if level<=10:return 0
	if level<=15:return Pl11To15ProgressionCatalog.region_required(level)
	if level<=20:return Pl16To20ProgressionCatalog.region_required(level)
	if level<=25:return Pl21To25ProgressionCatalog.region_required(level)
	if level<=30:return Pl26To30ProgressionCatalog.region_required(level)
	if level<=35:return Pl31To35ProgressionCatalog.region_required(level)
	if level<=40:return Pl36To40ProgressionCatalog.region_required(level)
	if level<=45:return Pl41To45ProgressionCatalog.region_required(level)
	if level<=50:return Pl46To50ProgressionCatalog.region_required(level)
	return Pl51To60ProgressionCatalog.region_required(level)
func add_map_xp(level:int,amount:int)->void:
	if level<6 or level>60 or amount<=0:return
	map_xp[level]=mini(_goal(level),int(map_xp.get(level,0))+amount);changed.emit()
func record_boss_clear(level:int)->void:
	if level<6 or level>60:return
	boss_clears[level]=true;changed.emit()
func record_hunter(level:int)->void:
	if level<11 or level>60:return
	hunter_clears[level]=mini(_hunter_goal(level),int(hunter_clears.get(level,0))+1);changed.emit()
func record_region_objective(level:int)->void:
	if level<11 or level>60:return
	region_objectives[level]=mini(_region_goal(level),int(region_objectives.get(level,0))+1);changed.emit()
func xp_ready(level:int)->bool:return _goal(level)>0 and int(map_xp.get(level,0))>=_goal(level)
func objectives_ready(level:int)->bool:
	if int(hunter_clears.get(level,0))<_hunter_goal(level) or int(region_objectives.get(level,0))<_region_goal(level):return false
	if level>=21 and level<=25:
		if int(status_objectives.get(level,0))<Pl21To25ProgressionCatalog.status_required(level):return false
		if int(build_objectives.get(level,0))<Pl21To25ProgressionCatalog.build_required(level):return false
	if level>=26 and level<=30:
		if int(corruption_objectives.get(level,0))<Pl26To30ProgressionCatalog.corruption_required(level):return false
	if level>=31 and level<=35:
		if int(guardian_fragments.get(level,0))<Pl31To35ProgressionCatalog.fragment_required(level):return false
	if level>=36 and level<=40:
		if int(void_elite_chains.get(level,0))<2:return false
	if level>=41 and level<=45:
		if int(sovereign_prestige.get(level,0))<Pl41To45ProgressionCatalog.prestige_required(level):return false
	if level>=46 and level<=50 and (int(legendary_chains.get(level,0))<Pl46To50ProgressionCatalog.legendary_required(level) or int(top_material_objectives.get(level,0))<Pl46To50ProgressionCatalog.top_material_required(level)):return false
	if level>=51 and level<=60:
		if int(w5_elite_chains.get(level,0))<Pl51To60ProgressionCatalog.elite_chain_required(level):return false
		if int(dominion_shard_objectives.get(level,0))<Pl51To60ProgressionCatalog.shard_required(level):return false
	return true
func record_status_objective(level:int)->void:
	if level<21 or level>25:return
	status_objectives[level]=mini(Pl21To25ProgressionCatalog.status_required(level),int(status_objectives.get(level,0))+1);changed.emit()
func record_build_objective(level:int)->void:
	if level<21 or level>25:return
	build_objectives[level]=mini(Pl21To25ProgressionCatalog.build_required(level),int(build_objectives.get(level,0))+1);changed.emit()
func record_corruption_objective(level:int)->void:
	if level<26 or level>35:return
	corruption_objectives[level]=mini(Pl26To30ProgressionCatalog.corruption_required(level),int(corruption_objectives.get(level,0))+1);changed.emit()
func record_guardian_fragment(level:int,amount:int=1)->void:
	if level<31 or level>35 or amount<=0:return
	guardian_fragments[level]=mini(Pl31To35ProgressionCatalog.fragment_required(level),int(guardian_fragments.get(level,0))+amount);changed.emit()
func record_void_elite(level:int)->void:
	if level<36 or level>40:return
	void_elite_chains[level]=mini(2,int(void_elite_chains.get(level,0))+1)
	changed.emit()
func record_sovereign_prestige(level:int,amount:int=1)->void:
	if level<41 or level>50 or amount<=0:return
	sovereign_prestige[level]=mini(Pl41To45ProgressionCatalog.prestige_required(level),int(sovereign_prestige.get(level,0))+amount)
	changed.emit()
func record_legendary_chain(level:int,amount:int=1)->void:
	if level<46 or level>50 or amount<=0:return
	legendary_chains[level]=mini(Pl46To50ProgressionCatalog.legendary_required(level),int(legendary_chains.get(level,0))+amount);changed.emit()
func record_top_material(level:int,amount:int=1)->void:
	if level<46 or level>50 or amount<=0:return
	top_material_objectives[level]=mini(Pl46To50ProgressionCatalog.top_material_required(level),int(top_material_objectives.get(level,0))+amount);changed.emit()
func record_w5_elite_chain(level:int,amount:int=1)->void:
	if level<51 or level>60 or amount<=0:return
	w5_elite_chains[level]=mini(Pl51To60ProgressionCatalog.elite_chain_required(level),int(w5_elite_chains.get(level,0))+amount);changed.emit()
func record_dominion_shards(level:int,amount:int=1)->void:
	if level<51 or level>60 or amount<=0:return
	dominion_shard_objectives[level]=mini(Pl51To60ProgressionCatalog.shard_required(level),int(dominion_shard_objectives.get(level,0))+amount);changed.emit()
func trial_ready(level:int)->bool:
	return _trial(level) and xp_ready(level) and bool(boss_clears.get(level,false)) and objectives_ready(level)
func claim_trial(level:int)->bool:
	if not trial_ready(level):return false
	trial_clears[level]=true;changed.emit();return true
func level_complete(level:int)->bool:
	if not xp_ready(level) or not bool(boss_clears.get(level,false)) or not objectives_ready(level):return false
	return not _trial(level) or bool(trial_clears.get(level,false))
func next_level(current:int)->int:return mini(60,current+1) if level_complete(current) else current
func export_state()->Dictionary:
	return {"map_xp":map_xp.duplicate(true),"boss_clears":boss_clears.duplicate(true),
	"hunter_clears":hunter_clears.duplicate(true),"region_objectives":region_objectives.duplicate(true),
	 "trial_clears":trial_clears.duplicate(true),"status_objectives":status_objectives.duplicate(true),"build_objectives":build_objectives.duplicate(true),
	"corruption_objectives":corruption_objectives.duplicate(true),"guardian_fragments":guardian_fragments.duplicate(true),"void_elite_chains":void_elite_chains.duplicate(true),"sovereign_prestige":sovereign_prestige.duplicate(true),"legendary_chains":legendary_chains.duplicate(true),"top_material_objectives":top_material_objectives.duplicate(true),"w5_elite_chains":w5_elite_chains.duplicate(true),"dominion_shard_objectives":dominion_shard_objectives.duplicate(true)}
func import_state(data:Dictionary)->void:
	map_xp=(data.get("map_xp",{}) as Dictionary).duplicate(true)
	boss_clears=(data.get("boss_clears",{}) as Dictionary).duplicate(true)
	hunter_clears=(data.get("hunter_clears",{}) as Dictionary).duplicate(true)
	region_objectives=(data.get("region_objectives",{}) as Dictionary).duplicate(true)
	trial_clears=(data.get("trial_clears",{}) as Dictionary).duplicate(true)
	status_objectives=(data.get("status_objectives",{}) as Dictionary).duplicate(true)
	build_objectives=(data.get("build_objectives",{}) as Dictionary).duplicate(true)
	corruption_objectives=(data.get("corruption_objectives",{}) as Dictionary).duplicate(true)
	guardian_fragments=(data.get("guardian_fragments",{}) as Dictionary).duplicate(true)
	void_elite_chains=(data.get("void_elite_chains",{}) as Dictionary).duplicate(true)
	sovereign_prestige=(data.get("sovereign_prestige",{}) as Dictionary).duplicate(true)
	legendary_chains=(data.get("legendary_chains",{}) as Dictionary).duplicate(true)
	top_material_objectives=(data.get("top_material_objectives",{}) as Dictionary).duplicate(true)
	w5_elite_chains=(data.get("w5_elite_chains",{}) as Dictionary).duplicate(true)
	dominion_shard_objectives=(data.get("dominion_shard_objectives",{}) as Dictionary).duplicate(true)
	changed.emit()
