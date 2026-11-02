class_name RegionalHarborEconomy
extends RefCounted
const PATH := "res://data/regional_harbor_economy.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if not _data.is_empty(): return _data
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_data = parsed if parsed is Dictionary else {}
	return _data

static func region_for_level(level: int) -> String:
	if level >= 6 and level <= 8: return "stormreach"
	if level >= 9 and level <= 11: return "ember_shoals"
	if level >= 12 and level <= 15: return "veil_sea"
	return ""

static func harbor(region_id: String) -> Dictionary:
	var value: Variant = data().get("harbors", {}).get(region_id, {})
	return value.duplicate(true) if value is Dictionary else {}

static func offer(region_id: String, item_id: String) -> Dictionary:
	var value: Variant = harbor(region_id).get("purchase_offers", {}).get(item_id, {})
	return value.duplicate(true) if value is Dictionary else {}

static func recipe_ids(region_id: String) -> Array:
	return harbor(region_id).get("recipes", [])
