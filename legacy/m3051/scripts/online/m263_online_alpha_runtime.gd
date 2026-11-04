class_name M263OnlineAlphaRuntime
extends Node
## M263 end-to-end Online Alpha server-contract replica. It never simulates a successful backend.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}
func _ready() -> void: add_to_group("online_alpha_readiness")
func ingest_authoritative_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision <= revision: return false
	var environment := str(snapshot.get("environment", "")).to_upper()
	if environment not in ["INTERNAL", "TEST", "GLOBAL"]: return false
	revision = incoming_revision; authoritative_snapshot = snapshot.duplicate(true); changed.emit(); return true
func snapshot() -> Dictionary:
	if not authoritative_snapshot.is_empty():
		var result := authoritative_snapshot.duplicate(true); result["source"] = "SERVER"; result["revision"] = revision; return result
	return {"source":"LOCAL_PREVIEW","revision":-1,"environment":"LOCAL","phase":"OFFLINE","account":{},"session":{},"world":{},"persistence":{},"reconnect":{},"flow_checks":[]}
func phase() -> String: return str(snapshot().get("phase", "OFFLINE"))
func _server_dict(key: String) -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER": return {}
	var row = snap.get(key, {}); return (row as Dictionary).duplicate(true) if row is Dictionary else {}
func account_state() -> Dictionary: return _server_dict("account")
func session_state() -> Dictionary: return _server_dict("session")
func world_state() -> Dictionary: return _server_dict("world")
func persistence_state() -> Dictionary: return _server_dict("persistence")
func reconnect_state() -> Dictionary: return _server_dict("reconnect")
func flow_checks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []; var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER": return result
	var rows = snap.get("flow_checks", [])
	if rows is Array:
		for row in rows:
			if row is Dictionary: result.append((row as Dictionary).duplicate(true))
	return result
func prepare_intent(kind: String, payload: Dictionary = {}) -> Dictionary:
	return {"kind":kind,"payload":payload.duplicate(true),"authority":"CLIENT_INTENT_ONLY","accepted_by_server":false,"settles_gameplay":false}
func can_client_authenticate_authoritatively() -> bool: return false
func can_client_open_session() -> bool: return false
func can_client_resolve_movement() -> bool: return false
func can_client_resolve_combat() -> bool: return false
func can_client_confirm_persistence() -> bool: return false
func can_client_generate_resume_ticket() -> bool: return false
func can_client_finalize_rejoin() -> bool: return false
func can_client_acknowledge_leave() -> bool: return false
func can_client_mark_online_alpha_passed() -> bool: return false
