class_name M242OfficerProgressionRuntime
extends Node

signal replica_changed
signal acquisition_changed

var revision := 0
var progression: Dictionary = {}
var acquisition: Dictionary = {}
var authority_state := "LOCAL_PREVIEW"

func ingest_authoritative_snapshot(snapshot: Dictionary) -> bool:
	var incoming_revision := int(snapshot.get("revision", 0))
	if incoming_revision < revision:
		return false
	revision = incoming_revision
	authority_state = "SERVER"
	progression.clear()
	var incoming_progression = snapshot.get("progression", {})
	if incoming_progression is Dictionary:
		for raw_id in incoming_progression.keys():
			var officer_id := str(raw_id)
			var row = incoming_progression[raw_id]
			if row is Dictionary:
				progression[officer_id] = _sanitize_progression(row)
	acquisition = (snapshot.get("acquisition", {}) as Dictionary).duplicate(true) if snapshot.get("acquisition", {}) is Dictionary else {}
	replica_changed.emit(); acquisition_changed.emit()
	return true

func state_for(officer_id: String, roster_state: Dictionary = {}) -> Dictionary:
	if progression.has(officer_id):
		var server_row: Dictionary = progression[officer_id].duplicate(true)
		server_row["authority"] = "SERVER"
		return server_row
	return {
		"level": maxi(1, int(roster_state.get("level", 1))),
		"xp": maxi(0, int(roster_state.get("xp", 0))),
		"next_level_xp": -1,
		"upgrade_state": "preview_no_threshold",
		"authority": "LOCAL_PREVIEW"
	}

func acquisition_for(officer_id: String) -> Dictionary:
	var offers = acquisition.get("officers", {})
	if offers is Dictionary and offers.get(officer_id, {}) is Dictionary:
		return (offers.get(officer_id, {}) as Dictionary).duplicate(true)
	return {"state":"not_published", "authority":authority_state}

func can_client_upgrade(_officer_id: String) -> bool:
	return false

func can_client_purchase(_officer_id: String) -> bool:
	return false

func _sanitize_progression(row: Dictionary) -> Dictionary:
	return {
		"level": maxi(1, int(row.get("level", 1))),
		"xp": maxi(0, int(row.get("xp", 0))),
		"next_level_xp": maxi(-1, int(row.get("next_level_xp", -1))),
		"upgrade_state": str(row.get("upgrade_state", "unknown")),
		"quality": str(row.get("quality", "")),
		"traits": row.get("traits", []).duplicate() if row.get("traits", []) is Array else []
	}

func export_state() -> Dictionary:
	return {"revision":revision, "progression":progression.duplicate(true), "acquisition":acquisition.duplicate(true), "authority_state":authority_state}

func import_state(state: Dictionary) -> void:
	revision = int(state.get("revision", 0))
	progression = (state.get("progression", {}) as Dictionary).duplicate(true) if state.get("progression", {}) is Dictionary else {}
	acquisition = (state.get("acquisition", {}) as Dictionary).duplicate(true) if state.get("acquisition", {}) is Dictionary else {}
	# Persisted server data is only a cached replica; it never becomes mutation authority.
	authority_state = "CACHED_SERVER" if str(state.get("authority_state", "LOCAL_PREVIEW")) == "SERVER" else str(state.get("authority_state", "LOCAL_PREVIEW"))
