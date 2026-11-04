class_name M241CrewOfficerRuntime
extends Node

signal roster_changed
signal assignment_changed

const CONTRACT_PATH := "res://data/m241_crew_officer_contract.json"
var owned: Dictionary = {}
var assigned_slots: Array[String] = []
var _data: Dictionary = {}

func _ready() -> void:
	_load_contract()
	if owned.is_empty():
		_initialize_starter_state()

func _load_contract() -> void:
	if not _data.is_empty(): return
	if not FileAccess.file_exists(CONTRACT_PATH): return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	if parsed is Dictionary: _data = parsed

func _initialize_starter_state() -> void:
	_load_contract()
	owned.clear()
	for officer_id in _data.get("starter_owned", []):
		owned[str(officer_id)] = {"level": 1, "xp": 0}
	assigned_slots.clear()
	for officer_id in _data.get("starter_assignment", []):
		assigned_slots.append(str(officer_id))
	_normalize_slots()

func slot_count() -> int:
	_load_contract()
	return maxi(1, int((_data.get("crew_model", {}) as Dictionary).get("prototype_officer_slots", 4)))

func officer_def(officer_id: String) -> Dictionary:
	_load_contract()
	for row in _data.get("officers", []):
		if row is Dictionary and str(row.get("id", "")) == officer_id:
			return row
	return {}

func officer_label(officer_id: String) -> String:
	if officer_id.is_empty(): return "FREI"
	var row := officer_def(officer_id)
	return str(row.get("label", officer_id))

func owned_ids() -> Array[String]:
	var result: Array[String] = []
	for key in owned.keys(): result.append(str(key))
	result.sort_custom(func(a: String, b: String):
		var da := officer_def(a)
		var db := officer_def(b)
		var fa := str(da.get("family", "")); var fb := str(db.get("family", ""))
		if fa == fb: return int(da.get("tier", 0)) < int(db.get("tier", 0))
		return fa < fb)
	return result

func is_owned(officer_id: String) -> bool:
	return owned.has(officer_id)

func assigned_slot(officer_id: String) -> int:
	return assigned_slots.find(officer_id)

func assign(slot_index: int, officer_id: String) -> bool:
	_normalize_slots()
	if slot_index < 0 or slot_index >= assigned_slots.size(): return false
	if officer_id.is_empty():
		if assigned_slots[slot_index].is_empty(): return false
		assigned_slots[slot_index] = ""
		assignment_changed.emit(); roster_changed.emit(); return true
	if not is_owned(officer_id) or officer_def(officer_id).is_empty(): return false
	var existing := assigned_slot(officer_id)
	if existing >= 0 and existing != slot_index: return false
	if assigned_slots[slot_index] == officer_id: return false
	assigned_slots[slot_index] = officer_id
	assignment_changed.emit(); roster_changed.emit()
	return true

func cycle_slot(slot_index: int) -> bool:
	_normalize_slots()
	if slot_index < 0 or slot_index >= assigned_slots.size(): return false
	var candidates: Array[String] = [""]
	for officer_id in owned_ids():
		var occupied := assigned_slot(officer_id)
		if occupied < 0 or occupied == slot_index: candidates.append(officer_id)
	if candidates.size() <= 1 and assigned_slots[slot_index].is_empty(): return false
	var current := candidates.find(assigned_slots[slot_index])
	var next := candidates[(current + 1) % candidates.size()] if current >= 0 else candidates[0]
	return assign(slot_index, next)

func effective_tier(family: String) -> int:
	_normalize_slots()
	var best := 0
	for officer_id in assigned_slots:
		if officer_id.is_empty(): continue
		var row := officer_def(officer_id)
		if str(row.get("family", "")) == family:
			best = maxi(best, int(row.get("tier", 0)))
	return best

func summary() -> String:
	_normalize_slots()
	var occupied := 0
	for officer_id in assigned_slots:
		if not officer_id.is_empty(): occupied += 1
	return "%d/%d Slots · Reparaturmeister %s · Schutzschildmeister %s" % [occupied, slot_count(), _roman(effective_tier("repair_master")), _roman(effective_tier("shield_master"))]

func roster_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for officer_id in owned_ids():
		var row := officer_def(officer_id).duplicate(true)
		var state: Dictionary = owned.get(officer_id, {})
		row["level"] = int(state.get("level", 1))
		row["xp"] = int(state.get("xp", 0))
		row["assigned_slot"] = assigned_slot(officer_id)
		rows.append(row)
	return rows

func locked_rows() -> Array[Dictionary]:
	_load_contract()
	var rows: Array[Dictionary] = []
	for raw in _data.get("officers", []):
		if raw is Dictionary and not is_owned(str(raw.get("id", ""))): rows.append((raw as Dictionary).duplicate(true))
	return rows

func grant_for_local_qa(officer_id: String) -> bool:
	# LOCAL_DEVELOPMENT helper only. Live ownership must come from an authoritative service.
	if officer_def(officer_id).is_empty() or owned.has(officer_id): return false
	owned[officer_id] = {"level": 1, "xp": 0}
	roster_changed.emit()
	return true

func import_legacy_sustain_state(data: Dictionary) -> void:
	# Preserve M240 local saves without treating legacy tier numbers as a live entitlement source.
	_initialize_starter_state()
	var repair_tier := clampi(int(data.get("repair_master_tier", 1)), 1, 3)
	var shield_tier := clampi(int(data.get("shield_master_tier", 1)), 1, 3)
	var repair_id := "repair_master_%s" % _roman_lower(repair_tier)
	var shield_id := "shield_master_%s" % _roman_lower(shield_tier)
	grant_for_local_qa(repair_id); grant_for_local_qa(shield_id)
	assign(0, repair_id)
	assign(1, shield_id)

func export_state() -> Dictionary:
	_normalize_slots()
	return {"schema": 1, "owned": owned.duplicate(true), "assigned_slots": assigned_slots.duplicate()}

func import_state(data: Dictionary) -> void:
	_load_contract()
	owned.clear()
	var incoming_owned = data.get("owned", {})
	if incoming_owned is Dictionary:
		for key in incoming_owned.keys():
			var officer_id := str(key)
			if officer_def(officer_id).is_empty(): continue
			var state: Dictionary = incoming_owned[key] if incoming_owned[key] is Dictionary else {}
			owned[officer_id] = {"level": clampi(int(state.get("level", 1)), 1, int(officer_def(officer_id).get("max_level", 10))), "xp": maxi(0, int(state.get("xp", 0)))}
	for starter in _data.get("starter_owned", []):
		if not owned.has(str(starter)): owned[str(starter)] = {"level": 1, "xp": 0}
	assigned_slots.clear()
	var incoming_slots = data.get("assigned_slots", [])
	if incoming_slots is Array:
		for raw in incoming_slots:
			var officer_id := str(raw)
			assigned_slots.append(officer_id if officer_id.is_empty() or is_owned(officer_id) else "")
	_normalize_slots()
	# Remove duplicate assignments deterministically.
	var seen: Dictionary = {}
	for i in range(assigned_slots.size()):
		var officer_id := assigned_slots[i]
		if officer_id.is_empty(): continue
		if seen.has(officer_id): assigned_slots[i] = ""
		else: seen[officer_id] = true
	roster_changed.emit(); assignment_changed.emit()

func _normalize_slots() -> void:
	while assigned_slots.size() < slot_count(): assigned_slots.append("")
	while assigned_slots.size() > slot_count(): assigned_slots.pop_back()

func _roman(value: int) -> String:
	return ["—", "I", "II", "III"][clampi(value, 0, 3)]

func _roman_lower(value: int) -> String:
	return ["", "i", "ii", "iii"][clampi(value, 0, 3)]
