class_name M260CapacityPerformanceRuntime
extends Node
## M260 read-only capacity/performance readiness. Production scale and destructive test authority stay Operations/QA-owned.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}

func _ready() -> void:
	add_to_group("capacity_performance_readiness")

func ingest_authoritative_snapshot(snapshot: Dictionary, operations_verified: bool) -> bool:
	if not operations_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision <= revision: return false
	var environment := str(snapshot.get("environment", "")).to_upper()
	if environment not in ["INTERNAL", "TEST", "GLOBAL"]: return false
	if snapshot.has("autoscaling_write") or snapshot.has("capacity_override") or snapshot.has("server_tick_override"): return false
	revision = incoming_revision
	authoritative_snapshot = snapshot.duplicate(true)
	changed.emit()
	return true

func snapshot() -> Dictionary:
	if not authoritative_snapshot.is_empty():
		var result := authoritative_snapshot.duplicate(true)
		result["source"] = "CAPACITY_OPS"
		result["revision"] = revision
		return result
	return {"source":"LOCAL_PREVIEW","revision":-1,"environment":"LOCAL","capacity_health":{},"performance_health":{},"test_campaigns":[],"bottlenecks":[],"readiness":{}}

func capacity_health() -> Dictionary: return _ops_dict("capacity_health")
func performance_health() -> Dictionary: return _ops_dict("performance_health")
func readiness() -> Dictionary: return _ops_dict("readiness")
func test_campaign_rows() -> Array[Dictionary]: return _ops_rows("test_campaigns")
func bottleneck_rows() -> Array[Dictionary]: return _ops_rows("bottlenecks")

func _ops_dict(key: String) -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "CAPACITY_OPS": return {}
	var row = snap.get(key, {})
	return (row as Dictionary).duplicate(true) if row is Dictionary else {}

func _ops_rows(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var snap := snapshot()
	if str(snap.get("source", "")) != "CAPACITY_OPS": return result
	var rows = snap.get(key, [])
	if rows is Array:
		for row in rows:
			if row is Dictionary: result.append((row as Dictionary).duplicate(true))
	return result

func can_client_start_production_load_test() -> bool: return false
func can_client_start_destructive_global_chaos_test() -> bool: return false
func can_client_change_capacity_limit() -> bool: return false
func can_client_change_autoscaling_threshold() -> bool: return false
func can_client_change_server_tick_rate() -> bool: return false
func can_client_mark_capacity_gate_passed() -> bool: return false
func can_client_fabricate_test_result() -> bool: return false
func can_client_merge_test_global_results() -> bool: return false
func can_client_degrade_gameplay_world_for_platform_capacity() -> bool: return false
