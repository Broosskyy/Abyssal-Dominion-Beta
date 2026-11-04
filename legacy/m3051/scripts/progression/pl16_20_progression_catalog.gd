class_name Pl16To20ProgressionCatalog
extends RefCounted
const PATH:="res://data/m111_pl16_20_progression.json"
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {}
	return _data
static func level(value:int)->Dictionary:
	return ProgressionBandOverlay.apply(value,((data().get("levels",{}) as Dictionary).get(str(value),{}) as Dictionary).duplicate(true))
static func map_xp_goal(value:int)->int:return int(level(value).get("map_xp_goal",0))
static func mastery_xp(value:int,admiral:bool,elite:bool)->int:
	var base:=int(level(value).get("mastery_xp_per_sink",0))
	return roundi(base*(2.5 if admiral else (1.5 if elite else 1.0)))
static func hunter_required(value:int)->int:return int(level(value).get("hunter_required",0))
static func region_required(value:int)->int:return int(level(value).get("region_objectives",0))
static func requires_trial(value:int)->bool:return bool(level(value).get("pirate_trial",false))
