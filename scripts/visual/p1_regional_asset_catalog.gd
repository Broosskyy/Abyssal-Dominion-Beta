class_name P1RegionalAssetCatalog
extends Node

const PATH := "res://data/m148_p1_regional_asset_batch.json"
const ROOT := "res://assets/production_placeholders/p1/regional/"
static var config: Dictionary = {}
static var errors := PackedStringArray()

func _ready() -> void:
	add_to_group("p1_regional_asset_catalog")
	_ensure()
	_validate()
	get_tree().root.set_meta("m148_p1_regional_assets", summary())

static func entry(id: String) -> Dictionary:
	_ensure()
	for value in config.get("assets", []):
		if value is Dictionary and (str(value.get("id", "")) == id or str(value.get("master_slot", "")) == id):
			var row := (value as Dictionary).duplicate(true)
			row["path"] = ROOT + str(row.get("file", ""))
			row["classification"] = "M148_DEDICATED_PRODUCTION_PLACEHOLDER"
			row["live"] = false
			return row
	return {}

static func runtime_id(master_slot: String) -> String:
	var row := entry(master_slot)
	return str(row.get("id", master_slot))

static func summary() -> Dictionary:
	_ensure()
	var counts := {"ship":0,"monster":0,"flora":0,"island_module":0,"harbor":0}
	var valid := 0
	for value in config.get("assets", []):
		if not value is Dictionary: continue
		var row := entry(str(value.get("id", "")))
		var family := str(row.get("family", ""))
		counts[family] = int(counts.get(family, 0)) + 1
		if _is_glb(str(row.get("path", ""))): valid += 1
	return {"milestone":"M148","valid_glb":valid,"total":config.get("assets", []).size(),"counts":counts,"errors":errors.duplicate(),"valid":errors.is_empty(),"live_activation":false}

static func _ensure() -> void:
	if not config.is_empty(): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	config = parsed if parsed is Dictionary else {}

static func _validate() -> void:
	errors.clear()
	var ids := {}
	var slots := {}
	var paths := {}
	for value in config.get("assets", []):
		if not value is Dictionary: continue
		var row := entry(str(value.get("id", "")))
		var id := str(row.get("id", "")); var slot := str(row.get("master_slot", "")); var path := str(row.get("path", ""))
		if id.is_empty() or ids.has(id): errors.append("duplicate_or_empty_id:" + id)
		if slot.is_empty() or slots.has(slot): errors.append("duplicate_or_empty_slot:" + slot)
		if paths.has(path): errors.append("duplicate_path:" + path)
		ids[id] = true; slots[slot] = true; paths[path] = true
		if not path.begins_with(ROOT) or not _is_glb(path): errors.append("invalid_glb:" + id)

static func _is_glb(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	return file != null and file.get_length() >= 20 and file.get_buffer(4).get_string_from_ascii() == "glTF"
