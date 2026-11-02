class_name M256TelemetryObservabilityRuntime
extends Node
## M256 privacy-safe telemetry/observability boundary.
## Local buffering is diagnostics-only. Production analytics, alerts and enforcement remain server/operations owned.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}
var local_diagnostic_events: Array[Dictionary] = []
const MAX_LOCAL_DIAGNOSTIC_EVENTS := 64
const FORBIDDEN_KEYS := ["password", "auth_token", "refresh_token", "raw_store_receipt", "receipt", "payment_data", "card_number", "private_chat_body", "email"]

func _ready() -> void:
	add_to_group("telemetry_observability_readiness")

func ingest_authoritative_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision < revision: return false
	var environment := str(snapshot.get("environment", ""))
	if environment.is_empty() or environment == "LOCAL_DEVELOPMENT": return false
	revision = incoming_revision
	authoritative_snapshot = snapshot.duplicate(true)
	changed.emit()
	return true

func snapshot() -> Dictionary:
	if not authoritative_snapshot.is_empty():
		var result := authoritative_snapshot.duplicate(true)
		result["source"] = "SERVER"
		result["revision"] = revision
		return result
	return {"source":"LOCAL_PREVIEW","revision":-1,"pipeline_state":"unavailable","health":{},"alerts":[],"metric_groups":[]}

func record_local_diagnostic(event_name: String, context: Dictionary = {}) -> bool:
	# LOCAL-only developer diagnostics. Never used as ownership, reward, moderation or payment authority.
	if event_name.strip_edges().is_empty(): return false
	var clean := _sanitize(context)
	local_diagnostic_events.append({"event_name":event_name,"event_version":1,"context":clean,"authority":"LOCAL_DIAGNOSTIC_ONLY"})
	while local_diagnostic_events.size() > MAX_LOCAL_DIAGNOSTIC_EVENTS: local_diagnostic_events.pop_front()
	changed.emit()
	return true

func diagnostic_summary() -> Dictionary:
	return {"source":"LOCAL_DIAGNOSTIC_ONLY","buffered":local_diagnostic_events.size(),"capacity":MAX_LOCAL_DIAGNOSTIC_EVENTS,"grants_authority":false}

func health_rows() -> Array[Dictionary]: return _server_rows("metric_groups")
func alert_rows() -> Array[Dictionary]: return _server_rows("alerts")

func _server_rows(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER": return result
	var rows = snap.get(key, [])
	if rows is Array:
		for row in rows:
			if row is Dictionary: result.append((row as Dictionary).duplicate(true))
	return result

func _sanitize(value: Variant) -> Variant:
	if value is Dictionary:
		var clean := {}
		for key in value.keys():
			var normalized := str(key).to_lower()
			if normalized in FORBIDDEN_KEYS: continue
			clean[key] = _sanitize(value[key])
		return clean
	if value is Array:
		var clean_array := []
		for entry in value: clean_array.append(_sanitize(entry))
		return clean_array
	return value

func can_client_publish_production_telemetry() -> bool: return false
func can_client_define_retention_policy() -> bool: return false
func can_client_define_alert_thresholds() -> bool: return false
func can_client_mark_service_healthy() -> bool: return false
func can_client_confirm_fraud_or_cheat() -> bool: return false
func can_client_grant_reward_from_analytics() -> bool: return false
func can_client_mutate_balance_from_analytics() -> bool: return false
func can_client_count_test_as_global() -> bool: return false
func can_client_log_sensitive_secrets() -> bool: return false
