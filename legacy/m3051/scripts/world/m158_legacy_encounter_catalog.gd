class_name M158LegacyEncounterCatalog
extends RefCounted

const DATA_PATH := "res://data/m158_legacy_encounter_refresh.json"

static func _data()->Dictionary:
	if not FileAccess.file_exists(DATA_PATH): return {}
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return parsed if parsed is Dictionary else {}

static func band(level:int)->Dictionary:
	for row in _data().get("bands",[]):
		if level>=int(row.get("min_level",999)) and level<=int(row.get("max_level",-1)):
			return (row as Dictionary).duplicate(true)
	return {}

static func phase_profile(level:int)->Dictionary:
	var row:=band(level)
	var key:=str(row.get("phase_profile",""))
	var profiles:Dictionary=_data().get("phase_profiles",{})
	return (profiles.get(key,{}) as Dictionary).duplicate(true)

static func identity(level:int)->String:
	return str(band(level).get("identity",""))

static func loot_profile(level:int)->String:
	return str(band(level).get("loot_profile",""))

static func boss_title(level:int,fallback:String)->String:
	var titles:Array=band(level).get("boss_titles",[])
	if titles.is_empty(): return fallback
	return str(titles[posmod(level,titles.size())])

static func phase_profile_by_id(id:String)->Dictionary:
	var profiles:Dictionary=_data().get("phase_profiles",{})
	return (profiles.get(id,{}) as Dictionary).duplicate(true)
