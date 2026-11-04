class_name MainProgressionFleet
extends RefCounted

const PATH := "res://data/main_progression_fleet.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if not _data.is_empty(): return _data
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_data = parsed if parsed is Dictionary else {}
	return _data

static func design(id: String) -> Dictionary:
	for entry in data().get("designs", []):
		if str(entry.get("id", "")) == id: return entry
	return ShipProductionArchitecture.progression_design(id)

static func unlocked_at_map_level(map_level: int) -> Array[String]:
	var result: Array[String] = []
	for entry in data().get("designs", []):
		if int(entry.get("unlock", {}).get("map_level", 999)) <= map_level:
			result.append(str(entry.id))
	for index in range(51, 101):
		var late := ShipProductionArchitecture.progression_design("ship_main_%02d" % index)
		if int((late.get("unlock", {}) as Dictionary).get("map_level", 999999)) <= map_level: result.append(str(late.id))
	return result

static func fallback_profile(id: String) -> String:
	return str(design(id).get("fallback_profile", BeginnerRules.START_SHIP))


static func eligible_designs(map_level: int) -> Array[String]:
	var result: Array[String] = []
	for entry in data().get("designs", []):
		if int(entry.get("unlock", {}).get("map_level", 999)) <= map_level:
			result.append(str(entry.get("id","")))
	for index in range(51, 101):
		var late := ShipProductionArchitecture.progression_design("ship_main_%02d" % index)
		if int((late.get("unlock", {}) as Dictionary).get("map_level", 999999)) <= map_level: result.append(str(late.get("id", "")))
	return result

static func prestige_design(rank: int) -> Dictionary:
	return ShipProductionArchitecture.progression_design("prestige_p%d" % clampi(rank, 1, 5))

static func is_eligible(id: String, map_level: int) -> bool:
	return eligible_designs(map_level).has(id)
