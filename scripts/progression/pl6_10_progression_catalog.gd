class_name Pl6To10ProgressionCatalog
extends RefCounted
const PATH:="res://data/m109_pl6_10_progression.json"
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():
		var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));_data=v if v is Dictionary else {}
	return _data
static func level(level:int)->Dictionary:
	return ProgressionBandOverlay.apply(level,((data().get("levels",{}) as Dictionary).get(str(level),{}) as Dictionary).duplicate(true))
static func mastery_xp(level:int,admiral:bool,elite:bool)->int:
	var row:=level(level)
	var base:=int(row.get("mastery_xp_per_sink",0))
	return roundi(base*(2.5 if admiral else (1.5 if elite else 1.0)))
static func map_xp_goal(level:int)->int:return int(level(level).get("map_xp_goal",0))
static func requires_trial(level:int)->bool:return bool(level(level).get("trial",false))
