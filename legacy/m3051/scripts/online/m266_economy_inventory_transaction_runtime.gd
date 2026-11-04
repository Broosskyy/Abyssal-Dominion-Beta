class_name M266EconomyInventoryTransactionRuntime
extends Node
## M266 atomic/idempotent economy + inventory transaction boundary. Client can request; server commits value movement.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}
var _environment := ""
var _account_id := ""
var _captain_id := ""
func _ready() -> void: add_to_group("economy_inventory_transaction_readiness")
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
	return {"source":"LOCAL_PREVIEW","revision":-1,"environment":"LOCAL","identity":{},"wallet":{},"inventory":[],"locks":[],"recent_transactions":[],"last_receipt":{}}
func _server_dict(key: String) -> Dictionary:
	var snap := snapshot(); if str(snap.get("source", "")) != "SERVER": return {}
	var row = snap.get(key, {}); return (row as Dictionary).duplicate(true) if row is Dictionary else {}
func _server_rows(key: String) -> Array:
	var snap := snapshot(); if str(snap.get("source", "")) != "SERVER": return []
	var rows = snap.get(key, []); return (rows as Array).duplicate(true) if rows is Array else []
func wallet_state() -> Dictionary: return _server_dict("wallet")
func inventory_rows() -> Array: return _server_rows("inventory")
func lock_rows() -> Array: return _server_rows("locks")
func recent_transactions() -> Array: return _server_rows("recent_transactions")
func last_receipt() -> Dictionary: return _server_dict("last_receipt")
func prepare_transaction_intent(domain: String, operation: String, expected_revision: int, request_id: String, transaction_id: String, idempotency_key: String, inputs: Dictionary = {}, outputs_expected: Dictionary = {}) -> Dictionary:
	return {"domain":domain,"operation":operation,"expected_revision":expected_revision,"request_id":request_id,"transaction_id":transaction_id,"idempotency_key":idempotency_key,"inputs":inputs.duplicate(true),"outputs_expected":outputs_expected.duplicate(true),"authority":"CLIENT_REQUEST_ONLY","committed":false,"receipt_id":"","server_revision":-1}
func can_client_commit_transaction() -> bool: return false
func can_client_set_wallet_balance() -> bool: return false
func can_client_create_inventory_instance() -> bool: return false
func can_client_destroy_inventory_instance() -> bool: return false
func can_client_settle_loot_reward() -> bool: return false
func can_client_settle_shop_trade() -> bool: return false
func can_client_settle_crafting_salvage() -> bool: return false
func can_client_settle_bazaar_transfer() -> bool: return false
func can_client_unlock_transaction_lock() -> bool: return false
func can_client_generate_server_receipt() -> bool: return false
func can_client_override_revision_conflict() -> bool: return false
func can_client_transfer_test_value_to_global() -> bool: return false
