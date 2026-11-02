class_name ShipProductionArchitecture
extends Node

const PATH := "res://data/m151_late_fleet_production_architecture.json"
static var config: Dictionary = {}
static var errors := PackedStringArray()

func _ready() -> void:
	add_to_group("ship_production_architecture")
	_ensure()
	_validate()
	get_tree().root.set_meta("m151_ship_production_architecture", summary())

static func entry(id: String) -> Dictionary:
	_ensure()
	if id.begins_with("ship_main_"):
		var index := id.trim_prefix("ship_main_").to_int()
		if index < 51 or index > 100: return {}
		var family := family_for(index)
		var wave := wave_for(index)
		if family.is_empty() or wave.is_empty(): return {}
		var variant := index - int((family.get("range", []) as Array)[0]) + 1
		var recipe := (family.get("recipe", {}) as Dictionary).duplicate(true)
		recipe["masts"] = int(family.get("masts", 2))
		recipe["variant"] = variant
		recipe["twin_hull"] = str(family.get("hull", "")).contains("twin hull")
		var result := {"id":id,"master_slot":"SHIP-PROG-%03d" % index,"class_number":index,"kind":"regular","family":str(family.id),"role":str(family.role),"variant":variant,"path":str(wave.root) + id + ".glb","wave":str(wave.id),"recipe":recipe,"state":"RESERVED_DISTINCT_GLB_WITH_RUNTIME_FALLBACK","classification":"M151_RESERVED_REPLACEABLE_SLOT","counts_as_final_glb":false}
		var w5 := W5ProductionBatch.entry(id)
		if not w5.is_empty(): result.merge(w5, true); result["state"] = "M153_W5_GLB_PLACEHOLDER_READY_REPLACEABLE"
		return result
	for row in (config.get("prestige", {}) as Dictionary).get("classes", []):
		if row is Dictionary and str(row.get("id", "")) == id:
			var result := (row as Dictionary).duplicate(true)
			result["kind"] = "prestige"
			result["master_slot"] = "SHIP-PRESTIGE-" + str(result.get("rank", ""))
			result["path"] = str((config.get("prestige", {}) as Dictionary).get("root", "")) + id + ".glb"
			result["state"] = "RESERVED_DISTINCT_GLB_WITH_RUNTIME_FALLBACK"
			result["classification"] = "M151_RESERVED_REPLACEABLE_SLOT"
			return result
	return {}

static func family_for(index: int) -> Dictionary:
	_ensure()
	for row in config.get("families", []):
		if not row is Dictionary: continue
		var bounds := row.get("range", []) as Array
		if bounds.size() == 2 and index >= int(bounds[0]) and index <= int(bounds[1]): return (row as Dictionary).duplicate(true)
	return {}

static func wave_for(index: int) -> Dictionary:
	_ensure()
	for row in config.get("waves", []):
		if not row is Dictionary: continue
		var bounds := row.get("range", []) as Array
		if bounds.size() == 2 and index >= int(bounds[0]) and index <= int(bounds[1]): return (row as Dictionary).duplicate(true)
	return {}

static func all_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(51, 101): result.append(entry("ship_main_%02d" % index))
	for rank in range(1, 6): result.append(entry("prestige_p%d" % rank))
	return result

static func progression_design(id: String) -> Dictionary:
	var row := entry(id)
	if row.is_empty(): return {}
	if str(row.get("kind", "")) == "prestige":
		return {"id":id,"display_name":str(row.get("name", id)),"production_status":str(row.state),"ship_mastery_levels":10,"role":str(row.role),"visual_slot":id,"fallback_profile":"chalupa","prestige_rank":str(row.rank),"unlock":{"contract":"Prestige rank requirements are server-authoritative; not regular class 101-105.","meaning":"prestige_eligibility_only"}}
	var index := int(row.class_number)
	return {"id":id,"display_name":"%s %02d" % [str(row.family).replace("_", " ").capitalize(), int(row.variant)],"production_status":str(row.state),"ship_mastery_levels":10,"role":str(row.role),"visual_slot":id,"fallback_profile":["clipper","barco_low","chalupa"][index % 3],"silhouette_family":str(row.family),"unlock":{"map_level":106 + (index - 51) * 2,"contract":"eligibility only; ownership requires explicit server-authoritative reward","meaning":"eligibility_threshold_only"}}

static func summary() -> Dictionary:
	_ensure()
	var final_glb := 0; var production_placeholders := 0
	for row in all_entries():
		if ResourceLoader.exists(str(row.get("path", ""))):
			if bool(row.get("counts_as_final_glb", false)): final_glb += 1
			else: production_placeholders += 1
	return {"milestone":"M153","regular_slots":50,"prestige_slots":5,"silhouette_families":10,"final_glb_ready":final_glb,"production_glb_placeholders":production_placeholders,"runtime_fallbacks":55-production_placeholders-final_glb,"qa_scene":str(config.get("qa_scene", "")),"errors":errors.duplicate(),"valid":errors.is_empty(),"global_locked":true,"live_activation":false}

static func _ensure() -> void:
	if not config.is_empty(): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	config = parsed if parsed is Dictionary else {}

static func _validate() -> void:
	errors.clear()
	var covered := {}
	for row in config.get("families", []):
		if not row is Dictionary: continue
		var bounds := row.get("range", []) as Array
		if bounds.size() != 2: errors.append("invalid_family_range"); continue
		for index in range(int(bounds[0]), int(bounds[1]) + 1):
			if covered.has(index): errors.append("overlap_class:" + str(index))
			covered[index] = str(row.get("id", ""))
	for index in range(51, 101):
		if not covered.has(index): errors.append("missing_class:" + str(index))
	var entries := all_entries()
	var paths := {}
	for row in entries:
		var path := str(row.get("path", ""))
		if path.is_empty() or paths.has(path): errors.append("invalid_or_duplicate_path:" + path)
		paths[path] = true
	if entries.size() != 55: errors.append("slot_count_not_55")
	var qa_scene := str(config.get("qa_scene", ""))
	if qa_scene.is_empty() or not ResourceLoader.exists(qa_scene): errors.append("missing_qa_scene")
