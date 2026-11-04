class_name ProductionWaveCatalog
extends Node

const PATH := "res://data/m147_p1_p4_production_waves.json"
static var config: Dictionary = {}
static var validation_errors := PackedStringArray()

func _ready() -> void:
	add_to_group("production_wave_catalog")
	_ensure()
	_validate()
	get_tree().root.set_meta("m147_production_waves", summary())

static func entry(id: String) -> Dictionary:
	_ensure()
	for value in config.get("active_glb_slots", []):
		if value is Dictionary and str(value.get("id", "")) == id:
			var row := (value as Dictionary).duplicate(true)
			var wave: Dictionary = (config.get("waves", {}) as Dictionary).get(str(row.get("wave", "")), {})
			row["path"] = str(wave.get("root", "")) + str(row.get("file", ""))
			row["classification"] = "M147_DEDICATED_PRODUCTION_PLACEHOLDER"
			return row
	return {}

static func runtime_id(master_slot: String) -> String:
	_ensure()
	for value in config.get("active_glb_slots", []):
		if value is Dictionary and str(value.get("master_slot", "")) == master_slot:
			return str(value.get("id", master_slot))
	return master_slot

static func wave_for_ship(index: int) -> String:
	_ensure()
	for wave_id in (config.get("waves", {}) as Dictionary):
		var row: Dictionary = config.waves[wave_id]
		var bounds: Array = row.get("main_ship_range", [])
		if bounds.size() == 2 and index >= int(bounds[0]) and index <= int(bounds[1]): return str(wave_id)
	return ""

func summary() -> Dictionary:
	_ensure()
	var ready := 0
	for value in config.get("active_glb_slots", []):
		if value is Dictionary:
			var row := entry(str(value.get("id", "")))
			if FileAccess.file_exists(str(row.get("path", ""))) and _is_glb(str(row.get("path", ""))): ready += 1
	return {
		"milestone":"M147", "p1_glb_ready":ready, "p1_glb_total":config.get("active_glb_slots", []).size(),
		"p2_reserved":20, "p3_reserved":10, "p4_reserved":10, "p_event_reserved":true,
		"errors":validation_errors.duplicate(), "valid":validation_errors.is_empty(),
		"live_activation":false
	}

static func _ensure() -> void:
	if not config.is_empty(): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	config = parsed if parsed is Dictionary else {}

static func _validate() -> void:
	validation_errors.clear()
	var covered := {}
	for wave_id in (config.get("waves", {}) as Dictionary):
		var row: Dictionary = config.waves[wave_id]
		var bounds: Array = row.get("main_ship_range", [])
		if bounds.size() != 2:
			validation_errors.append("invalid_range:" + str(wave_id))
			continue
		for index in range(int(bounds[0]), int(bounds[1]) + 1):
			if covered.has(index): validation_errors.append("overlap_ship:" + str(index))
			covered[index] = wave_id
	for index in range(1, 51):
		if not covered.has(index): validation_errors.append("missing_ship:" + str(index))
	var p4: Dictionary = (config.get("waves", {}) as Dictionary).get("P4", {})
	if str(p4.get("master_priority", "")) != "P3": validation_errors.append("p4_must_remain_master_p3_endgame")
	var seen_paths := {}
	for value in config.get("active_glb_slots", []):
		if not value is Dictionary: continue
		var row := entry(str(value.get("id", "")))
		var path := str(row.get("path", ""))
		if seen_paths.has(path): validation_errors.append("duplicate_active_path:" + path)
		seen_paths[path] = true
		if not path.begins_with("res://assets/production_placeholders/p1/") or not _is_glb(path): validation_errors.append("invalid_p1_glb:" + str(value.get("id", "")))

static func _is_glb(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	return file != null and file.get_length() >= 20 and file.get_buffer(4).get_string_from_ascii() == "glTF"
