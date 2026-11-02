class_name M274AuthoritativeKillCreditRewardPersistenceRuntime
extends Node
## M274 fail-closed server replica for kill credit, contribution eligibility, loot/reward authorization and encounter persistence.
signal changed
signal reward_feedback(kind: String, payload: Dictionary)

var session_id := ""
var environment := ""
var instance_id := ""
var encounter_id := ""
var eligibility_revision := -1
var persistence_revision := -1
var settlement_sequence := -1
var server_tick := -1
var encounter_state: Dictionary = {}
var contribution_state: Dictionary = {}
var kill_credit_state: Dictionary = {}
var eligibility_state: Dictionary = {}
var loot_authorization: Dictionary = {}
var reward_authorization: Dictionary = {}
var persistence_state: Dictionary = {}
var last_server_event: Dictionary = {}

const ELIGIBILITY_STATES := ["UNKNOWN", "TRACKING", "ELIGIBLE", "INELIGIBLE", "LOCKED", "SETTLED", "REVOKED"]
const SERVER_EVENTS := ["CONTRIBUTION_UPDATE", "KILL_CREDIT", "ELIGIBILITY_UPDATE", "LOOT_AUTHORIZED", "REWARD_AUTHORIZED", "PERSISTED", "RECOVERED", "SETTLED", "REVOKED"]

func _ready() -> void:
	add_to_group("authoritative_kill_credit_reward_persistence_readiness")

func bind_encounter_orchestration(encounter: M273AuthoritativeEncounterOrchestrationRuntime) -> bool:
	if encounter == null: return false
	var s := encounter.snapshot()
	if str(s.get("source", "")) != "SERVER": return false
	session_id = str(s.get("session_id", "")); environment = str(s.get("environment", "")).to_upper(); instance_id = str(s.get("instance_id", "")); encounter_id = str(s.get("encounter_id", "")); server_tick = int(s.get("server_tick", -1))
	if session_id.is_empty() or environment.is_empty() or instance_id.is_empty() or encounter_id.is_empty(): return false
	changed.emit(); return true

func ingest_server_eligibility_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(snapshot.get("session_id", "")) != session_id or str(snapshot.get("environment", "")).to_upper() != environment or str(snapshot.get("instance_id", "")) != instance_id or str(snapshot.get("encounter_id", "")) != encounter_id: return false
	var er := int(snapshot.get("eligibility_revision", -1)); var pr := int(snapshot.get("persistence_revision", -1)); var seq := int(snapshot.get("settlement_sequence", -1)); var tick := int(snapshot.get("server_tick", -1))
	if er <= eligibility_revision or pr < persistence_revision or seq < settlement_sequence or tick < server_tick: return false
	for key in ["encounter_state", "contribution_state", "kill_credit_state", "eligibility_state", "loot_authorization", "reward_authorization", "persistence_state"]:
		if not snapshot.get(key, {}) is Dictionary: return false
	var state := str((snapshot.get("eligibility_state", {}) as Dictionary).get("state", "UNKNOWN")).to_upper()
	if state not in ELIGIBILITY_STATES: return false
	eligibility_revision = er; persistence_revision = pr; settlement_sequence = seq; server_tick = tick
	encounter_state = (snapshot.get("encounter_state", {}) as Dictionary).duplicate(true)
	contribution_state = (snapshot.get("contribution_state", {}) as Dictionary).duplicate(true)
	kill_credit_state = (snapshot.get("kill_credit_state", {}) as Dictionary).duplicate(true)
	eligibility_state = (snapshot.get("eligibility_state", {}) as Dictionary).duplicate(true)
	loot_authorization = (snapshot.get("loot_authorization", {}) as Dictionary).duplicate(true)
	reward_authorization = (snapshot.get("reward_authorization", {}) as Dictionary).duplicate(true)
	persistence_state = (snapshot.get("persistence_state", {}) as Dictionary).duplicate(true)
	last_server_event = {"kind":"ELIGIBILITY_SNAPSHOT", "server_verified":true, "eligibility_revision":er, "persistence_revision":pr, "settlement_sequence":seq, "server_tick":tick}
	reward_feedback.emit("ELIGIBILITY_CONFIRMED", last_server_event.duplicate(true)); changed.emit(); return true

func ingest_server_reward_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(event.get("session_id", "")) != session_id or str(event.get("environment", "")).to_upper() != environment or str(event.get("instance_id", "")) != instance_id or str(event.get("encounter_id", "")) != encounter_id: return false
	var er := int(event.get("eligibility_revision", -1)); var pr := int(event.get("persistence_revision", -1)); var seq := int(event.get("settlement_sequence", -1)); var tick := int(event.get("server_tick", -1))
	if er <= eligibility_revision or pr < persistence_revision or seq <= settlement_sequence or tick < server_tick: return false
	var kind := str(event.get("event", "")).to_upper(); if kind not in SERVER_EVENTS: return false
	eligibility_revision = er; persistence_revision = pr; settlement_sequence = seq; server_tick = tick
	if event.has("contribution_state") and event.get("contribution_state") is Dictionary: contribution_state = (event.get("contribution_state") as Dictionary).duplicate(true)
	if event.has("kill_credit_state") and event.get("kill_credit_state") is Dictionary: kill_credit_state = (event.get("kill_credit_state") as Dictionary).duplicate(true)
	if event.has("eligibility_state") and event.get("eligibility_state") is Dictionary: eligibility_state = (event.get("eligibility_state") as Dictionary).duplicate(true)
	if event.has("loot_authorization") and event.get("loot_authorization") is Dictionary: loot_authorization = (event.get("loot_authorization") as Dictionary).duplicate(true)
	if event.has("reward_authorization") and event.get("reward_authorization") is Dictionary: reward_authorization = (event.get("reward_authorization") as Dictionary).duplicate(true)
	if event.has("persistence_state") and event.get("persistence_state") is Dictionary: persistence_state = (event.get("persistence_state") as Dictionary).duplicate(true)
	last_server_event = event.duplicate(true); last_server_event["server_verified"] = true
	reward_feedback.emit(kind, last_server_event.duplicate(true)); changed.emit(); return true

func local_reward_presentation_hint() -> Dictionary:
	return {"encounter_id":encounter_id, "eligibility_hint":str(eligibility_state.get("state", "UNKNOWN")), "contribution_hint":contribution_state.duplicate(true), "loot_hint":loot_authorization.duplicate(true), "authority":"LOCAL_PRESENTATION_ONLY", "can_grant":false, "can_settle":false, "can_restore_credit":false}

func invalidate_from_world_resync() -> void:
	contribution_state.clear(); kill_credit_state.clear(); eligibility_state.clear(); loot_authorization.clear(); reward_authorization.clear(); last_server_event = {"kind":"WORLD_RESYNC", "server_verified":false}; changed.emit()

func snapshot() -> Dictionary:
	return {"source":"SERVER" if eligibility_revision >= 0 else "LOCAL_PREVIEW", "session_id":session_id, "environment":environment, "instance_id":instance_id, "encounter_id":encounter_id, "eligibility_revision":eligibility_revision, "persistence_revision":persistence_revision, "settlement_sequence":settlement_sequence, "server_tick":server_tick, "encounter_state":encounter_state.duplicate(true), "contribution_state":contribution_state.duplicate(true), "kill_credit_state":kill_credit_state.duplicate(true), "eligibility_state":eligibility_state.duplicate(true), "loot_authorization":loot_authorization.duplicate(true), "reward_authorization":reward_authorization.duplicate(true), "persistence_state":persistence_state.duplicate(true), "last_server_event":last_server_event.duplicate(true)}

func can_client_assign_kill_credit() -> bool: return false
func can_client_set_contribution() -> bool: return false
func can_client_mark_reward_eligible() -> bool: return false
func can_client_roll_loot() -> bool: return false
func can_client_authorize_loot_drop() -> bool: return false
func can_client_grant_reward() -> bool: return false
func can_client_restore_encounter_credit() -> bool: return false
func can_client_confirm_settlement() -> bool: return false
func can_client_transfer_test_reward_to_global() -> bool: return false
