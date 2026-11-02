class_name M273AuthoritativeEncounterOrchestrationRuntime
extends Node
## M273 server-authoritative encounter / spawn / respawn / phase orchestration replica boundary.
## Server owns encounter lifecycle, spawn/despawn legality, waves/adds, reset/respawn and completion.
## Clients only render confirmed encounter telegraphs and world replicas; local encounter previews never commit world state.
signal changed
signal encounter_feedback(kind: String, payload: Dictionary)

var session_id := ""
var environment := ""
var instance_id := ""
var encounter_id := ""
var encounter_revision := -1
var orchestration_sequence := -1
var server_tick := -1
var encounter_kind := ""
var lifecycle_state := "INACTIVE"
var phase_state: Dictionary = {}
var wave_state: Dictionary = {}
var spawn_state: Dictionary = {}
var respawn_state: Dictionary = {}
var reset_state: Dictionary = {}
var completion_state: Dictionary = {}
var reward_handoff: Dictionary = {}
var last_orchestration: Dictionary = {}

const ENCOUNTER_KINDS := ["PATROL_GROUP", "MONSTER_PACK", "ADMIRAL", "BOSS", "EVENT", "BONUSMAP", "QUEST"]
const LIFECYCLE_STATES := ["INACTIVE", "ARMED", "SPAWNING", "ACTIVE", "PHASE_TRANSITION", "WAVE_TRANSITION", "RESETTING", "RESPAWNING", "COMPLETING", "COMPLETED", "CLEANUP", "DISABLED"]
const ORCHESTRATION_EVENTS := ["ARM", "SPAWN_GROUP", "SPAWN_ENTITY", "DESPAWN_ENTITY", "START", "ENTER_PHASE", "START_WAVE", "SPAWN_ADDS", "RESET", "RESPAWN", "DEFEAT", "COMPLETE", "CLEANUP", "DISABLE"]

func _ready() -> void:
	add_to_group("authoritative_encounter_orchestration_readiness")

func bind_ai_brain(ai_brain: M272NpcMonsterAICombatBrainRuntime) -> bool:
	if ai_brain == null: return false
	var s := ai_brain.snapshot()
	if str(s.get("source", "")) != "SERVER": return false
	session_id = str(s.get("session_id", "")); environment = str(s.get("environment", "")).to_upper(); instance_id = str(s.get("instance_id", "")); server_tick = int(s.get("server_tick", -1))
	if session_id.is_empty() or environment.is_empty() or instance_id.is_empty(): return false
	changed.emit(); return true

func ingest_server_encounter_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(snapshot.get("session_id", "")) != session_id or str(snapshot.get("environment", "")).to_upper() != environment or str(snapshot.get("instance_id", "")) != instance_id: return false
	var next_id := str(snapshot.get("encounter_id", "")); var revision := int(snapshot.get("encounter_revision", -1)); var sequence := int(snapshot.get("orchestration_sequence", -1)); var tick := int(snapshot.get("server_tick", -1))
	var next_kind := str(snapshot.get("encounter_kind", "")).to_upper(); var next_state := str(snapshot.get("lifecycle_state", "")).to_upper()
	if next_id.is_empty() or revision <= encounter_revision or sequence < orchestration_sequence or tick < server_tick: return false
	if next_kind not in ENCOUNTER_KINDS or next_state not in LIFECYCLE_STATES: return false
	for key in ["phase_state", "wave_state", "spawn_state", "respawn_state", "reset_state", "completion_state", "reward_handoff"]:
		if not snapshot.get(key, {}) is Dictionary: return false
	encounter_id = next_id; encounter_revision = revision; orchestration_sequence = sequence; server_tick = tick; encounter_kind = next_kind; lifecycle_state = next_state
	phase_state = (snapshot.get("phase_state", {}) as Dictionary).duplicate(true)
	wave_state = (snapshot.get("wave_state", {}) as Dictionary).duplicate(true)
	spawn_state = (snapshot.get("spawn_state", {}) as Dictionary).duplicate(true)
	respawn_state = (snapshot.get("respawn_state", {}) as Dictionary).duplicate(true)
	reset_state = (snapshot.get("reset_state", {}) as Dictionary).duplicate(true)
	completion_state = (snapshot.get("completion_state", {}) as Dictionary).duplicate(true)
	reward_handoff = (snapshot.get("reward_handoff", {}) as Dictionary).duplicate(true)
	last_orchestration = {"kind":"ENCOUNTER_SNAPSHOT", "server_verified":true, "encounter_revision":revision, "orchestration_sequence":sequence, "server_tick":tick}
	encounter_feedback.emit("ENCOUNTER_CONFIRMED", last_orchestration.duplicate(true)); changed.emit(); return true

func ingest_server_orchestration_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(event.get("session_id", "")) != session_id or str(event.get("environment", "")).to_upper() != environment or str(event.get("instance_id", "")) != instance_id: return false
	if str(event.get("encounter_id", "")) != encounter_id: return false
	var revision := int(event.get("encounter_revision", -1)); var sequence := int(event.get("orchestration_sequence", -1)); var tick := int(event.get("server_tick", -1))
	if revision <= encounter_revision or sequence <= orchestration_sequence or tick < server_tick: return false
	var kind := str(event.get("event", "")).to_upper(); var next_state := str(event.get("lifecycle_state", lifecycle_state)).to_upper()
	if kind not in ORCHESTRATION_EVENTS or next_state not in LIFECYCLE_STATES: return false
	encounter_revision = revision; orchestration_sequence = sequence; server_tick = tick; lifecycle_state = next_state
	if event.has("phase_state") and event.get("phase_state") is Dictionary: phase_state = (event.get("phase_state") as Dictionary).duplicate(true)
	if event.has("wave_state") and event.get("wave_state") is Dictionary: wave_state = (event.get("wave_state") as Dictionary).duplicate(true)
	if event.has("spawn_state") and event.get("spawn_state") is Dictionary: spawn_state = (event.get("spawn_state") as Dictionary).duplicate(true)
	if event.has("respawn_state") and event.get("respawn_state") is Dictionary: respawn_state = (event.get("respawn_state") as Dictionary).duplicate(true)
	if event.has("reset_state") and event.get("reset_state") is Dictionary: reset_state = (event.get("reset_state") as Dictionary).duplicate(true)
	if event.has("completion_state") and event.get("completion_state") is Dictionary: completion_state = (event.get("completion_state") as Dictionary).duplicate(true)
	if event.has("reward_handoff") and event.get("reward_handoff") is Dictionary: reward_handoff = (event.get("reward_handoff") as Dictionary).duplicate(true)
	last_orchestration = event.duplicate(true); last_orchestration["server_verified"] = true
	encounter_feedback.emit(kind, last_orchestration.duplicate(true)); changed.emit(); return true

func local_encounter_presentation_hint(replica: Dictionary) -> Dictionary:
	return {"encounter_id":str(replica.get("encounter_id", encounter_id)), "lifecycle_hint":str(replica.get("lifecycle_state", lifecycle_state)), "phase_hint":str((replica.get("phase_state", {}) as Dictionary).get("phase_id", "")) if replica.get("phase_state", {}) is Dictionary else "", "wave_hint":str((replica.get("wave_state", {}) as Dictionary).get("wave_id", "")) if replica.get("wave_state", {}) is Dictionary else "", "telegraph_hint":str(replica.get("telegraph_hint", "NONE")), "authority":"LOCAL_PRESENTATION_ONLY", "can_commit_spawn":false, "can_commit_completion":false}

func invalidate_from_world_resync() -> void:
	encounter_id = ""; encounter_revision = -1; orchestration_sequence = -1; encounter_kind = ""; lifecycle_state = "INACTIVE"
	phase_state.clear(); wave_state.clear(); spawn_state.clear(); respawn_state.clear(); reset_state.clear(); completion_state.clear(); reward_handoff.clear(); last_orchestration = {"kind":"WORLD_RESYNC", "server_verified":false}; changed.emit()

func snapshot() -> Dictionary:
	return {"source":"SERVER" if encounter_revision >= 0 else "LOCAL_PREVIEW", "session_id":session_id, "environment":environment, "instance_id":instance_id, "encounter_id":encounter_id, "encounter_revision":encounter_revision, "orchestration_sequence":orchestration_sequence, "server_tick":server_tick, "encounter_kind":encounter_kind, "lifecycle_state":lifecycle_state, "phase_state":phase_state.duplicate(true), "wave_state":wave_state.duplicate(true), "spawn_state":spawn_state.duplicate(true), "respawn_state":respawn_state.duplicate(true), "reset_state":reset_state.duplicate(true), "completion_state":completion_state.duplicate(true), "reward_handoff":reward_handoff.duplicate(true), "last_orchestration":last_orchestration.duplicate(true)}

func can_client_spawn_encounter_entity() -> bool: return false
func can_client_despawn_encounter_entity() -> bool: return false
func can_client_schedule_respawn() -> bool: return false
func can_client_force_encounter_reset() -> bool: return false
func can_client_start_wave() -> bool: return false
func can_client_force_boss_phase() -> bool: return false
func can_client_confirm_encounter_completion() -> bool: return false
func can_client_grant_encounter_reward() -> bool: return false
func can_client_transfer_test_encounter_to_global() -> bool: return false
