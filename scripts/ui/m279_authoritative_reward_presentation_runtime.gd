class_name M279AuthoritativeRewardPresentationRuntime
extends Node
## M279 presentation-only replica for server-confirmed reward notifications, loot presentation and claim UX state.
signal changed
signal presentation_feedback(kind: String, payload: Dictionary)

var session_id := ""
var environment := ""
var instance_id := ""
var encounter_id := ""
var inbox_revision := -1
var presentation_revision := -1
var notification_sequence := -1
var server_tick := -1
var presentation_state: Dictionary = {}
var notification_state: Dictionary = {}
var badge_state: Dictionary = {}
var claim_ux_state: Dictionary = {}
var encounter_reward_state: Dictionary = {}
var last_server_event: Dictionary = {}

const SERVER_EVENTS := ["PRESENTATION_SNAPSHOT", "REWARD_CONFIRMED", "LOOT_PRESENTED", "BOSS_REWARD_PRESENTED", "ADMIRAL_REWARD_PRESENTED", "INBOX_BADGE_UPDATED", "CLAIM_UX_UPDATED", "PRESENTATION_DISMISSED", "PRESENTATION_RESTORED"]
const PRESENTATION_STATES := ["IDLE", "QUEUED", "PRESENTING", "CONFIRMED", "CLAIMABLE", "DELIVERED", "MAIL_FALLBACK", "RECOVERY_PENDING", "SETTLED", "DISMISSED"]
const CLAIM_UX_STATES := ["NONE", "CLAIMABLE", "QUEUED", "PROCESSING", "BLOCKED_CAPACITY", "MAIL_FALLBACK", "RECOVERY_PENDING", "SETTLED", "EXPIRED", "REVOKED"]

func _ready() -> void:
	add_to_group("authoritative_reward_presentation_readiness")

func bind_reward_inbox(inbox: M278AuthoritativeRewardInboxRuntime) -> bool:
	if inbox == null: return false
	var s := inbox.snapshot()
	if str(s.get("source", "")) != "SERVER": return false
	session_id = str(s.get("session_id", "")); environment = str(s.get("environment", "")).to_upper(); instance_id = str(s.get("instance_id", "")); encounter_id = str(s.get("encounter_id", "")); inbox_revision = int(s.get("inbox_revision", -1)); server_tick = int(s.get("server_tick", -1))
	if session_id.is_empty() or environment.is_empty() or instance_id.is_empty() or encounter_id.is_empty() or inbox_revision < 0: return false
	changed.emit(); return true

func ingest_server_presentation_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified or not _same_scope(snapshot): return false
	var ir := int(snapshot.get("inbox_revision", -1)); var pr := int(snapshot.get("presentation_revision", -1)); var seq := int(snapshot.get("notification_sequence", -1)); var tick := int(snapshot.get("server_tick", -1))
	if ir < inbox_revision or pr <= presentation_revision or seq < notification_sequence or tick < server_tick: return false
	for key in ["presentation_state", "notification_state", "badge_state", "claim_ux_state", "encounter_reward_state"]:
		if not snapshot.get(key, {}) is Dictionary: return false
	if not _valid_presentation(snapshot.get("presentation_state", {}) as Dictionary): return false
	if not _valid_claim_ux(snapshot.get("claim_ux_state", {}) as Dictionary): return false
	inbox_revision = ir; presentation_revision = pr; notification_sequence = seq; server_tick = tick
	presentation_state = (snapshot.get("presentation_state") as Dictionary).duplicate(true); notification_state = (snapshot.get("notification_state") as Dictionary).duplicate(true); badge_state = (snapshot.get("badge_state") as Dictionary).duplicate(true); claim_ux_state = (snapshot.get("claim_ux_state") as Dictionary).duplicate(true); encounter_reward_state = (snapshot.get("encounter_reward_state") as Dictionary).duplicate(true)
	last_server_event = {"event":"PRESENTATION_SNAPSHOT", "server_verified":true, "presentation_revision":pr, "notification_sequence":seq, "server_tick":tick}
	presentation_feedback.emit("PRESENTATION_SNAPSHOT", last_server_event.duplicate(true)); changed.emit(); return true

func ingest_server_presentation_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified or not _same_scope(event): return false
	var ir := int(event.get("inbox_revision", -1)); var pr := int(event.get("presentation_revision", -1)); var seq := int(event.get("notification_sequence", -1)); var tick := int(event.get("server_tick", -1))
	if ir < inbox_revision or pr <= presentation_revision or seq < notification_sequence or tick < server_tick: return false
	var kind := str(event.get("event", "")).to_upper(); if kind not in SERVER_EVENTS: return false
	if event.has("presentation_state") and (not event.get("presentation_state") is Dictionary or not _valid_presentation(event.get("presentation_state") as Dictionary)): return false
	if event.has("claim_ux_state") and (not event.get("claim_ux_state") is Dictionary or not _valid_claim_ux(event.get("claim_ux_state") as Dictionary)): return false
	inbox_revision = ir; presentation_revision = pr; notification_sequence = seq; server_tick = tick
	if event.has("presentation_state"): presentation_state = (event.get("presentation_state") as Dictionary).duplicate(true)
	if event.has("notification_state") and event.get("notification_state") is Dictionary: notification_state = (event.get("notification_state") as Dictionary).duplicate(true)
	if event.has("badge_state") and event.get("badge_state") is Dictionary: badge_state = (event.get("badge_state") as Dictionary).duplicate(true)
	if event.has("claim_ux_state"): claim_ux_state = (event.get("claim_ux_state") as Dictionary).duplicate(true)
	if event.has("encounter_reward_state") and event.get("encounter_reward_state") is Dictionary: encounter_reward_state = (event.get("encounter_reward_state") as Dictionary).duplicate(true)
	last_server_event = event.duplicate(true); last_server_event["server_verified"] = true
	presentation_feedback.emit(kind, last_server_event.duplicate(true)); changed.emit(); return true

func prepare_dismiss_presentation_intent(request_id: String, presentation_id: String) -> Dictionary:
	if request_id.is_empty() or presentation_id.is_empty(): return {}
	return {"intent":"DISMISS_REWARD_PRESENTATION", "request_id":request_id, "presentation_id":presentation_id, "expected_presentation_revision":presentation_revision, "environment":environment, "authority":"CLIENT_PRESENTATION_INTENT_ONLY", "creates_value":false, "claims_reward":false, "settles_reward":false, "changes_badge_authority":false}

func prepare_open_claim_surface_intent(request_id: String, inbox_entry_id: String) -> Dictionary:
	if request_id.is_empty() or inbox_entry_id.is_empty(): return {}
	return {"intent":"OPEN_REWARD_CLAIM_SURFACE", "request_id":request_id, "inbox_entry_id":inbox_entry_id, "expected_inbox_revision":inbox_revision, "environment":environment, "authority":"CLIENT_NAVIGATION_INTENT_ONLY", "creates_value":false, "claims_reward":false, "settles_reward":false}

func _same_scope(payload: Dictionary) -> bool:
	return str(payload.get("session_id", "")) == session_id and str(payload.get("environment", "")).to_upper() == environment and str(payload.get("instance_id", "")) == instance_id and str(payload.get("encounter_id", "")) == encounter_id

func _valid_presentation(state: Dictionary) -> bool:
	if state.is_empty(): return true
	if str(state.get("authority", "SERVER")).to_upper() != "SERVER": return false
	if str(state.get("state", "IDLE")).to_upper() not in PRESENTATION_STATES: return false
	for forbidden in ["client_reward_value", "client_rarity_override", "client_quantity_override", "client_claim_success", "client_settlement_success"]:
		if state.has(forbidden): return false
	return true

func _valid_claim_ux(state: Dictionary) -> bool:
	if state.is_empty(): return true
	if str(state.get("state", "NONE")).to_upper() not in CLAIM_UX_STATES: return false
	if state.has("client_force_claimable") or state.has("client_force_delivered") or state.has("client_badge_count_override"): return false
	return true

func local_presentation_hint() -> Dictionary:
	return {"badge_count_hint":int(badge_state.get("count", 0)), "claim_state_hint":str(claim_ux_state.get("state", "NONE")), "encounter_reward_kind_hint":str(encounter_reward_state.get("kind", "")), "authority":"LOCAL_PRESENTATION_ONLY", "can_animate":true, "can_dismiss_visual":true, "can_open_claim_surface":true, "can_create_reward":false, "can_confirm_claim":false, "can_settle":false}

func invalidate_from_world_resync() -> void:
	presentation_state.clear(); notification_state.clear(); claim_ux_state.clear(); encounter_reward_state.clear(); last_server_event = {"event":"WORLD_RESYNC", "server_verified":false}; changed.emit()

func snapshot() -> Dictionary:
	return {"source":"SERVER" if presentation_revision >= 0 else "LOCAL_PREVIEW", "session_id":session_id, "environment":environment, "instance_id":instance_id, "encounter_id":encounter_id, "inbox_revision":inbox_revision, "presentation_revision":presentation_revision, "notification_sequence":notification_sequence, "server_tick":server_tick, "presentation_state":presentation_state.duplicate(true), "notification_state":notification_state.duplicate(true), "badge_state":badge_state.duplicate(true), "claim_ux_state":claim_ux_state.duplicate(true), "encounter_reward_state":encounter_reward_state.duplicate(true), "last_server_event":last_server_event.duplicate(true)}

func can_client_create_reward_notification() -> bool: return false
func can_client_define_reward_value() -> bool: return false
func can_client_override_rarity_or_quantity() -> bool: return false
func can_client_confirm_claim_success() -> bool: return false
func can_client_set_badge_authoritatively() -> bool: return false
func can_client_mark_delivery_settled() -> bool: return false
func can_client_transfer_test_presentation_to_global() -> bool: return false
