class_name M262LaunchReadinessRuntime
extends Node
## M262 read-only launch-readiness/RC verification replica. Release promotion and waivers remain Operations/pipeline-owned.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}
func _ready() -> void: add_to_group("launch_readiness_gate")
func ingest_authoritative_snapshot(snapshot: Dictionary, operations_verified: bool) -> bool:
	if not operations_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision <= revision: return false
	var environment := str(snapshot.get("environment", "")).to_upper()
	if environment not in ["INTERNAL", "TEST", "GLOBAL"]: return false
	revision = incoming_revision; authoritative_snapshot = snapshot.duplicate(true); changed.emit(); return true
func snapshot() -> Dictionary:
	if not authoritative_snapshot.is_empty():
		var result := authoritative_snapshot.duplicate(true); result["source"] = "RELEASE_OPS"; result["revision"] = revision; return result
	return {"source":"LOCAL_PREVIEW","revision":-1,"environment":"LOCAL","candidate":{},"gate_results":[],"blockers":[],"evidence_summary":{},"decision":{"state":"NOT_EVALUATED"}}
func gate_rows() -> Array[Dictionary]: return _ops_rows("gate_results")
func blocker_rows() -> Array[Dictionary]: return _ops_rows("blockers")
func candidate() -> Dictionary: return _ops_dict("candidate")
func evidence_summary() -> Dictionary: return _ops_dict("evidence_summary")
func decision() -> Dictionary: return _ops_dict("decision")
func _ops_dict(key: String) -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "RELEASE_OPS": return {}
	var row = snap.get(key, {}); return (row as Dictionary).duplicate(true) if row is Dictionary else {}
func _ops_rows(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []; var snap := snapshot()
	if str(snap.get("source", "")) != "RELEASE_OPS": return result
	var rows = snap.get(key, [])
	if rows is Array:
		for row in rows:
			if row is Dictionary: result.append((row as Dictionary).duplicate(true))
	return result
func local_readiness_preview() -> Dictionary: return {"state":"NOT_EVALUATED","authority":"LOCAL_PREVIEW","production_claim":false,"reason":"Echte QA-/Operations-Evidenz erforderlich"}
func can_client_promote_build() -> bool: return false
func can_client_override_blocker() -> bool: return false
func can_client_mark_global_ready() -> bool: return false
func can_client_issue_waiver() -> bool: return false
func can_client_fabricate_gate_evidence() -> bool: return false
func can_client_merge_test_global_evidence() -> bool: return false
func can_client_change_release_identity() -> bool: return false
