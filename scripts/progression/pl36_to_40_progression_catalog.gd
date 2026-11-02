class_name Pl36To40ProgressionCatalog
extends RefCounted
const PATH:="res://data/m121_pl36_40_progression.json"
static func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return v if v is Dictionary else {}
static func level(level_id:int)->Dictionary:return ProgressionBandOverlay.apply(level_id,data().get("levels",{}).get(str(level_id),{}))
static func map_xp_goal(level_id:int)->int:return int(level(level_id).get("map_xp_goal",1))
static func region_required(level_id:int)->int:return int(level(level_id).get("region_objectives",0))
static func hunter_required(level_id:int)->int:return int(level(level_id).get("hunter_required",0))
static func requires_trial(level_id:int)->bool:return bool(level(level_id).get("requires_trial",false))
static func mastery_xp(level_id:int,boss:bool,elite:bool)->int:
	var row:Dictionary=level(level_id).get("mastery_xp",{})
	return int(row.get("boss" if boss else ("elite" if elite else "normal"),0))
