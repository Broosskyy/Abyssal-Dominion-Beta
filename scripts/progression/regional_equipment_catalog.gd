class_name RegionalEquipmentCatalog
extends RefCounted

const PATH := "res://data/regional_equipment_modules.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if not _data.is_empty(): return _data
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_data = parsed if parsed is Dictionary else {}
	return _data

static func module(id: String) -> Dictionary:
	var tree:=Engine.get_main_loop() as SceneTree
	if tree!=null:
		var dynamic:=DynamicContentResolver.by_id(tree,"equipment_module",id)
		if not dynamic.is_empty():return dynamic
	var value: Variant = data().get("modules", {}).get(id, {})
	return value.duplicate(true) if value is Dictionary else {}

static func ids_for_region(region_id: String) -> Array[String]:
	var result: Array[String] = []
	for id in data().get("modules",{}):
		if str(data().modules[id].get("region",""))==region_id:result.append(str(id))
	var tree:=Engine.get_main_loop() as SceneTree
	if tree!=null:
		for row in DynamicContentResolver.active_records(tree,"equipment_module"):
			if str(row.get("region",""))==region_id and str(row.get("id","")) not in result:result.append(str(row.get("id","")))
	return result

static func effect(module_id: String, key: String, fallback: float) -> float:
	return float(module(module_id).get("effects", {}).get(key, fallback))
