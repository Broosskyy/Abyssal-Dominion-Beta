class_name Pl26To30ProgressionCatalog
extends RefCounted
const PATH:="res://data/m115_pl26_30_progression.json"
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():
		var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));_data=v if v is Dictionary else {}
	return _data
static func level(v:int)->Dictionary:return ProgressionBandOverlay.apply(v,((data().get("levels",{}) as Dictionary).get(str(v),{}) as Dictionary).duplicate(true))
static func map_xp_goal(v:int)->int:return int(level(v).get("map_xp_goal",0))
static func mastery_xp(v:int,admiral:bool,elite:bool)->int:
	var b:=int(level(v).get("mastery_xp_per_sink",0));return roundi(b*(2.5 if admiral else (1.5 if elite else 1.0)))
static func hunter_required(v:int)->int:return int(level(v).get("hunter_required",0))
static func region_required(v:int)->int:return int(level(v).get("region_objectives",0))
static func corruption_required(v:int)->int:return int(level(v).get("corruption_objectives",0))
static func requires_trial(v:int)->bool:return bool(level(v).get("pirate_trial",false))
