class_name M285ShipDamageDefeatPresentationRuntime
extends Node
## M285 replica-only ship hit, persistent damage-state and defeat presentation over authoritative combat truth.
signal changed
signal reaction_requested(kind: String, payload: Dictionary)
signal ship_state_changed(entity_id: String, state: Dictionary)
signal confirmed_cleanup_requested(entity_id: String, defeat_sequence_id: String)

var combat_state: M270AuthoritativeCombatStateRuntime
var combat_feedback: M282CombatEventFeedbackRuntime
var projectile_presentation: M283ProjectileSalvoPresentationRuntime
var combat_identity: M284NavalCombatIdentityRuntime
var environment := ""
var state_revision := -1
var presentation_revision := -1
var last_server_tick := -1
var last_event_sequence := -1
var ship_states: Dictionary = {}
var recent_reactions: Array = []
var seen_event_ids: Dictionary = {}
var completed_defeat_sequences: Dictionary = {}

const DAMAGE_STATES := ["INTACT", "LIGHT", "MODERATE", "HEAVY", "CRITICAL", "DEFEATED"]
const SHIELD_STATES := ["NONE", "STABLE", "HIT", "LOW", "BROKEN"]
const REACTION_KINDS := ["SHIELD_HIT", "HULL_HIT", "ARMOR_HIT", "CRITICAL_ENTER", "DEFEAT_CONFIRMED", "SINK_START", "SINK_COMPLETE", "CLEANUP_CONFIRMED"]
const PRESENTATION_FIELDS := ["hit_flash_hook", "hit_stop_hook", "tilt_hook", "knockback_hook", "hull_damage_hook", "shield_hook", "fire_hook", "smoke_hook", "critical_hook", "sinking_hook", "audio_hook", "haptic_hook"]


func _ready() -> void:
	add_to_group("ship_damage_defeat_presentation_readiness")


func bind_authority_layers(state: M270AuthoritativeCombatStateRuntime, feedback: M282CombatEventFeedbackRuntime, projectiles: M283ProjectileSalvoPresentationRuntime, identity: M284NavalCombatIdentityRuntime) -> bool:
	if state == null or feedback == null or projectiles == null or identity == null: return false
	var snapshots := [state.snapshot(), feedback.snapshot(), projectiles.snapshot(), identity.snapshot()]
	var expected_environment := ""
	for snapshot in snapshots:
		if str(snapshot.get("source", "")) != "SERVER": return false
		var candidate := str(snapshot.get("environment", "")).to_upper()
		if candidate.is_empty() or (not expected_environment.is_empty() and candidate != expected_environment): return false
		expected_environment = candidate
	combat_state = state
	combat_feedback = feedback
	projectile_presentation = projectiles
	combat_identity = identity
	environment = expected_environment
	last_server_tick = maxi(maxi(int(snapshots[0].get("server_tick", -1)), int(snapshots[1].get("server_tick", -1))), maxi(int(snapshots[2].get("server_tick", -1)), int(snapshots[3].get("server_tick", -1))))
	changed.emit()
	return true


func ingest_server_ship_state_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified or not _authorities_bound(): return false
	if str(snapshot.get("environment", "")).to_upper() != environment: return false
	var revision := int(snapshot.get("state_revision", -1))
	var tick := int(snapshot.get("server_tick", -1))
	if revision <= state_revision or tick < last_server_tick: return false
	var next_states: Dictionary = {}
	for raw in snapshot.get("ships", []) as Array:
		var safe := _sanitize_ship_state(raw as Dictionary)
		var entity_id := str(safe.get("entity_id", ""))
		if not entity_id.is_empty(): next_states[entity_id] = safe
	ship_states = next_states
	state_revision = revision
	last_server_tick = tick
	for entity_id in ship_states:
		var state := (ship_states[entity_id] as Dictionary).duplicate(true)
		ship_state_changed.emit(str(entity_id), state)
		_route_state_to_visual_rig(str(entity_id), state)
	changed.emit()
	return true


func ingest_server_reaction_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified or not _authorities_bound(): return false
	if str(event.get("environment", "")).to_upper() != environment: return false
	var event_id := str(event.get("event_id", ""))
	var kind := str(event.get("kind", "")).to_upper()
	var entity_id := str(event.get("entity_id", ""))
	if event_id.is_empty() or entity_id.is_empty() or kind not in REACTION_KINDS or seen_event_ids.has(event_id): return false
	var revision := int(event.get("presentation_revision", -1))
	var tick := int(event.get("server_tick", -1))
	var sequence := int(event.get("event_sequence", -1))
	if revision <= presentation_revision or tick < last_server_tick or sequence <= last_event_sequence: return false
	var seed_value := int(event.get("presentation_seed", -1))
	if seed_value < 0: return false
	var defeat_sequence_id := str(event.get("defeat_sequence_id", ""))
	if kind in ["DEFEAT_CONFIRMED", "SINK_START", "SINK_COMPLETE", "CLEANUP_CONFIRMED"] and defeat_sequence_id.is_empty(): return false
	if kind in ["SINK_START", "SINK_COMPLETE", "CLEANUP_CONFIRMED"] and not _defeat_is_server_confirmed(entity_id, defeat_sequence_id): return false
	var safe := _sanitize_reaction(event)
	safe["kind"] = kind
	safe["source"] = "SERVER"
	safe["server_verified"] = true
	seen_event_ids[event_id] = true
	presentation_revision = revision
	last_server_tick = tick
	last_event_sequence = sequence
	if kind == "DEFEAT_CONFIRMED": completed_defeat_sequences[defeat_sequence_id] = entity_id
	if kind == "CLEANUP_CONFIRMED":
		ship_states.erase(entity_id)
		recent_reactions = recent_reactions.filter(func(row: Dictionary) -> bool: return str(row.get("entity_id", "")) != entity_id)
		_route_cleanup_to_visual_rig(entity_id)
		confirmed_cleanup_requested.emit(entity_id, defeat_sequence_id)
	else:
		recent_reactions.append(safe)
		_route_reaction_to_visual_rig(entity_id, kind, safe)
	reaction_requested.emit(kind, safe.duplicate(true))
	changed.emit()
	return true


func presentation_view(layout: Dictionary) -> Dictionary:
	if state_revision < 0: return {}
	var compact := bool(layout.get("compact", false))
	var reaction_budget := int(layout.get("ship_reaction_visual_slots", 3 if compact else 6))
	var state_budget := int(layout.get("ship_damage_state_slots", 4 if compact else 8))
	var states: Array = []
	for entity_id in ship_states: states.append((ship_states[entity_id] as Dictionary).duplicate(true))
	states.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _state_priority(str(a.get("damage_state", "INTACT"))) > _state_priority(str(b.get("damage_state", "INTACT"))))
	if states.size() > state_budget: states = states.slice(0, state_budget)
	var reactions := recent_reactions.duplicate(true)
	if reactions.size() > reaction_budget: reactions = reactions.slice(reactions.size() - reaction_budget, reactions.size())
	return {"source":"SERVER", "environment":environment, "state_revision":state_revision, "presentation_revision":presentation_revision, "server_tick":last_server_tick, "ship_states":states, "recent_reactions":reactions, "compact":compact, "persistent_damage_states":true, "defeat_cleanup":"SERVER_CONFIRMED_ONLY", "placeholder_rigs":"REPLACEABLE", "authority":"PRESENTATION_ONLY"}


func local_accessibility_intent(request_id: String, action: String) -> Dictionary:
	var normalized := action.to_upper()
	if request_id.is_empty() or normalized not in ["REDUCE_HIT_MOTION", "RESTORE_HIT_MOTION", "REDUCE_SINKING_MOTION", "RESTORE_SINKING_MOTION", "REDUCE_DAMAGE_VFX", "RESTORE_DAMAGE_VFX"]: return {}
	return {"intent":"M285_" + normalized, "request_id":request_id, "environment":environment, "authority":"CLIENT_PRESENTATION_PREFERENCE_ONLY", "changes_damage":false, "changes_damage_state":false, "changes_defeat":false, "despawns_entity":false}


func invalidate_from_world_resync() -> void:
	ship_states.clear()
	recent_reactions.clear()
	seen_event_ids.clear()
	completed_defeat_sequences.clear()
	state_revision = -1
	presentation_revision = -1
	last_event_sequence = -1
	changed.emit()


func _sanitize_ship_state(row: Dictionary) -> Dictionary:
	var entity_id := str(row.get("entity_id", ""))
	var damage_state := str(row.get("damage_state", "INTACT")).to_upper()
	var shield_state := str(row.get("shield_state", "NONE")).to_upper()
	if entity_id.is_empty() or damage_state not in DAMAGE_STATES or shield_state not in SHIELD_STATES: return {}
	var safe := {"entity_id":entity_id, "entity_kind":str(row.get("entity_kind", "SHIP")).to_upper(), "damage_state":damage_state, "shield_state":shield_state, "hull_ratio":clampf(float(row.get("hull_ratio", 1.0)), 0.0, 1.0), "shield_ratio":clampf(float(row.get("shield_ratio", 0.0)), 0.0, 1.0), "segment_states":row.get("segment_states", {}), "defeated":bool(row.get("defeated", false)), "defeat_sequence_id":str(row.get("defeat_sequence_id", "")), "presentation_seed":int(row.get("presentation_seed", 0)), "source":"SERVER", "server_verified":true}
	for field in PRESENTATION_FIELDS:
		if row.has(field): safe[field] = row[field]
	return safe


func _sanitize_reaction(event: Dictionary) -> Dictionary:
	var safe := {"event_id":str(event.get("event_id", "")), "entity_id":str(event.get("entity_id", "")), "event_sequence":int(event.get("event_sequence", -1)), "server_tick":int(event.get("server_tick", -1)), "presentation_revision":int(event.get("presentation_revision", -1)), "presentation_seed":int(event.get("presentation_seed", -1)), "defeat_sequence_id":str(event.get("defeat_sequence_id", "")), "impact_segment":str(event.get("impact_segment", "")), "impact_material":str(event.get("impact_material", ""))}
	for field in PRESENTATION_FIELDS:
		if event.has(field): safe[field] = event[field]
	return safe


func _matching_visual_rigs(entity_id: String) -> Array[Node]:
	var matches: Array[Node] = []
	for node in get_tree().get_nodes_in_group("m285_ship_damage_visual_rigs"):
		var ship := node.get_parent()
		if str(ship.get_meta("network_entity_id", "")) == entity_id: matches.append(node)
	return matches


func _route_state_to_visual_rig(entity_id: String, state: Dictionary) -> void:
	for node in _matching_visual_rigs(entity_id): (node as M285ShipDamageVisualRig).apply_server_state(state, true)


func _route_reaction_to_visual_rig(entity_id: String, kind: String, event: Dictionary) -> void:
	for node in _matching_visual_rigs(entity_id): (node as M285ShipDamageVisualRig).play_server_reaction(kind, event, true)


func _route_cleanup_to_visual_rig(entity_id: String) -> void:
	for node in _matching_visual_rigs(entity_id): (node as M285ShipDamageVisualRig).confirm_visual_cleanup(true)


func _defeat_is_server_confirmed(entity_id: String, sequence_id: String) -> bool:
	if str(completed_defeat_sequences.get(sequence_id, "")) == entity_id: return true
	var state := ship_states.get(entity_id, {}) as Dictionary
	return bool(state.get("defeated", false)) and str(state.get("defeat_sequence_id", "")) == sequence_id


func _authorities_bound() -> bool: return combat_state != null and combat_feedback != null and projectile_presentation != null and combat_identity != null
func _state_priority(value: String) -> int: return DAMAGE_STATES.find(value)
func snapshot() -> Dictionary: return {"source":"SERVER" if state_revision >= 0 else "LOCAL_PREVIEW", "environment":environment, "state_revision":state_revision, "presentation_revision":presentation_revision, "server_tick":last_server_tick, "ship_count":ship_states.size(), "reaction_count":recent_reactions.size(), "defeat_sequence_count":completed_defeat_sequences.size()}
func can_client_apply_damage_from_reaction() -> bool: return false
func can_client_derive_damage_state_from_health_bar() -> bool: return false
func can_client_confirm_defeat_from_animation() -> bool: return false
func can_client_despawn_from_sinking_vfx() -> bool: return false
func can_client_grant_reward_or_drop_from_defeat() -> bool: return false
func can_client_transfer_test_presentation_to_global() -> bool: return false
