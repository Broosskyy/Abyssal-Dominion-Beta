class_name P1RegionalVisualAcceptanceCatalog
extends Node

const PATH := "res://data/m150_p1_regional_visual_acceptance.json"
static var config: Dictionary = {}
static var errors := PackedStringArray()

func _ready() -> void:
	add_to_group("p1_regional_visual_acceptance_catalog")
	_ensure()
	_validate()
	get_tree().root.set_meta("m150_p1_regional_visual_acceptance", summary())

static func region(id: String) -> Dictionary:
	_ensure()
	return ((config.get("regions", {}) as Dictionary).get(id, {}) as Dictionary).duplicate(true)

static func default_profile() -> Dictionary:
	_ensure()
	return (config.get("default_profile", {}) as Dictionary).duplicate(true)

static func material_path(region_id: String, family: String) -> String:
	return str((region(region_id).get("materials", {}) as Dictionary).get(family, ""))

static func summary() -> Dictionary:
	_ensure()
	return {"milestone":"M150","regions":(config.get("regions", {}) as Dictionary).size(),"materials":8,"qa_scene":str((config.get("acceptance", {}) as Dictionary).get("qa_scene", "")),"errors":errors.duplicate(),"valid":errors.is_empty(),"live_activation":false}

static func _ensure() -> void:
	if not config.is_empty(): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	config = parsed if parsed is Dictionary else {}

static func _validate() -> void:
	errors.clear()
	for region_id in ["crimson_sea", "drowned_reach"]:
		var profile := region(region_id)
		if profile.is_empty(): errors.append("missing_region:" + region_id); continue
		for family in ["ship", "monster", "world", "harbor"]:
			var path := material_path(region_id, family)
			if path.is_empty() or not ResourceLoader.exists(path): errors.append("missing_material:%s:%s" % [region_id, family])
	var qa_scene := str((config.get("acceptance", {}) as Dictionary).get("qa_scene", ""))
	if qa_scene.is_empty() or not ResourceLoader.exists(qa_scene): errors.append("missing_qa_scene")
