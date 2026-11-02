class_name M267AuthoritativeWorldTransportRuntime
extends Node
## M267 authoritative world transport / snapshot protocol replica.
## The client may request join/resync/transfer and render/interpolate server state,
## but it can never publish authoritative world state, entity identity or ticks.
signal changed
signal resync_required(reason: String)

var session_id := ""
var environment := ""
var instance_id := ""
var snapshot_revision := -1
var server_tick := -1
var last_sequence := -1
var baseline_id := ""
var authoritative_entities: Dictionary = {}
var transport_state: Dictionary = {}
var _resync_pending := false
var _resync_reason := ""

func _ready() -> void:
	add_to_group("authoritative_world_transport_readiness")

func reset_replica() -> void:
	session_id = ""
	environment = ""
	instance_id = ""
	snapshot_revision = -1
	server_tick = -1
	last_sequence = -1
	baseline_id = ""
	authoritative_entities.clear()
	transport_state.clear()
	_resync_pending = false
	_resync_reason = ""
	changed.emit()

func ingest_full_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	var meta = snapshot.get("meta", {})
	var rows = snapshot.get("entities", [])
	if not (meta is Dictionary) or not (rows is Array): return false
	var incoming_session := str((meta as Dictionary).get("session_id", ""))
	var incoming_environment := str((meta as Dictionary).get("environment", "")).to_upper()
	var incoming_instance := str((meta as Dictionary).get("instance_id", ""))
	var incoming_baseline := str((meta as Dictionary).get("baseline_id", ""))
	var incoming_revision := int((meta as Dictionary).get("snapshot_revision", -1))
	var incoming_tick := int((meta as Dictionary).get("server_tick", -1))
	var incoming_sequence := int((meta as Dictionary).get("sequence", -1))
	if incoming_session.is_empty() or incoming_instance.is_empty() or incoming_baseline.is_empty(): return false
	if incoming_environment not in ["INTERNAL", "TEST", "GLOBAL"]: return false
	if incoming_revision < 0 or incoming_tick < 0 or incoming_sequence < 0: return false
	if not environment.is_empty() and incoming_environment != environment: return false
	if not session_id.is_empty() and incoming_session == session_id and incoming_revision <= snapshot_revision: return false
	var next_entities: Dictionary = {}
	for raw in rows:
		if not (raw is Dictionary): return false
		var row := (raw as Dictionary)
		var entity_id := str(row.get("network_entity_id", ""))
		var generation := int(row.get("spawn_generation", -1))
		if entity_id.is_empty() or generation < 0 or next_entities.has(entity_id): return false
		next_entities[entity_id] = row.duplicate(true)
	session_id = incoming_session
	environment = incoming_environment
	instance_id = incoming_instance
	baseline_id = incoming_baseline
	snapshot_revision = incoming_revision
	server_tick = incoming_tick
	last_sequence = incoming_sequence
	authoritative_entities = next_entities
	transport_state = {"source":"SERVER","mode":"BASELINE","connected":true,"stale":false}
	_resync_pending = false
	_resync_reason = ""
	changed.emit()
	return true

func ingest_delta(packet: Dictionary, server_verified: bool) -> bool:
	if not server_verified or baseline_id.is_empty(): return false
	var meta = packet.get("meta", {})
	var ops = packet.get("ops", [])
	if not (meta is Dictionary) or not (ops is Array): return false
	if str((meta as Dictionary).get("session_id", "")) != session_id: return false
	if str((meta as Dictionary).get("environment", "")).to_upper() != environment: return false
	if str((meta as Dictionary).get("instance_id", "")) != instance_id: return false
	if str((meta as Dictionary).get("baseline_id", "")) != baseline_id:
		_require_resync("baseline_mismatch"); return false
	var incoming_sequence := int((meta as Dictionary).get("sequence", -1))
	var incoming_revision := int((meta as Dictionary).get("snapshot_revision", -1))
	var incoming_tick := int((meta as Dictionary).get("server_tick", -1))
	if incoming_sequence <= last_sequence or incoming_revision <= snapshot_revision or incoming_tick < server_tick: return false
	if incoming_sequence != last_sequence + 1:
		_require_resync("sequence_gap"); return false
	var next_entities := authoritative_entities.duplicate(true)
	for raw in ops:
		if not (raw is Dictionary): return false
		var op := raw as Dictionary
		var kind := str(op.get("op", ""))
		var entity_id := str(op.get("network_entity_id", ""))
		if entity_id.is_empty(): return false
		match kind:
			"spawn":
				var state = op.get("state", {})
				if not (state is Dictionary) or next_entities.has(entity_id): return false
				if int((state as Dictionary).get("spawn_generation", -1)) < 0: return false
				next_entities[entity_id] = (state as Dictionary).duplicate(true)
			"patch":
				var patch = op.get("patch", {})
				if not next_entities.has(entity_id) or not (patch is Dictionary): return false
				var current: Dictionary = (next_entities[entity_id] as Dictionary).duplicate(true)
				if int(op.get("spawn_generation", current.get("spawn_generation", -1))) != int(current.get("spawn_generation", -1)): return false
				for key in (patch as Dictionary).keys(): current[key] = (patch as Dictionary)[key]
				next_entities[entity_id] = current
			"despawn":
				if not next_entities.has(entity_id): return false
				var current: Dictionary = next_entities[entity_id]
				if int(op.get("spawn_generation", -1)) != int(current.get("spawn_generation", -2)): return false
				next_entities.erase(entity_id)
			_:
				return false
	authoritative_entities = next_entities
	last_sequence = incoming_sequence
	snapshot_revision = incoming_revision
	server_tick = incoming_tick
	transport_state = {"source":"SERVER","mode":"DELTA","connected":true,"stale":false}
	changed.emit()
	return true

func _require_resync(reason: String) -> void:
	_resync_pending = true
	_resync_reason = reason
	transport_state["stale"] = true
	transport_state["mode"] = "RESYNC_REQUIRED"
	resync_required.emit(reason)
	changed.emit()

func mark_transport_lost_locally() -> void:
	# Presentation-only stale marker. It never advances world authority.
	if baseline_id.is_empty(): return
	transport_state["connected"] = false
	transport_state["stale"] = true
	transport_state["mode"] = "DISCONNECTED"
	changed.emit()

func snapshot() -> Dictionary:
	return {
		"source":"SERVER" if not baseline_id.is_empty() else "LOCAL_PREVIEW",
		"session_id":session_id,"environment":environment,"instance_id":instance_id,
		"baseline_id":baseline_id,"snapshot_revision":snapshot_revision,"server_tick":server_tick,
		"sequence":last_sequence,"entity_count":authoritative_entities.size(),
		"transport":transport_state.duplicate(true),"resync_pending":_resync_pending,"resync_reason":_resync_reason
	}

func entity_state(network_entity_id: String) -> Dictionary:
	if not authoritative_entities.has(network_entity_id): return {}
	return (authoritative_entities[network_entity_id] as Dictionary).duplicate(true)

func entity_rows() -> Array:
	var rows: Array = []
	for id in authoritative_entities.keys(): rows.append((authoritative_entities[id] as Dictionary).duplicate(true))
	return rows

func prepare_join_intent(map_id: String, region_id: String, request_id: String) -> Dictionary:
	return {"operation":"JOIN_WORLD","map_id":map_id,"region_id":region_id,"request_id":request_id,"authority":"CLIENT_REQUEST_ONLY","server_verified":false}
func prepare_resync_intent(request_id: String) -> Dictionary:
	return {"operation":"WORLD_RESYNC","session_id":session_id,"instance_id":instance_id,"baseline_id":baseline_id,"last_sequence":last_sequence,"snapshot_revision":snapshot_revision,"request_id":request_id,"authority":"CLIENT_REQUEST_ONLY","server_verified":false}
func prepare_transfer_intent(target_map_id: String, target_region_id: String, request_id: String) -> Dictionary:
	return {"operation":"WORLD_TRANSFER","source_instance_id":instance_id,"target_map_id":target_map_id,"target_region_id":target_region_id,"request_id":request_id,"authority":"CLIENT_REQUEST_ONLY","server_verified":false}

func can_client_publish_full_snapshot() -> bool: return false
func can_client_publish_delta() -> bool: return false
func can_client_allocate_network_entity_id() -> bool: return false
func can_client_advance_server_tick() -> bool: return false
func can_client_advance_snapshot_revision() -> bool: return false
func can_client_force_sequence() -> bool: return false
func can_client_authorize_spawn_despawn() -> bool: return false
func can_client_confirm_zone_transfer() -> bool: return false
func can_client_clear_resync_without_baseline() -> bool: return false
func can_client_transfer_test_world_to_global() -> bool: return false
