class_name M158BonusMapBossCatalog
extends RefCounted

const DATA_PATH := "res://data/m158_bonusmap_boss_mechanics.json"

static func _data()->Dictionary:
	if not FileAccess.file_exists(DATA_PATH): return {}
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return parsed if parsed is Dictionary else {}

static func row(map_id:String)->Dictionary:
	return (_data().get("maps",{}).get(map_id,{}) as Dictionary).duplicate(true)

static func summary(map_id:String)->String:
	var value:=row(map_id)
	if value.is_empty(): return ""
	return "%s · W%d · %s"%[str(value.get("boss","Boss")),int(value.get("boss_wave",0)),", ".join(value.get("mechanics",[]))]
