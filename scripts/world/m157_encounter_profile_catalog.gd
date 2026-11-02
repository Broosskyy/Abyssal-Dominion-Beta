class_name M157EncounterProfileCatalog
extends RefCounted
const PATH:="res://data/m157_pl51_60_encounter_profiles.json"
static func data()->Dictionary:
	if not FileAccess.file_exists(PATH):return {}
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}
static func level(level_id:int)->Dictionary:
	return (data().get("levels",{}).get(str(level_id),{}) as Dictionary).duplicate(true)
static func drop_profile(level_id:int)->Dictionary:
	var row:=level(level_id)
	return (data().get("drop_profiles",{}).get(str(row.get("loot_profile","")),{}) as Dictionary).duplicate(true)
static func signature(level_id:int)->String:return str(level(level_id).get("signature_mechanic",""))
static func admiral_title(level_id:int,fallback:String)->String:return str(level(level_id).get("admiral_title",fallback))
