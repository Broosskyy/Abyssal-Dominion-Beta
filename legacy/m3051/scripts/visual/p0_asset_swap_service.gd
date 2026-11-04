class_name P0AssetSwapService
extends Node

const MANIFEST_PATH := "res://data/m146_p0_asset_swap_manifest.json"
const VISUAL_MANIFEST_PATH := "res://assets/placeholder_pack/manifest.json"
var manifest: Dictionary = {}
var errors := PackedStringArray()

func _ready() -> void:
	add_to_group("p0_asset_swap_service")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	manifest = parsed if parsed is Dictionary else {}
	_validate()
	get_tree().root.set_meta("m146_p0_asset_swap", summary())

func entry(runtime_id: String) -> Dictionary:
	for row in manifest.get("slots", []):
		if row is Dictionary and str(row.get("runtime_id", "")) == runtime_id:
			return (row as Dictionary).duplicate(true)
	return {}

func summary() -> Dictionary:
	var slots: Array = manifest.get("slots", [])
	return {
		"milestone":"M146", "total":slots.size(), "valid":maxi(0, slots.size() - errors.size()),
		"errors":errors.duplicate(), "replace_without_code":errors.is_empty(),
		"next_wave":str(manifest.get("next_wave", ""))
	}

func _validate() -> void:
	errors.clear()
	if manifest.is_empty():
		errors.append("manifest_missing")
		return
	var visual_parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VISUAL_MANIFEST_PATH))
	var visual_assets: Dictionary = visual_parsed.get("assets", {}) if visual_parsed is Dictionary else {}
	var ids := {}
	var files := {}
	var master_slots := {}
	var root := str(manifest.get("replacement_root", ""))
	for value in manifest.get("slots", []):
		if not value is Dictionary:
			errors.append("invalid_row")
			continue
		var row := value as Dictionary
		var runtime_id := str(row.get("runtime_id", ""))
		var master_slot := str(row.get("master_slot", ""))
		var file_name := str(row.get("file", ""))
		var path := root + file_name
		if runtime_id.is_empty() or ids.has(runtime_id): errors.append("duplicate_runtime_id:" + runtime_id)
		if master_slot.is_empty() or master_slots.has(master_slot): errors.append("duplicate_master_slot:" + master_slot)
		if file_name.is_empty() or files.has(file_name): errors.append("duplicate_file:" + file_name)
		ids[runtime_id] = true; master_slots[master_slot] = true; files[file_name] = true
		if not path.begins_with("res://assets/production_placeholders/p0/") or path.get_extension().to_lower() != "glb": errors.append("unsafe_path:" + runtime_id)
		if not FileAccess.file_exists(path) or not _is_glb(path): errors.append("invalid_glb:" + runtime_id)
		var catalog_row: Dictionary = visual_assets.get(runtime_id, {}) if visual_assets.get(runtime_id, {}) is Dictionary else {}
		if str(catalog_row.get("path", "")) != path: errors.append("catalog_path_mismatch:" + runtime_id)

func _is_glb(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 20: return false
	return file.get_buffer(4).get_string_from_ascii() == "glTF"
