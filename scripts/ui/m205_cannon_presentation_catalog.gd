class_name M205CannonPresentationCatalog
extends RefCounted
## Visual-only cannon presentation. Combat/upgrades remain sourced from existing data catalogs.
const VISIBLE_TRACK_STAGES := [1, 3, 5, 7, 10]

static func cannon_icon_slot(id:String)->String:
	return "ui_cannon_"+id

static func quality_tier_icon_slot(tier:int)->String:
	return "ui_cannon_tier_%d"%clampi(tier,1,5)

static func visible_stage_for_level(level:int)->int:
	var result:=1
	for stage in VISIBLE_TRACK_STAGES:
		if level>=stage:result=stage
	return result

static func track_icon_slot(track:String,level:int)->String:
	return "ui_cannon_track_%s_%d"%[track,visible_stage_for_level(level)]

static func track_stage_label(level:int)->String:
	var stage:=visible_stage_for_level(level)
	return "VISUELLE STUFE %d"%stage

static func quality_label(tier:int)->String:
	var rows:Array=CombatCatalog.m155_progression_data().get("upgrade_tiers",[])
	for row in rows:
		if row is Dictionary and int(row.get("tier",0))==tier:return str(row.get("label","Tier %d"%tier))
	return "Tier %d"%tier
