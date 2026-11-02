class_name M258BackupDisasterRecoveryRuntime
extends Node
## M258 read-only recovery posture. Backup/PITR/DR truth is Operations-owned, never client-owned.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}

func _ready() -> void:
	add_to_group("backup_disaster_recovery_readiness")

func ingest_authoritative_snapshot(snapshot: Dictionary, operations_verified: bool) -> bool:
	if not operations_verified: return false
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
		result["source"] = "OPERATIONS"
		result["revision"] = revision
		return result
	return {"source":"LOCAL_PREVIEW","revision":-1,"environment":"LOCAL","backup_health":[],"restore_readiness":{},"disaster_recovery":{},"recovery_incident":{}}

func backup_health_rows() -> Array[Dictionary]: return _ops_rows("backup_health")
func restore_readiness() -> Dictionary: return _ops_dict("restore_readiness")
func disaster_recovery() -> Dictionary: return _ops_dict("disaster_recovery")
func recovery_incident() -> Dictionary: return _ops_dict("recovery_incident")

func _ops_rows(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var snap := snapshot()
	if str(snap.get("source", "")) != "OPERATIONS": return result
	var rows = snap.get(key, [])
	if rows is Array:
		for row in rows:
			if row is Dictionary: result.append((row as Dictionary).duplicate(true))
	return result

func _ops_dict(key: String) -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "OPERATIONS": return {}
	var row = snap.get(key, {})
	return (row as Dictionary).duplicate(true) if row is Dictionary else {}

func can_client_create_production_backup() -> bool: return false
func can_client_verify_backup() -> bool: return false
func can_client_select_restore_point() -> bool: return false
func can_client_execute_restore() -> bool: return false
func can_client_execute_pitr() -> bool: return false
func can_client_change_rpo_rto() -> bool: return false
func can_client_mark_drill_successful() -> bool: return false
func can_client_repair_account_economy() -> bool: return false
func can_client_bypass_recovery_audit() -> bool: return false
func can_client_merge_test_and_global_backup_state() -> bool: return false
