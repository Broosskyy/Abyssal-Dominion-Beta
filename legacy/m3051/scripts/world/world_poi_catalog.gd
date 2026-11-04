class_name WorldPoiCatalog
extends RefCounted
const PATH := "res://data/m72_poi_catalog.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {"types":{},"pl1_5_mix":{}}
	return _data

static func definition(kind: String) -> Dictionary:
	return (data().get("types",{}) as Dictionary).get(kind,{})

static func level_mix(level: int) -> Array:
	return (data().get("pl1_5_mix",{}) as Dictionary).get(str(clampi(level,1,5)),["navigation","salvage"])
