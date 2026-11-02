class_name M275AuthoritativeLootDistributionRuntime
extends Node
## M275 fail-closed server replica for loot-table/drop-pool resolution and group/fleet reward distribution.
signal changed
signal loot_feedback(kind: String, payload: Dictionary)

var session_id := ""
var environment := ""
var instance_id := ""
var encounter_id := ""
var loot_revision := -1
var distribution_revision := -1
var settlement_sequence := -1
var server_tick := -1
var pool_context: Dictionary = {}
var resolved_drop_state: Dictionary = {}
var participant_distribution: Dictionary = {}
var group_distribution: Dictionary = {}
var fleet_distribution: Dictionary = {}
var settlement_authorizations: Dictionary = {}
var last_server_event: Dictionary = {}

const DROP_STATES := ["UNKNOWN", "PENDING", "RESOLVED", "DISTRIBUTED", "SETTLEMENT_PENDING", "SETTLED", "REVOKED"]
const SERVER_EVENTS := ["POOL_SELECTED", "DROP_RESOLVED", "PERSONAL_DISTRIBUTION", "GROUP_DISTRIBUTION", "FLEET_DISTRIBUTION", "SETTLEMENT_AUTHORIZED", "SETTLED", "REVOKED"]

func _ready() -> void:
	add_to_group("authoritative_loot_distribution_readiness")

func bind_reward_eligibility(reward: M274AuthoritativeKillCreditRewardPersistenceRuntime) -> bool:
	if reward == null: return false
	var s := reward.snapshot()
	if str(s.get("source", "")) != "SERVER": return false
	session_id = str(s.get("session_id", "")); environment = str(s.get("environment", "")).to_upper(); instance_id = str(s.get("instance_id", "")); encounter_id = str(s.get("encounter_id", "")); server_tick = int(s.get("server_tick", -1))
	if session_id.is_empty() or environment.is_empty() or instance_id.is_empty() or encounter_id.is_empty(): return false
	changed.emit(); return true

func ingest_server_loot_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(snapshot.get("session_id", "")) != session_id or str(snapshot.get("environment", "")).to_upper() != environment or str(snapshot.get("instance_id", "")) != instance_id or str(snapshot.get("encounter_id", "")) != encounter_id: return false
	var lr := int(snapshot.get("loot_revision", -1)); var dr := int(snapshot.get("distribution_revision", -1)); var seq := int(snapshot.get("settlement_sequence", -1)); var tick := int(snapshot.get("server_tick", -1))
	if lr <= loot_revision or dr < distribution_revision or seq < settlement_sequence or tick < server_tick: return false
	for key in ["pool_context", "resolved_drop_state", "participant_distribution", "group_distribution", "fleet_distribution", "settlement_authorizations"]:
		if not snapshot.get(key, {}) is Dictionary: return false
	var state := str((snapshot.get("resolved_drop_state", {}) as Dictionary).get("state", "UNKNOWN")).to_upper()
	if state not in DROP_STATES: return false
	loot_revision = lr; distribution_revision = dr; settlement_sequence = seq; server_tick = tick
	pool_context = (snapshot.get("pool_context", {}) as Dictionary).duplicate(true)
	resolved_drop_state = (snapshot.get("resolved_drop_state", {}) as Dictionary).duplicate(true)
	participant_distribution = (snapshot.get("participant_distribution", {}) as Dictionary).duplicate(true)
	group_distribution = (snapshot.get("group_distribution", {}) as Dictionary).duplicate(true)
	fleet_distribution = (snapshot.get("fleet_distribution", {}) as Dictionary).duplicate(true)
	settlement_authorizations = (snapshot.get("settlement_authorizations", {}) as Dictionary).duplicate(true)
	last_server_event = {"kind":"LOOT_SNAPSHOT", "server_verified":true, "loot_revision":lr, "distribution_revision":dr, "settlement_sequence":seq, "server_tick":tick}
	loot_feedback.emit("LOOT_CONFIRMED", last_server_event.duplicate(true)); changed.emit(); return true

func ingest_server_loot_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(event.get("session_id", "")) != session_id or str(event.get("environment", "")).to_upper() != environment or str(event.get("instance_id", "")) != instance_id or str(event.get("encounter_id", "")) != encounter_id: return false
	var lr := int(event.get("loot_revision", -1)); var dr := int(event.get("distribution_revision", -1)); var seq := int(event.get("settlement_sequence", -1)); var tick := int(event.get("server_tick", -1))
	if lr <= loot_revision or dr < distribution_revision or seq <= settlement_sequence or tick < server_tick: return false
	var kind := str(event.get("event", "")).to_upper(); if kind not in SERVER_EVENTS: return false
	loot_revision = lr; distribution_revision = dr; settlement_sequence = seq; server_tick = tick
	if event.has("pool_context") and event.get("pool_context") is Dictionary: pool_context = (event.get("pool_context") as Dictionary).duplicate(true)
	if event.has("resolved_drop_state") and event.get("resolved_drop_state") is Dictionary: resolved_drop_state = (event.get("resolved_drop_state") as Dictionary).duplicate(true)
	if event.has("participant_distribution") and event.get("participant_distribution") is Dictionary: participant_distribution = (event.get("participant_distribution") as Dictionary).duplicate(true)
	if event.has("group_distribution") and event.get("group_distribution") is Dictionary: group_distribution = (event.get("group_distribution") as Dictionary).duplicate(true)
	if event.has("fleet_distribution") and event.get("fleet_distribution") is Dictionary: fleet_distribution = (event.get("fleet_distribution") as Dictionary).duplicate(true)
	if event.has("settlement_authorizations") and event.get("settlement_authorizations") is Dictionary: settlement_authorizations = (event.get("settlement_authorizations") as Dictionary).duplicate(true)
	last_server_event = event.duplicate(true); last_server_event["server_verified"] = true
	loot_feedback.emit(kind, last_server_event.duplicate(true)); changed.emit(); return true

func local_loot_presentation_hint() -> Dictionary:
	return {"encounter_id":encounter_id, "drop_state_hint":str(resolved_drop_state.get("state", "UNKNOWN")), "pool_hint":pool_context.duplicate(true), "distribution_hint":participant_distribution.duplicate(true), "authority":"LOCAL_PRESENTATION_ONLY", "can_roll":false, "can_distribute":false, "can_settle":false}

func invalidate_from_world_resync() -> void:
	pool_context.clear(); resolved_drop_state.clear(); participant_distribution.clear(); group_distribution.clear(); fleet_distribution.clear(); settlement_authorizations.clear(); last_server_event = {"kind":"WORLD_RESYNC", "server_verified":false}; changed.emit()

func snapshot() -> Dictionary:
	return {"source":"SERVER" if loot_revision >= 0 else "LOCAL_PREVIEW", "session_id":session_id, "environment":environment, "instance_id":instance_id, "encounter_id":encounter_id, "loot_revision":loot_revision, "distribution_revision":distribution_revision, "settlement_sequence":settlement_sequence, "server_tick":server_tick, "pool_context":pool_context.duplicate(true), "resolved_drop_state":resolved_drop_state.duplicate(true), "participant_distribution":participant_distribution.duplicate(true), "group_distribution":group_distribution.duplicate(true), "fleet_distribution":fleet_distribution.duplicate(true), "settlement_authorizations":settlement_authorizations.duplicate(true), "last_server_event":last_server_event.duplicate(true)}

func can_client_select_loot_pool() -> bool: return false
func can_client_roll_drop() -> bool: return false
func can_client_assign_personal_drop() -> bool: return false
func can_client_split_group_reward() -> bool: return false
func can_client_split_fleet_reward() -> bool: return false
func can_client_override_rarity() -> bool: return false
func can_client_authorize_settlement() -> bool: return false
func can_client_create_reward_instance() -> bool: return false
func can_client_confirm_settlement() -> bool: return false
func can_client_transfer_test_loot_to_global() -> bool: return false
