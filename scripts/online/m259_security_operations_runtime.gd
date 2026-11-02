class_name M259SecurityOperationsRuntime
extends Node
## M259 read-only security posture. Secrets, permissions and abuse enforcement stay server/Operations authoritative.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}

func _ready() -> void:
	add_to_group("security_operations_readiness")

func ingest_authoritative_snapshot(snapshot: Dictionary, security_verified: bool) -> bool:
	if not security_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision <= revision: return false
	var environment := str(snapshot.get("environment", "")).to_upper()
	if environment not in ["INTERNAL", "TEST", "GLOBAL"]: return false
	if snapshot.has("secrets") or snapshot.has("credentials") or snapshot.has("tokens"): return false
	revision = incoming_revision
	authoritative_snapshot = snapshot.duplicate(true)
	changed.emit()
	return true

func snapshot() -> Dictionary:
	if not authoritative_snapshot.is_empty():
		var result := authoritative_snapshot.duplicate(true)
		result["source"] = "SECURITY_SERVER"
		result["revision"] = revision
		return result
	return {"source":"LOCAL_PREVIEW","revision":-1,"environment":"LOCAL","account_security":{},"permission_health":{},"anti_abuse_health":{},"security_alerts":[]}

func account_security() -> Dictionary: return _server_dict("account_security")
func permission_health() -> Dictionary: return _server_dict("permission_health")
func anti_abuse_health() -> Dictionary: return _server_dict("anti_abuse_health")
func security_alert_rows() -> Array[Dictionary]: return _server_rows("security_alerts")

func _server_dict(key: String) -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "SECURITY_SERVER": return {}
	var row = snap.get(key, {})
	return (row as Dictionary).duplicate(true) if row is Dictionary else {}

func _server_rows(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var snap := snapshot()
	if str(snap.get("source", "")) != "SECURITY_SERVER": return result
	var rows = snap.get(key, [])
	if rows is Array:
		for row in rows:
			if row is Dictionary: result.append((row as Dictionary).duplicate(true))
	return result

func can_client_grant_staff_role() -> bool: return false
func can_client_elevate_permission() -> bool: return false
func can_client_read_secret_material() -> bool: return false
func can_client_rotate_secret() -> bool: return false
func can_client_revoke_secret() -> bool: return false
func can_client_disable_rate_limit() -> bool: return false
func can_client_confirm_abuse_case() -> bool: return false
func can_client_issue_critical_sanction() -> bool: return false
func can_client_bypass_security_audit() -> bool: return false
func can_client_merge_test_global_security_state() -> bool: return false
func can_client_mark_security_service_healthy() -> bool: return false
