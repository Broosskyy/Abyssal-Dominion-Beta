class_name M257ReleaseOperationsRuntime
extends Node
## M257 read-only release/operations state. GLOBAL/TEST truth comes only from server/release operations.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}

func _ready() -> void:
	add_to_group("release_operations_readiness")

func ingest_authoritative_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision <= revision: return false
	var environment := str(snapshot.get("environment", "")).to_upper()
	if environment not in ["INTERNAL", "TEST", "GLOBAL"]: return false
	revision = incoming_revision
	authoritative_snapshot = snapshot.duplicate(true)
	changed.emit()
	return true

func snapshot() -> Dictionary:
	if not authoritative_snapshot.is_empty():
		var result := authoritative_snapshot.duplicate(true)
		result["source"] = "SERVER_OR_RELEASE_PIPELINE"
		result["revision"] = revision
		return result
	return {"source":"LOCAL_PREVIEW","revision":-1,"environment":"LOCAL","release_state":"development","minimum_version_state":"local_only","feature_flags":[],"incident":{},"deployment":{}}

func release_gate() -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER_OR_RELEASE_PIPELINE":
		return {"state":"LOCAL DEVELOPMENT","blocking":false,"authority":false}
	var minimum_state := str(snap.get("minimum_version_state", "supported"))
	var incident = snap.get("incident", {})
	var incident_state := str(incident.get("state", "")) if incident is Dictionary else ""
	var blocking := minimum_state == "update_required" or incident_state in ["maintenance", "login_blocked", "world_blocked"]
	return {"state":minimum_state.to_upper(),"blocking":blocking,"authority":true}

func feature_rows() -> Array[Dictionary]: return _server_rows("feature_flags")

func incident_summary() -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER_OR_RELEASE_PIPELINE": return {}
	var row = snap.get("incident", {})
	return (row as Dictionary).duplicate(true) if row is Dictionary else {}

func deployment_summary() -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER_OR_RELEASE_PIPELINE": return {}
	var row = snap.get("deployment", {})
	return (row as Dictionary).duplicate(true) if row is Dictionary else {}

func _server_rows(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER_OR_RELEASE_PIPELINE": return result
	var rows = snap.get(key, [])
	if rows is Array:
		for row in rows:
			if row is Dictionary: result.append((row as Dictionary).duplicate(true))
	return result

func can_client_set_minimum_version() -> bool: return false
func can_client_bypass_required_update() -> bool: return false
func can_client_override_feature_flag() -> bool: return false
func can_client_promote_build() -> bool: return false
func can_client_deploy() -> bool: return false
func can_client_rollback() -> bool: return false
func can_client_resolve_incident() -> bool: return false
func can_client_mark_release_healthy() -> bool: return false
func can_client_merge_test_and_global_state() -> bool: return false
func can_client_create_authoritative_progression_while_offline() -> bool: return false
