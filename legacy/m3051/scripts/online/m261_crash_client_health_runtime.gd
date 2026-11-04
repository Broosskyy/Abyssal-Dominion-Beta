class_name M261CrashClientHealthRuntime
extends Node
## M261 read-only crash/client-health/QA readiness. Provider delivery and release QA verdicts remain Operations/QA-owned.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}
const FORBIDDEN_DIAGNOSTIC_KEYS := ["password","passwd","secret","token","authorization","receipt","store_receipt","api_key","private_key","credential"]

func _ready() -> void:
	add_to_group("crash_client_health_readiness")

func ingest_authoritative_snapshot(snapshot: Dictionary, operations_verified: bool) -> bool:
	if not operations_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision <= revision: return false
	var environment := str(snapshot.get("environment", "")).to_upper()
	if environment not in ["INTERNAL", "TEST", "GLOBAL"]: return false
	if _contains_forbidden_key(snapshot): return false
	revision = incoming_revision
	authoritative_snapshot = snapshot.duplicate(true)
	changed.emit()
	return true

func snapshot() -> Dictionary:
	if not authoritative_snapshot.is_empty():
		var result := authoritative_snapshot.duplicate(true)
		result["source"] = "QA_OPS"
		result["revision"] = revision
		return result
	return {"source":"LOCAL_PREVIEW","revision":-1,"environment":"LOCAL","crash_health":{},"client_health":{},"network_health":{},"qa_runs":[],"coverage":{},"known_issues":[]}

func prepare_sanitized_diagnostic_intent(kind: String, payload: Dictionary, player_opt_in: bool = false) -> Dictionary:
	var clean = _scrub(payload)
	return {"kind":kind.strip_edges(),"payload":clean,"player_opt_in":player_opt_in,"delivery_state":"NOT_SENT","authority":"CLIENT_DIAGNOSTIC_INTENT","grants_gameplay_authority":false}

func crash_health() -> Dictionary: return _ops_dict("crash_health")
func client_health() -> Dictionary: return _ops_dict("client_health")
func network_health() -> Dictionary: return _ops_dict("network_health")
func coverage() -> Dictionary: return _ops_dict("coverage")
func qa_run_rows() -> Array[Dictionary]: return _ops_rows("qa_runs")
func known_issue_rows() -> Array[Dictionary]: return _ops_rows("known_issues")

func _ops_dict(key: String) -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "QA_OPS": return {}
	var row = snap.get(key, {})
	return (row as Dictionary).duplicate(true) if row is Dictionary else {}

func _ops_rows(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var snap := snapshot()
	if str(snap.get("source", "")) != "QA_OPS": return result
	var rows = snap.get(key, [])
	if rows is Array:
		for row in rows:
			if row is Dictionary: result.append((row as Dictionary).duplicate(true))
	return result

func _scrub(value):
	if value is Dictionary:
		var out := {}
		for key in value.keys():
			var normalized := str(key).to_lower()
			var blocked := false
			for forbidden in FORBIDDEN_DIAGNOSTIC_KEYS:
				if normalized.contains(forbidden): blocked = true; break
			if not blocked: out[key] = _scrub(value[key])
		return out
	if value is Array:
		var out_array := []
		for item in value: out_array.append(_scrub(item))
		return out_array
	return value

func _contains_forbidden_key(value) -> bool:
	if value is Dictionary:
		for key in value.keys():
			var normalized := str(key).to_lower()
			for forbidden in FORBIDDEN_DIAGNOSTIC_KEYS:
				if normalized.contains(forbidden): return true
			if _contains_forbidden_key(value[key]): return true
	elif value is Array:
		for item in value:
			if _contains_forbidden_key(item): return true
	return false

func can_client_mark_crash_uploaded() -> bool: return false
func can_client_mark_qa_gate_passed() -> bool: return false
func can_client_fabricate_device_result() -> bool: return false
func can_client_close_crash_incident() -> bool: return false
func can_client_override_session_revalidation() -> bool: return false
func can_client_attach_secret_to_diagnostics() -> bool: return false
func can_client_merge_test_global_results() -> bool: return false
func can_client_change_gameplay_tick_from_fps() -> bool: return false
