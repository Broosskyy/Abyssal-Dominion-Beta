class_name Pl46To50ProgressionCatalog
extends RefCounted
const PATH:="res://data/m124_pl46_50_progression.json"
static func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return v if v is Dictionary else {}
static func level(level_id:int)->Dictionary:return ProgressionBandOverlay.apply(level_id,data().get("levels",{}).get(str(level_id),{}))
static func map_xp_goal(level_id:int)->int:return int(level(level_id).get("map_xp",0))
static func region_required(level_id:int)->int:return int(level(level_id).get("region_objectives",0))
static func hunter_required(level_id:int)->int:return int(level(level_id).get("hunter",0))
static func legendary_required(level_id:int)->int:return int(level(level_id).get("legendary_chain",0))
static func top_material_required(level_id:int)->int:return int(level(level_id).get("top_materials",0))
static func requires_trial(level_id:int)->bool:return bool(level(level_id).get("trial",false))
static func mastery_xp(level_id:int,admiral:bool,elite:bool)->int:
	var base:=maxi(10,level_id*2)
	return base*4 if admiral else (base*2 if elite else base)
