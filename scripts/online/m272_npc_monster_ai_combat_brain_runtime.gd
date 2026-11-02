class_name M272NpcMonsterAICombatBrainRuntime
extends Node
## M272 server-authoritative NPC / monster / admiral / boss combat-brain replica boundary.
## The server owns AI state transitions, threat resolution, target choice, leash/return and combat decisions.
## Local navigation, telegraphs and intent previews are presentation only and never become AI authority.
signal changed
signal ai_feedback(kind: String, payload: Dictionary)

var session_id := ""
var environment := ""
var instance_id := ""
var brain_entity_id := ""
var brain_spawn_generation := -1
var brain_revision := -1
var decision_sequence := -1
var server_tick := -1
var archetype := ""
var brain_state := "IDLE"
var encounter_id := ""
var current_target: Dictionary = {}
var threat_state: Dictionary = {}
var navigation_state: Dictionary = {}
var combat_intent_state: Dictionary = {}
var leash_state: Dictionary = {}
var phase_state: Dictionary = {}
var last_decision: Dictionary = {}

const ARCHETYPES := ["NPC", "MONSTER", "ADMIRAL", "BOSS"]
const BRAIN_STATES := ["IDLE", "PATROL", "ACQUIRE", "PURSUE", "ATTACK", "REPOSITION", "EVADE", "LEASH", "RETURN", "DISABLED", "DEFEATED"]
const DECISIONS := ["HOLD", "PATROL", "ACQUIRE_TARGET", "PURSUE_TARGET", "ATTACK_TARGET", "REPOSITION", "EVADE", "BREAK_TARGET", "LEASH_RETURN", "RETURN_HOME", "ENTER_PHASE", "DISABLE", "DEFEATED"]

func _ready() -> void:
	add_to_group("npc_monster_ai_combat_brain_readiness")

func bind_targeting(targeting: M271TargetingRelationshipAuthorityRuntime) -> bool:
	if targeting == null: return false
	var s := targeting.snapshot()
	if str(s.get("source", "")) != "SERVER": return false
	session_id = str(s.get("session_id", "")); environment = str(s.get("environment", "")).to_upper(); instance_id = str(s.get("instance_id", "")); server_tick = int(s.get("server_tick", -1))
	if session_id.is_empty() or environment.is_empty() or instance_id.is_empty(): return false
	changed.emit(); return true

func ingest_server_brain_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(snapshot.get("session_id", "")) != session_id or str(snapshot.get("environment", "")).to_upper() != environment or str(snapshot.get("instance_id", "")) != instance_id: return false
	var entity_id := str(snapshot.get("brain_entity_id", "")); var generation := int(snapshot.get("brain_spawn_generation", -1))
	var revision := int(snapshot.get("brain_revision", -1)); var sequence := int(snapshot.get("decision_sequence", -1)); var tick := int(snapshot.get("server_tick", -1))
	var next_archetype := str(snapshot.get("archetype", "")).to_upper(); var next_state := str(snapshot.get("brain_state", "")).to_upper()
	if entity_id.is_empty() or generation < 0 or revision <= brain_revision or sequence < decision_sequence or tick < server_tick: return false
	if next_archetype not in ARCHETYPES or next_state not in BRAIN_STATES: return false
	for key in ["current_target", "threat_state", "navigation_state", "combat_intent_state", "leash_state", "phase_state"]:
		if not snapshot.get(key, {}) is Dictionary: return false
	brain_entity_id = entity_id; brain_spawn_generation = generation; brain_revision = revision; decision_sequence = sequence; server_tick = tick
	archetype = next_archetype; brain_state = next_state; encounter_id = str(snapshot.get("encounter_id", ""))
	current_target = (snapshot.get("current_target", {}) as Dictionary).duplicate(true)
	threat_state = (snapshot.get("threat_state", {}) as Dictionary).duplicate(true)
	navigation_state = (snapshot.get("navigation_state", {}) as Dictionary).duplicate(true)
	combat_intent_state = (snapshot.get("combat_intent_state", {}) as Dictionary).duplicate(true)
	leash_state = (snapshot.get("leash_state", {}) as Dictionary).duplicate(true)
	phase_state = (snapshot.get("phase_state", {}) as Dictionary).duplicate(true)
	last_decision = {"kind":"AI_BRAIN_SNAPSHOT", "server_verified":true, "brain_revision":revision, "decision_sequence":sequence, "server_tick":tick}
	ai_feedback.emit("AI_BRAIN_CONFIRMED", last_decision.duplicate(true)); changed.emit(); return true

func ingest_server_ai_decision(decision: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(decision.get("session_id", "")) != session_id or str(decision.get("environment", "")).to_upper() != environment or str(decision.get("instance_id", "")) != instance_id: return false
	if str(decision.get("brain_entity_id", "")) != brain_entity_id or int(decision.get("brain_spawn_generation", -1)) != brain_spawn_generation: return false
	var revision := int(decision.get("brain_revision", -1)); var sequence := int(decision.get("decision_sequence", -1)); var tick := int(decision.get("server_tick", -1))
	if revision <= brain_revision or sequence <= decision_sequence or tick < server_tick: return false
	var result := str(decision.get("decision", "")).to_upper(); var next_state := str(decision.get("brain_state", brain_state)).to_upper()
	if result not in DECISIONS or next_state not in BRAIN_STATES: return false
	brain_revision = revision; decision_sequence = sequence; server_tick = tick; brain_state = next_state
	if decision.has("current_target") and decision.get("current_target") is Dictionary: current_target = (decision.get("current_target") as Dictionary).duplicate(true)
	if decision.has("threat_state") and decision.get("threat_state") is Dictionary: threat_state = (decision.get("threat_state") as Dictionary).duplicate(true)
	if decision.has("navigation_state") and decision.get("navigation_state") is Dictionary: navigation_state = (decision.get("navigation_state") as Dictionary).duplicate(true)
	if decision.has("combat_intent_state") and decision.get("combat_intent_state") is Dictionary: combat_intent_state = (decision.get("combat_intent_state") as Dictionary).duplicate(true)
	if decision.has("leash_state") and decision.get("leash_state") is Dictionary: leash_state = (decision.get("leash_state") as Dictionary).duplicate(true)
	if decision.has("phase_state") and decision.get("phase_state") is Dictionary: phase_state = (decision.get("phase_state") as Dictionary).duplicate(true)
	if result in ["BREAK_TARGET", "LEASH_RETURN", "RETURN_HOME", "DEFEATED"] and bool(decision.get("clear_target", true)): current_target.clear()
	last_decision = decision.duplicate(true); last_decision["server_verified"] = true
	ai_feedback.emit(result, last_decision.duplicate(true)); changed.emit(); return true

func local_ai_presentation_hint(replica: Dictionary) -> Dictionary:
	# Client may improve encounter readability, but cannot decide aggro, pathing, attacks or phase transitions.
	return {"brain_entity_id":str(replica.get("brain_entity_id", brain_entity_id)), "brain_state_hint":str(replica.get("brain_state", brain_state)), "telegraph_hint":str(replica.get("telegraph_hint", "NONE")), "target_hint":str((replica.get("current_target", {}) as Dictionary).get("entity_id", "")) if replica.get("current_target", {}) is Dictionary else "", "authority":"LOCAL_PRESENTATION_ONLY", "can_commit_ai_decision":false}

func invalidate_from_world_resync() -> void:
	brain_entity_id = ""; brain_spawn_generation = -1; brain_revision = -1; decision_sequence = -1; archetype = ""; brain_state = "IDLE"; encounter_id = ""
	current_target.clear(); threat_state.clear(); navigation_state.clear(); combat_intent_state.clear(); leash_state.clear(); phase_state.clear(); last_decision = {"kind":"WORLD_RESYNC", "server_verified":false}; changed.emit()

func snapshot() -> Dictionary:
	return {"source":"SERVER" if brain_revision >= 0 else "LOCAL_PREVIEW", "session_id":session_id, "environment":environment, "instance_id":instance_id, "brain_entity_id":brain_entity_id, "brain_spawn_generation":brain_spawn_generation, "brain_revision":brain_revision, "decision_sequence":decision_sequence, "server_tick":server_tick, "archetype":archetype, "brain_state":brain_state, "encounter_id":encounter_id, "current_target":current_target.duplicate(true), "threat_state":threat_state.duplicate(true), "navigation_state":navigation_state.duplicate(true), "combat_intent_state":combat_intent_state.duplicate(true), "leash_state":leash_state.duplicate(true), "phase_state":phase_state.duplicate(true), "last_decision":last_decision.duplicate(true)}

func can_client_choose_ai_target() -> bool: return false
func can_client_set_ai_state() -> bool: return false
func can_client_set_threat() -> bool: return false
func can_client_authorize_ai_attack() -> bool: return false
func can_client_override_leash() -> bool: return false
func can_client_force_boss_phase() -> bool: return false
func can_client_confirm_ai_path() -> bool: return false
func can_client_transfer_test_ai_state_to_global() -> bool: return false
