class_name P1RegionalRuntimeCatalog
extends Node

const PATH := "res://data/m149_p1_regional_runtime_profiles.json"
static var config: Dictionary = {}
static var errors := PackedStringArray()

func _ready() -> void:
	add_to_group("p1_regional_runtime_catalog")
	_ensure()
	_validate()
	get_tree().root.set_meta("m149_p1_regional_runtime", summary())

static func region(id: String) -> Dictionary:
	_ensure()
	return ((config.get("regions", {}) as Dictionary).get(id, {}) as Dictionary).duplicate(true)

static func platform() -> Dictionary:
	_ensure()
	var key := VisualQualityResolver.platform_key()
	return ((config.get("platforms", {}) as Dictionary).get(key, {}) as Dictionary).duplicate(true)

static func spawn(region_id: String) -> Dictionary:
	return (region(region_id).get("spawn", {}) as Dictionary).duplicate(true)

static func nature_slots(region_id: String) -> Array:
	return (region(region_id).get("nature_slots", []) as Array).duplicate()

static func island_slots(region_id: String) -> Array:
	return (region(region_id).get("island_visual_slots", []) as Array).duplicate()

static func summary() -> Dictionary:
	_ensure()
	return {"milestone":"M149","regions":(config.get("regions", {}) as Dictionary).size(),"platforms":(config.get("platforms", {}) as Dictionary).size(),"errors":errors.duplicate(),"valid":errors.is_empty(),"server_authoritative":true,"global_locked":true}

static func _ensure() -> void:
	if not config.is_empty(): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	config = parsed if parsed is Dictionary else {}

static func _validate() -> void:
	errors.clear()
	for id in ["crimson_sea", "drowned_reach"]:
		var row := region(id)
		if row.is_empty(): errors.append("missing_region:" + id); continue
		for key in ["material", "vfx", "spawn", "nature_slots", "island_visual_slots", "harbor_slot"]:
			if not row.has(key): errors.append("missing_" + key + ":" + id)
		for slot in row.get("nature_slots", []):
			if P1RegionalAssetCatalog.entry(str(slot)).is_empty(): errors.append("unknown_nature:" + str(slot))
		for slot in row.get("island_visual_slots", []):
			if P1RegionalAssetCatalog.entry(str(slot)).is_empty(): errors.append("unknown_island:" + str(slot))
		if P1RegionalAssetCatalog.entry(str(row.get("harbor_slot", ""))).is_empty(): errors.append("unknown_harbor:" + id)
	for key in ["desktop", "mobile", "web"]:
		if not (config.get("platforms", {}) as Dictionary).has(key): errors.append("missing_platform:" + key)
