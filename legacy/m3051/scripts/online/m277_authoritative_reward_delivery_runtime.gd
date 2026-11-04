class_name M277AuthoritativeRewardDeliveryRuntime
extends Node
## M277 fail-closed server replica for reward receipts, claim delivery, mail fallback, recovery and audit state.
signal changed
signal reward_delivery_feedback(kind: String, payload: Dictionary)

var session_id := ""
var environment := ""
var instance_id := ""
var encounter_id := ""
var roll_ledger_revision := -1
var receipt_revision := -1
var delivery_revision := -1
var audit_revision := -1
var settlement_sequence := -1
var server_tick := -1
var receipt_state: Dictionary = {}
var claim_state: Dictionary = {}
var delivery_state: Dictionary = {}
var recovery_state: Dictionary = {}
var audit_state: Dictionary = {}
var last_server_event: Dictionary = {}

const RECEIPT_STATES := ["UNKNOWN", "ISSUED", "CLAIMABLE", "CLAIMING", "DELIVERED", "MAIL_FALLBACK", "RECOVERY_PENDING", "SETTLED", "REVOKED"]
const DELIVERY_CHANNELS := ["NONE", "INVENTORY", "WALLET", "OWNERSHIP", "MAIL", "CLAIM_INBOX", "MIXED"]
const SERVER_EVENTS := ["RECEIPT_ISSUED", "CLAIM_AVAILABLE", "CLAIM_ACCEPTED", "DELIVERY_ATTEMPTED", "DELIVERED", "MAIL_FALLBACK_QUEUED", "RECOVERY_PENDING", "RECOVERED", "SETTLED", "REVOKED", "AUDIT_APPENDED"]
const REQUIRED_RECEIPT_IDENTITY := ["receipt_id", "transaction_id", "idempotency_key", "beneficiary_id", "reward_bundle_digest"]

func _ready() -> void:
	add_to_group("authoritative_reward_delivery_readiness")

func bind_roll_integrity(rolls: M276AuthoritativeLootRollIntegrityRuntime) -> bool:
	if rolls == null: return false
	var s := rolls.snapshot()
	if str(s.get("source", "")) != "SERVER": return false
	session_id = str(s.get("session_id", "")); environment = str(s.get("environment", "")).to_upper(); instance_id = str(s.get("instance_id", "")); encounter_id = str(s.get("encounter_id", "")); roll_ledger_revision = int(s.get("roll_ledger_revision", -1)); settlement_sequence = int(s.get("settlement_sequence", -1)); server_tick = int(s.get("server_tick", -1))
	if session_id.is_empty() or environment.is_empty() or instance_id.is_empty() or encounter_id.is_empty() or roll_ledger_revision < 0: return false
	changed.emit(); return true

func ingest_server_delivery_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if not _same_scope(snapshot): return false
	var rr := int(snapshot.get("roll_ledger_revision", -1)); var rcr := int(snapshot.get("receipt_revision", -1)); var dr := int(snapshot.get("delivery_revision", -1)); var ar := int(snapshot.get("audit_revision", -1)); var seq := int(snapshot.get("settlement_sequence", -1)); var tick := int(snapshot.get("server_tick", -1))
	if rr < roll_ledger_revision or rcr <= receipt_revision or dr < delivery_revision or ar < audit_revision or seq < settlement_sequence or tick < server_tick: return false
	for key in ["receipt_state", "claim_state", "delivery_state", "recovery_state", "audit_state"]:
		if not snapshot.get(key, {}) is Dictionary: return false
	var receipt := snapshot.get("receipt_state", {}) as Dictionary
	if not _valid_receipt(receipt): return false
	if not _valid_delivery(snapshot.get("delivery_state", {}) as Dictionary): return false
	roll_ledger_revision = rr; receipt_revision = rcr; delivery_revision = dr; audit_revision = ar; settlement_sequence = seq; server_tick = tick
	receipt_state = receipt.duplicate(true)
	claim_state = (snapshot.get("claim_state", {}) as Dictionary).duplicate(true)
	delivery_state = (snapshot.get("delivery_state", {}) as Dictionary).duplicate(true)
	recovery_state = (snapshot.get("recovery_state", {}) as Dictionary).duplicate(true)
	audit_state = (snapshot.get("audit_state", {}) as Dictionary).duplicate(true)
	last_server_event = {"kind":"REWARD_DELIVERY_SNAPSHOT", "server_verified":true, "receipt_revision":rcr, "delivery_revision":dr, "audit_revision":ar, "server_tick":tick}
	reward_delivery_feedback.emit("REWARD_DELIVERY_CONFIRMED", last_server_event.duplicate(true)); changed.emit(); return true

func ingest_server_delivery_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if not _same_scope(event): return false
	var rr := int(event.get("roll_ledger_revision", -1)); var rcr := int(event.get("receipt_revision", -1)); var dr := int(event.get("delivery_revision", -1)); var ar := int(event.get("audit_revision", -1)); var seq := int(event.get("settlement_sequence", -1)); var tick := int(event.get("server_tick", -1))
	if rr < roll_ledger_revision or rcr <= receipt_revision or dr < delivery_revision or ar < audit_revision or seq < settlement_sequence or tick < server_tick: return false
	var kind := str(event.get("event", "")).to_upper(); if kind not in SERVER_EVENTS: return false
	if event.has("receipt_state"):
		if not event.get("receipt_state") is Dictionary or not _valid_receipt(event.get("receipt_state") as Dictionary): return false
	if event.has("delivery_state"):
		if not event.get("delivery_state") is Dictionary or not _valid_delivery(event.get("delivery_state") as Dictionary): return false
	roll_ledger_revision = rr; receipt_revision = rcr; delivery_revision = dr; audit_revision = ar; settlement_sequence = seq; server_tick = tick
	if event.has("receipt_state"): receipt_state = (event.get("receipt_state") as Dictionary).duplicate(true)
	if event.has("claim_state") and event.get("claim_state") is Dictionary: claim_state = (event.get("claim_state") as Dictionary).duplicate(true)
	if event.has("delivery_state") and event.get("delivery_state") is Dictionary: delivery_state = (event.get("delivery_state") as Dictionary).duplicate(true)
	if event.has("recovery_state") and event.get("recovery_state") is Dictionary: recovery_state = (event.get("recovery_state") as Dictionary).duplicate(true)
	if event.has("audit_state") and event.get("audit_state") is Dictionary: audit_state = (event.get("audit_state") as Dictionary).duplicate(true)
	last_server_event = event.duplicate(true); last_server_event["server_verified"] = true
	reward_delivery_feedback.emit(kind, last_server_event.duplicate(true)); changed.emit(); return true

func prepare_claim_intent(request_id: String) -> Dictionary:
	var receipt_id := str(receipt_state.get("receipt_id", ""))
	if request_id.is_empty() or receipt_id.is_empty(): return {}
	return {"intent":"CLAIM_REWARD", "request_id":request_id, "receipt_id":receipt_id, "expected_receipt_revision":receipt_revision, "expected_delivery_revision":delivery_revision, "environment":environment, "authority":"CLIENT_INTENT_ONLY", "creates_value":false, "settles_reward":false}

func _same_scope(payload: Dictionary) -> bool:
	return str(payload.get("session_id", "")) == session_id and str(payload.get("environment", "")).to_upper() == environment and str(payload.get("instance_id", "")) == instance_id and str(payload.get("encounter_id", "")) == encounter_id

func _valid_receipt(receipt: Dictionary) -> bool:
	if receipt.is_empty(): return false
	for key in REQUIRED_RECEIPT_IDENTITY:
		if str(receipt.get(key, "")).is_empty(): return false
	var state := str(receipt.get("state", "UNKNOWN")).to_upper()
	if state not in RECEIPT_STATES: return false
	if str(receipt.get("authority", "SERVER")).to_upper() != "SERVER": return false
	return true

func _valid_delivery(delivery: Dictionary) -> bool:
	if delivery.is_empty(): return true
	var channel := str(delivery.get("channel", "NONE")).to_upper()
	if channel not in DELIVERY_CHANNELS: return false
	if delivery.has("client_granted_items") or delivery.has("client_granted_currency") or delivery.has("client_generated_receipt"): return false
	return true

func local_delivery_presentation_hint() -> Dictionary:
	return {"receipt_id":str(receipt_state.get("receipt_id", "")), "state_hint":str(receipt_state.get("state", "UNKNOWN")), "channel_hint":str(delivery_state.get("channel", "NONE")), "authority":"LOCAL_PRESENTATION_ONLY", "can_claim_intent":not str(receipt_state.get("receipt_id", "")).is_empty(), "can_settle":false, "can_create_receipt":false, "can_attach_reward":false, "can_force_mail":false, "can_mark_delivered":false}

func invalidate_from_world_resync() -> void:
	claim_state.clear(); delivery_state.clear(); recovery_state.clear(); audit_state.clear(); last_server_event = {"kind":"WORLD_RESYNC", "server_verified":false}; changed.emit()

func snapshot() -> Dictionary:
	return {"source":"SERVER" if receipt_revision >= 0 else "LOCAL_PREVIEW", "session_id":session_id, "environment":environment, "instance_id":instance_id, "encounter_id":encounter_id, "roll_ledger_revision":roll_ledger_revision, "receipt_revision":receipt_revision, "delivery_revision":delivery_revision, "audit_revision":audit_revision, "settlement_sequence":settlement_sequence, "server_tick":server_tick, "receipt_state":receipt_state.duplicate(true), "claim_state":claim_state.duplicate(true), "delivery_state":delivery_state.duplicate(true), "recovery_state":recovery_state.duplicate(true), "audit_state":audit_state.duplicate(true), "last_server_event":last_server_event.duplicate(true)}

func can_client_generate_reward_receipt() -> bool: return false
func can_client_attach_reward_value() -> bool: return false
func can_client_mark_claim_delivered() -> bool: return false
func can_client_force_mail_fallback() -> bool: return false
func can_client_recover_settled_reward() -> bool: return false
func can_client_append_authoritative_audit() -> bool: return false
func can_client_change_beneficiary() -> bool: return false
func can_client_reopen_settled_receipt() -> bool: return false
func can_client_authorize_settlement() -> bool: return false
func can_client_transfer_test_receipt_to_global() -> bool: return false
