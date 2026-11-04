class_name Pl11To15ProgressionCatalog
extends RefCounted
const PATH:="res://data/m110_pl11_15_progression.json"
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():
		var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));_data=v if v is Dictionary else {}
	return _data
static func level(level_value:int)->Dictionary:
	return ProgressionBandOverlay.apply(level_value,((data().get("levels",{}) as Dictionary).get(str(level_value),{}) as Dictionary).duplicate(true))
static func map_xp_goal(level_value:int)->int:return int(level(level_value).get("map_xp_goal",0))
static func mastery_xp(level_value:int,admiral:bool,elite:bool)->int:
	var base:=int(level(level_value).get("mastery_xp_per_sink",0))
	return roundi(base*(2.5 if admiral else (1.5 if elite else 1.0)))
static func hunter_required(level_value:int)->int:return int(level(level_value).get("hunter_required",0))
static func region_required(level_value:int)->int:return int(level(level_value).get("region_objectives",0))
static func requires_trial(level_value:int)->bool:return bool(level(level_value).get("pirate_trial",false))
