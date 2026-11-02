class_name M265PlayerProfileOwnershipRuntime
extends Node
## M265 server-authoritative player profile/ownership replica. LOCAL preview cannot create durable ownership.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}
var _account_id := ""
var _captain_id := ""
var _environment := ""
func _ready() -> void: add_to_group("player_profile_ownership_readiness")
func ingest_authoritative_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision <= revision: return false
	var environment := str(snapshot.get("environment", "")).to_upper()
	if environment not in ["INTERNAL", "TEST", "GLOBAL"]: return false
	var identity = snapshot.get("identity", {})
	if not (identity is Dictionary): return false
	var account_id := str((identity as Dictionary).get("account_id", ""))
	var captain_id := str((identity as Dictionary).get("captain_id", ""))
	if account_id.is_empty() or captain_id.is_empty(): return false
	if not _environment.is_empty() and environment != _environment: return false
	if not _account_id.is_empty() and account_id != _account_id: return false
	if not _captain_id.is_empty() and captain_id != _captain_id: return false
	_environment = environment; _account_id = account_id; _captain_id = captain_id
	revision = incoming_revision; authoritative_snapshot = snapshot.duplicate(true); changed.emit(); return true
func snapshot() -> Dictionary:
	if not authoritative_snapshot.is_empty():
		var result := authoritative_snapshot.duplicate(true); result["source"] = "SERVER"; result["revision"] = revision; return result
	return {"source":"LOCAL_PREVIEW","revision":-1,"environment":"LOCAL","identity":{},"profile":{},"ownership":[],"equipment":{},"wallet":{},"progression":{},"last_commit":{}}
func _server_dict(key: String) -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER": return {}
	var row = snap.get(key, {}); return (row as Dictionary).duplicate(true) if row is Dictionary else {}
func _server_rows(key: String) -> Array:
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER": return []
	var rows = snap.get(key, []); return (rows as Array).duplicate(true) if rows is Array else []
func profile_state() -> Dictionary: return _server_dict("profile")
func ownership_rows() -> Array: return _server_rows("ownership")
func equipment_state() -> Dictionary: return _server_dict("equipment")
func wallet_state() -> Dictionary: return _server_dict("wallet")
func progression_state() -> Dictionary: return _server_dict("progression")
func last_commit() -> Dictionary: return _server_dict("last_commit")
func prepare_profile_transaction(operation: String, expected_profile_revision: int, request_id: String, transaction_id: String, idempotency_key: String, payload: Dictionary = {}) -> Dictionary:
	return {"operation":operation,"expected_profile_revision":expected_profile_revision,"request_id":request_id,"transaction_id":transaction_id,"idempotency_key":idempotency_key,"payload":payload.duplicate(true),"authority":"CLIENT_REQUEST_ONLY","committed":false,"server_revision":-1}
func can_client_grant_ownership() -> bool: return false
func can_client_revoke_ownership() -> bool: return false
func can_client_set_wallet_balance() -> bool: return false
func can_client_set_progression() -> bool: return false
func can_client_confirm_profile_commit() -> bool: return false
func can_client_override_revision_conflict() -> bool: return false
func can_client_equip_unowned_instance() -> bool: return false
func can_client_transfer_test_ownership_to_global() -> bool: return false
