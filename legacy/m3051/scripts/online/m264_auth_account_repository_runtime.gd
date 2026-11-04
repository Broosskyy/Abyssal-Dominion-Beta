class_name M264AuthAccountRepositoryRuntime
extends Node
## M264 verified Auth/Account/Repository boundary. LOCAL never becomes a live account or durable server save.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}
var _verified_account_id := ""
var _verified_captain_id := ""
var _environment := ""
func _ready() -> void: add_to_group("auth_account_repository_readiness")
func ingest_authoritative_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision <= revision: return false
	var environment := str(snapshot.get("environment", "")).to_upper()
	if environment not in ["INTERNAL", "TEST", "GLOBAL"]: return false
	var account := snapshot.get("account", {})
	if not (account is Dictionary): return false
	var account_id := str((account as Dictionary).get("account_id", ""))
	var captain_id := str((account as Dictionary).get("captain_id", ""))
	if account_id.is_empty() or captain_id.is_empty(): return false
	if not _environment.is_empty() and environment != _environment: return false
	if not _verified_account_id.is_empty() and account_id != _verified_account_id: return false
	if not _verified_captain_id.is_empty() and captain_id != _verified_captain_id: return false
	_environment = environment; _verified_account_id = account_id; _verified_captain_id = captain_id
	revision = incoming_revision; authoritative_snapshot = snapshot.duplicate(true); changed.emit(); return true
func snapshot() -> Dictionary:
	if not authoritative_snapshot.is_empty():
		var result := authoritative_snapshot.duplicate(true); result["source"] = "SERVER"; result["revision"] = revision; return result
	return {"source":"LOCAL_PREVIEW","revision":-1,"environment":"LOCAL","auth":{"state":"UNVERIFIED"},"account":{},"repository":{"state":"NOT_CONNECTED"},"last_commit":{}}
func _server_dict(key: String) -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER": return {}
	var row = snap.get(key, {}); return (row as Dictionary).duplicate(true) if row is Dictionary else {}
func auth_state() -> Dictionary: return _server_dict("auth")
func account_state() -> Dictionary: return _server_dict("account")
func repository_state() -> Dictionary: return _server_dict("repository")
func last_commit() -> Dictionary: return _server_dict("last_commit")
func prepare_auth_intent(provider: String, payload: Dictionary = {}) -> Dictionary:
	return {"provider":provider.to_lower(),"payload":payload.duplicate(true),"authority":"CLIENT_AUTH_INTENT_ONLY","server_verified":false,"creates_live_identity":false}
func prepare_repository_request(operation: String, account_id: String, expected_revision: int, request_id: String, transaction_id: String = "") -> Dictionary:
	return {"operation":operation,"account_id":account_id,"expected_revision":expected_revision,"request_id":request_id,"transaction_id":transaction_id,"authority":"CLIENT_REQUEST_ONLY","committed":false,"server_revision":-1}
func can_client_verify_auth() -> bool: return false
func can_client_assign_account_id() -> bool: return false
func can_client_assign_captain_id() -> bool: return false
func can_client_confirm_repository_write() -> bool: return false
func can_client_override_revision_conflict() -> bool: return false
func can_client_transfer_test_profile_to_global() -> bool: return false
func can_client_mutate_server_profile_directly() -> bool: return false
