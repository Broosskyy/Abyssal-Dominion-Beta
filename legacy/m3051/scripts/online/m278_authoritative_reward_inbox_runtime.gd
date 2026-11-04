class_name M278AuthoritativeRewardInboxRuntime
extends Node
## M278 fail-closed server replica for reward inbox, claim queue, capacity overflow, expiry and compensation recovery.
signal changed
signal reward_inbox_feedback(kind: String, payload: Dictionary)

var session_id := ""
var environment := ""
var instance_id := ""
var encounter_id := ""
var receipt_revision := -1
var inbox_revision := -1
var queue_revision := -1
var recovery_revision := -1
var settlement_sequence := -1
var server_tick := -1
var inbox_state: Dictionary = {}
var queue_state: Dictionary = {}
var overflow_state: Dictionary = {}
var expiry_state: Dictionary = {}
var compensation_state: Dictionary = {}
var last_server_event: Dictionary = {}

const ENTRY_STATES := ["PENDING", "CLAIMABLE", "QUEUED", "DELIVERING", "OVERFLOW", "MAIL_FALLBACK", "RECOVERY_PENDING", "SETTLED", "EXPIRED", "REVOKED"]
const QUEUE_STATES := ["IDLE", "READY", "PROCESSING", "BLOCKED_CAPACITY", "BLOCKED_DEPENDENCY", "RECOVERY_PENDING"]
const SERVER_EVENTS := ["INBOX_SNAPSHOT", "ENTRY_ADDED", "ENTRY_UPDATED", "CLAIM_QUEUED", "QUEUE_STARTED", "QUEUE_BLOCKED", "OVERFLOW_RECORDED", "MAIL_FALLBACK_QUEUED", "EXPIRY_EVALUATED", "RECOVERY_PENDING", "COMPENSATION_AUTHORIZED", "ENTRY_SETTLED", "ENTRY_REVOKED"]
const REQUIRED_ENTRY_IDENTITY := ["inbox_entry_id", "receipt_id", "transaction_id", "idempotency_key", "beneficiary_id", "reward_bundle_digest"]

func _ready() -> void:
	add_to_group("authoritative_reward_inbox_readiness")

func bind_reward_delivery(delivery: M277AuthoritativeRewardDeliveryRuntime) -> bool:
	if delivery == null: return false
	var s := delivery.snapshot()
	if str(s.get("source", "")) != "SERVER": return false
	session_id = str(s.get("session_id", "")); environment = str(s.get("environment", "")).to_upper(); instance_id = str(s.get("instance_id", "")); encounter_id = str(s.get("encounter_id", "")); receipt_revision = int(s.get("receipt_revision", -1)); settlement_sequence = int(s.get("settlement_sequence", -1)); server_tick = int(s.get("server_tick", -1))
	if session_id.is_empty() or environment.is_empty() or instance_id.is_empty() or encounter_id.is_empty() or receipt_revision < 0: return false
	changed.emit(); return true

func ingest_server_inbox_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified or not _same_scope(snapshot): return false
	var rr := int(snapshot.get("receipt_revision", -1)); var ir := int(snapshot.get("inbox_revision", -1)); var qr := int(snapshot.get("queue_revision", -1)); var rec := int(snapshot.get("recovery_revision", -1)); var seq := int(snapshot.get("settlement_sequence", -1)); var tick := int(snapshot.get("server_tick", -1))
	if rr < receipt_revision or ir <= inbox_revision or qr < queue_revision or rec < recovery_revision or seq < settlement_sequence or tick < server_tick: return false
	for key in ["inbox_state", "queue_state", "overflow_state", "expiry_state", "compensation_state"]:
		if not snapshot.get(key, {}) is Dictionary: return false
	if not _valid_inbox(snapshot.get("inbox_state", {}) as Dictionary): return false
	if not _valid_queue(snapshot.get("queue_state", {}) as Dictionary): return false
	receipt_revision = rr; inbox_revision = ir; queue_revision = qr; recovery_revision = rec; settlement_sequence = seq; server_tick = tick
	inbox_state = (snapshot.get("inbox_state") as Dictionary).duplicate(true); queue_state = (snapshot.get("queue_state") as Dictionary).duplicate(true); overflow_state = (snapshot.get("overflow_state") as Dictionary).duplicate(true); expiry_state = (snapshot.get("expiry_state") as Dictionary).duplicate(true); compensation_state = (snapshot.get("compensation_state") as Dictionary).duplicate(true)
	last_server_event = {"event":"INBOX_SNAPSHOT", "server_verified":true, "inbox_revision":ir, "queue_revision":qr, "server_tick":tick}
	reward_inbox_feedback.emit("INBOX_SNAPSHOT", last_server_event.duplicate(true)); changed.emit(); return true

func ingest_server_inbox_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified or not _same_scope(event): return false
	var rr := int(event.get("receipt_revision", -1)); var ir := int(event.get("inbox_revision", -1)); var qr := int(event.get("queue_revision", -1)); var rec := int(event.get("recovery_revision", -1)); var seq := int(event.get("settlement_sequence", -1)); var tick := int(event.get("server_tick", -1))
	if rr < receipt_revision or ir <= inbox_revision or qr < queue_revision or rec < recovery_revision or seq < settlement_sequence or tick < server_tick: return false
	var kind := str(event.get("event", "")).to_upper(); if kind not in SERVER_EVENTS: return false
	if event.has("inbox_state") and (not event.get("inbox_state") is Dictionary or not _valid_inbox(event.get("inbox_state") as Dictionary)): return false
	if event.has("queue_state") and (not event.get("queue_state") is Dictionary or not _valid_queue(event.get("queue_state") as Dictionary)): return false
	receipt_revision = rr; inbox_revision = ir; queue_revision = qr; recovery_revision = rec; settlement_sequence = seq; server_tick = tick
	if event.has("inbox_state"): inbox_state = (event.get("inbox_state") as Dictionary).duplicate(true)
	if event.has("queue_state"): queue_state = (event.get("queue_state") as Dictionary).duplicate(true)
	if event.has("overflow_state") and event.get("overflow_state") is Dictionary: overflow_state = (event.get("overflow_state") as Dictionary).duplicate(true)
	if event.has("expiry_state") and event.get("expiry_state") is Dictionary: expiry_state = (event.get("expiry_state") as Dictionary).duplicate(true)
	if event.has("compensation_state") and event.get("compensation_state") is Dictionary: compensation_state = (event.get("compensation_state") as Dictionary).duplicate(true)
	last_server_event = event.duplicate(true); last_server_event["server_verified"] = true
	reward_inbox_feedback.emit(kind, last_server_event.duplicate(true)); changed.emit(); return true

func prepare_claim_queue_intent(request_id: String, inbox_entry_id: String) -> Dictionary:
	if request_id.is_empty() or inbox_entry_id.is_empty(): return {}
	return {"intent":"QUEUE_REWARD_CLAIM", "request_id":request_id, "inbox_entry_id":inbox_entry_id, "expected_inbox_revision":inbox_revision, "expected_queue_revision":queue_revision, "environment":environment, "authority":"CLIENT_INTENT_ONLY", "creates_value":false, "changes_expiry":false, "authorizes_compensation":false, "settles_reward":false}

func prepare_inbox_refresh_intent(request_id: String) -> Dictionary:
	if request_id.is_empty(): return {}
	return {"intent":"REFRESH_REWARD_INBOX", "request_id":request_id, "expected_inbox_revision":inbox_revision, "environment":environment, "authority":"CLIENT_INTENT_ONLY", "creates_value":false, "settles_reward":false}

func _same_scope(payload: Dictionary) -> bool:
	return str(payload.get("session_id", "")) == session_id and str(payload.get("environment", "")).to_upper() == environment and str(payload.get("instance_id", "")) == instance_id and str(payload.get("encounter_id", "")) == encounter_id

func _valid_inbox(inbox: Dictionary) -> bool:
	if inbox.is_empty(): return true
	if str(inbox.get("authority", "SERVER")).to_upper() != "SERVER": return false
	var entries = inbox.get("entries", [])
	if not entries is Array: return false
	for raw in entries:
		if not raw is Dictionary: return false
		var entry := raw as Dictionary
		for key in REQUIRED_ENTRY_IDENTITY:
			if str(entry.get(key, "")).is_empty(): return false
		if str(entry.get("state", "PENDING")).to_upper() not in ENTRY_STATES: return false
		if entry.has("client_granted_items") or entry.has("client_granted_currency") or entry.has("client_defined_expiry"): return false
	return true

func _valid_queue(queue: Dictionary) -> bool:
	if queue.is_empty(): return true
	if str(queue.get("state", "IDLE")).to_upper() not in QUEUE_STATES: return false
	if queue.has("client_priority_override") or queue.has("client_capacity_override") or queue.has("client_compensation_override"): return false
	return true

func local_inbox_presentation_hint() -> Dictionary:
	return {"pending_hint":int(inbox_state.get("pending_count", 0)), "queue_state_hint":str(queue_state.get("state", "IDLE")), "overflow_hint":bool(overflow_state.get("has_overflow", false)), "authority":"LOCAL_PRESENTATION_ONLY", "can_queue_claim_intent":true, "can_create_entry":false, "can_change_priority":false, "can_extend_expiry":false, "can_authorize_compensation":false, "can_settle":false}

func invalidate_from_world_resync() -> void:
	queue_state.clear(); overflow_state.clear(); expiry_state.clear(); compensation_state.clear(); last_server_event = {"event":"WORLD_RESYNC", "server_verified":false}; changed.emit()

func snapshot() -> Dictionary:
	return {"source":"SERVER" if inbox_revision >= 0 else "LOCAL_PREVIEW", "session_id":session_id, "environment":environment, "instance_id":instance_id, "encounter_id":encounter_id, "receipt_revision":receipt_revision, "inbox_revision":inbox_revision, "queue_revision":queue_revision, "recovery_revision":recovery_revision, "settlement_sequence":settlement_sequence, "server_tick":server_tick, "inbox_state":inbox_state.duplicate(true), "queue_state":queue_state.duplicate(true), "overflow_state":overflow_state.duplicate(true), "expiry_state":expiry_state.duplicate(true), "compensation_state":compensation_state.duplicate(true), "last_server_event":last_server_event.duplicate(true)}

func can_client_create_inbox_entry() -> bool: return false
func can_client_reorder_authoritative_queue() -> bool: return false
func can_client_override_capacity() -> bool: return false
func can_client_extend_reward_expiry() -> bool: return false
func can_client_mark_expired_reward_claimable() -> bool: return false
func can_client_authorize_compensation() -> bool: return false
func can_client_mint_compensation_value() -> bool: return false
func can_client_force_mail_overflow() -> bool: return false
func can_client_settle_inbox_reward() -> bool: return false
func can_client_transfer_test_inbox_to_global() -> bool: return false
