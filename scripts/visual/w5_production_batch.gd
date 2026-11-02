class_name W5ProductionBatch
extends Node

const PATH := "res://data/m153_w5_lod_batch.json"
static var config: Dictionary = {}
static var errors := PackedStringArray()

func _ready() -> void:
	add_to_group("w5_production_batch")
	_ensure()
	_validate()
	get_tree().root.set_meta("m153_w5_production_batch", summary())

static func all() -> Array[Dictionary]:
	_ensure()
	var result: Array[Dictionary] = []
	for row in config.get("ships", []):
		if row is Dictionary: result.append(_with_paths(row))
	return result

static func entry(id: String) -> Dictionary:
	for row in all():
		if str(row.get("id", "")) == id: return row.duplicate(true)
	return {}

static func summary() -> Dictionary:
	_ensure()
	var lod_files := 0
	var complete := 0
	for row in all():
		var ready := true
		for key in ["lod0_path", "lod1_path", "lod2_path"]:
			if ResourceLoader.exists(str(row.get(key, ""))): lod_files += 1
			else: ready = false
		if ready: complete += 1
	return {"milestone":"M153","wave":"W5","ships":all().size(),"complete_lod_sets":complete,"lod_files":lod_files,"socket_count":(config.get("socket_contract",[]) as Array).size(),"classification":"CLEAN_ROOM_GLB_PLACEHOLDER_NOT_FINAL_ART","valid":errors.is_empty(),"errors":errors.duplicate(),"live_activation":false}

static func required_sockets() -> Array:
	_ensure()
	return (config.get("socket_contract", []) as Array).duplicate()

static func _with_paths(source: Dictionary) -> Dictionary:
	var row := source.duplicate(true)
	var id := str(row.get("id", ""))
	row["path"] = str(config.get("path_pattern", "")).replace("{id}", id)
	row["lod0_path"] = row.path
	row["lod1_path"] = str(config.get("lod1_pattern", "")).replace("{id}", id)
	row["lod2_path"] = str(config.get("lod2_pattern", "")).replace("{id}", id)
	row["classification"] = "M153_W5_CLEAN_ROOM_GLB_PLACEHOLDER"
	row["counts_as_final_glb"] = false
	row["production_status"] = "PLACEHOLDER_READY_REPLACEABLE"
	return row

static func _ensure() -> void:
	if not config.is_empty(): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	config = parsed if parsed is Dictionary else {}

static func _validate() -> void:
	errors.clear()
	var ids := {}
	for row in all():
		var id := str(row.get("id", ""))
		ids[id] = int(ids.get(id, 0)) + 1
		if id.is_empty() or int(ids[id]) > 1: errors.append("duplicate_or_empty:" + id)
		for key in ["lod0_path", "lod1_path", "lod2_path"]:
			if not ResourceLoader.exists(str(row.get(key, ""))): errors.append("missing_%s:%s" % [key,id])
	if all().size() != 10: errors.append("ship_count_not_10")
	if required_sockets().size() < 10: errors.append("socket_contract_incomplete")
