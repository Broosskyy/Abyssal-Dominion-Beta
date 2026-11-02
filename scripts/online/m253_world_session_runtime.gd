class_name M253WorldSessionRuntime
extends Node
## M253 read-only replica for realtime world/session/presence/reconnect continuity.
## Cached or local state never becomes authority.
signal changed
var revision := -1
var world_revision := -1
var authoritative_snapshot: Dictionary = {}
var last_confirmed_snapshot: Dictionary = {}

func _ready() -> void:
	add_to_group("world_session_readiness")

func ingest_authoritative_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision < revision: return false
	var session_id := str(snapshot.get("session_id", ""))
	if session_id.is_empty(): return false
	var environment := str(snapshot.get("environment", ""))
	if environment == "LOCAL_DEVELOPMENT" or environment.is_empty(): return false
	var world = snapshot.get("world", {})
	if not world is Dictionary: return false
	var incoming_world_revision := int((world as Dictionary).get("world_revision", -1))
	if incoming_world_revision < 0: return false
	if session_id == str(authoritative_snapshot.get("session_id", "")) and incoming_world_revision < world_revision: return false
	revision = incoming_revision
	world_revision = incoming_world_revision
	authoritative_snapshot = snapshot.duplicate(true)
	last_confirmed_snapshot = authoritative_snapshot.duplicate(true)
	changed.emit()
	return true

func snapshot() -> Dictionary:
	if not authoritative_snapshot.is_empty():
		var result := authoritative_snapshot.duplicate(true)
		result["source"] = "SERVER"
		result["revision"] = revision
		return result
	return local_empty_state()

func local_empty_state() -> Dictionary:
	return {
		"source":"LOCAL_PREVIEW",
		"revision":-1,
		"session_id":"",
		"environment":EnvironmentContract.current_id(get_tree()) if get_tree()!=null else "LOCAL_DEVELOPMENT",
		"connection":{"state":"offline","server_verified":false,"stale":false},
		"world":{"world_revision":-1,"region_id":"","map_id":"","instance_id":"","channel_id":"","population":0,"server_tick":-1},
		"presence":[],
		"resume":{"state":"unavailable","ticket_present":false,"server_verified":false},
		"last_error":"production_world_session_not_connected"
	}

func presence_rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if str(snapshot().get("source", "")) != "SERVER": return result
	var rows = snapshot().get("presence", [])
	if rows is Array:
		for row in rows:
			if row is Dictionary: result.append((row as Dictionary).duplicate(true))
	return result

func world_state() -> Dictionary:
	var snap := snapshot()
	return (snap.get("world", {}) as Dictionary).duplicate(true) if snap.get("world", {}) is Dictionary else {}

func connection_state() -> Dictionary:
	var snap := snapshot()
	return (snap.get("connection", {}) as Dictionary).duplicate(true) if snap.get("connection", {}) is Dictionary else {}

func resume_state() -> Dictionary:
	var snap := snapshot()
	return (snap.get("resume", {}) as Dictionary).duplicate(true) if snap.get("resume", {}) is Dictionary else {}

func hud_status() -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER": return {"visible":false,"source":str(snap.get("source", "LOCAL_PREVIEW"))}
	var connection := connection_state()
	var state := str(connection.get("state", "connected"))
	if state not in ["degraded", "reconnecting", "resume_pending"]: return {"visible":false,"source":"SERVER","state":state}
	return {"visible":true,"source":"SERVER","state":state,"label":{"degraded":"NETZ INSTABIL","reconnecting":"VERBINDUNG…","resume_pending":"REJOIN…"}.get(state,"VERBINDUNG…")}

func mark_transport_lost_locally() -> void:
	# Presentation degradation only. It cannot fabricate a resume verdict or world mutation.
	if authoritative_snapshot.is_empty(): return
	var connection: Dictionary = authoritative_snapshot.get("connection", {}).duplicate(true) if authoritative_snapshot.get("connection", {}) is Dictionary else {}
	connection["state"] = "degraded"
	connection["stale"] = true
	authoritative_snapshot["connection"] = connection
	changed.emit()

func can_client_create_session_id() -> bool: return false
func can_client_publish_presence() -> bool: return false
func can_client_assign_map_instance() -> bool: return false
func can_client_advance_world_revision() -> bool: return false
func can_client_generate_resume_ticket() -> bool: return false
func can_client_finalize_resume() -> bool: return false
func can_client_set_population() -> bool: return false
func can_client_set_server_tick() -> bool: return false
func can_client_settle_from_stale_snapshot() -> bool: return false
