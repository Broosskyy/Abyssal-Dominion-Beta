class_name M158HalloweenCatalog
extends RefCounted

const DATA_PATH := "res://data/m158_halloween_gameplay.json"

static func _data()->Dictionary:
	if not FileAccess.file_exists(DATA_PATH): return {}
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return parsed if parsed is Dictionary else {}

static func phase(id:int)->Dictionary:
	for row in _data().get("phase_extensions",[]):
		if int(row.get("id",0))==id:return (row as Dictionary).duplicate(true)
	return {}

static func quests()->Array:return _data().get("quests",[])
static func shop()->Array:return _data().get("shop_extensions",[])
static func phase4_fleet()->Array:return _data().get("phase4_fleet",[])
