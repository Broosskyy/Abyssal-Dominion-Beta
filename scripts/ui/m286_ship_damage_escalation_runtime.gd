class_name M286ShipDamageEscalationRuntime
extends Node
## M286 segment damage and staged-destruction presentation layered over confirmed M285 state.
signal changed
signal segment_transition_requested(entity_id: String, kind: String, payload: Dictionary)
signal defeat_phase_changed(entity_id: String, phase: String)
signal visual_cleanup_confirmed(entity_id: String, defeat_sequence_id: String)

const SEGMENTS := ["BOW", "PORT_HULL", "STARBOARD_HULL", "DECK", "MAST", "SAILS", "STERN"]
const SEGMENT_STATES := ["INTACT", "DAMAGED", "BREACHED", "DESTROYED"]
const DEFEAT_PHASES := ["NONE", "STAGGER", "FLOODING", "BREAKUP", "SUBMERGED", "CLEANUP_PENDING"]
const TRANSITION_KINDS := ["DECK_BREACH", "MAST_BREAK", "SAIL_TEAR", "BOW_BREACH", "STERN_BREAK", "FLOODING_START", "BREAKUP_START", "SUBMERGED", "WRECK_REVEAL", "VISUAL_CLEANUP_CONFIRMED"]
const SINKING_PROFILES := ["BOW_FIRST", "STERN_FIRST", "BROADSIDE_ROLL", "HEAVY_SETTLE", "ABYSSAL_DISSOLVE"]

var ship_damage_presentation: M285ShipDamageDefeatPresentationRuntime
var environment := ""
var escalation_revision := -1
var transition_revision := -1
var last_server_tick := -1
var last_event_sequence := -1
var entity_states: Dictionary = {}
var seen_event_ids: Dictionary = {}
var transition_feed: Array = []


func _ready() -> void:
	add_to_group("ship_damage_escalation_readiness")


func bind_ship_damage_presentation(runtime: M285ShipDamageDefeatPresentationRuntime) -> bool:
	if runtime == null: return false
	var source := runtime.snapshot()
	if str(source.get("source", "")) != "SERVER": return false
	var candidate := str(source.get("environment", "")).to_upper()
	if candidate.is_empty(): return false
	ship_damage_presentation = runtime
	environment = candidate
	last_server_tick = int(source.get("server_tick", -1))
	changed.emit()
	return true


func ingest_server_escalation_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified or ship_damage_presentation == null: return false
	if str(snapshot.get("source", "")) != "SERVER" or str(snapshot.get("environment", "")).to_upper() != environment: return false
	var revision := int(snapshot.get("escalation_revision", -1))
	var tick := int(snapshot.get("server_tick", -1))
	if revision <= escalation_revision or tick < last_server_tick: return false
	var next_states: Dictionary = {}
	for raw in snapshot.get("entities", []) as Array:
		var safe := _sanitize_entity_state(raw as Dictionary)
		var entity_id := str(safe.get("entity_id", ""))
		if not entity_id.is_empty(): next_states[entity_id] = safe
	entity_states = next_states
	escalation_revision = revision
	last_server_tick = tick
	for entity_id in entity_states:
		_route_state_to_rig(str(entity_id), entity_states[entity_id] as Dictionary)
	changed.emit()
	return true


func ingest_server_transition(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified or ship_damage_presentation == null: return false
	if str(event.get("source", "")) != "SERVER" or str(event.get("environment", "")).to_upper() != environment: return false
	var event_id := str(event.get("event_id", ""))
	var entity_id := str(event.get("entity_id", ""))
	var kind := str(event.get("kind", "")).to_upper()
	if event_id.is_empty() or entity_id.is_empty() or kind not in TRANSITION_KINDS or seen_event_ids.has(event_id): return false
	var revision := int(event.get("transition_revision", -1))
	var sequence := int(event.get("event_sequence", -1))
	var tick := int(event.get("server_tick", -1))
	var seed_value := int(event.get("presentation_seed", -1))
	if revision <= transition_revision or sequence <= last_event_sequence or tick < last_server_tick or seed_value < 0: return false
	var defeat_sequence_id := str(event.get("defeat_sequence_id", ""))
	if kind in ["FLOODING_START", "BREAKUP_START", "SUBMERGED", "WRECK_REVEAL", "VISUAL_CLEANUP_CONFIRMED"] and not _has_confirmed_defeat(entity_id, defeat_sequence_id): return false
	var safe := _sanitize_transition(event)
	safe["kind"] = kind
	safe["source"] = "SERVER"
	safe["server_verified"] = true
	seen_event_ids[event_id] = true
	transition_revision = revision
	last_event_sequence = sequence
	last_server_tick = tick
	if kind == "VISUAL_CLEANUP_CONFIRMED":
		entity_states.erase(entity_id)
		transition_feed = transition_feed.filter(func(row: Dictionary) -> bool: return str(row.get("entity_id", "")) != entity_id)
		_route_cleanup_to_rig(entity_id)
		visual_cleanup_confirmed.emit(entity_id, defeat_sequence_id)
	else:
		transition_feed.append(safe)
		if transition_feed.size() > 24: transition_feed.pop_front()
		_route_transition_to_rig(entity_id, kind, safe)
		var phase := _phase_for_transition(kind)
		if not phase.is_empty(): defeat_phase_changed.emit(entity_id, phase)
	segment_transition_requested.emit(entity_id, kind, safe.duplicate(true))
	changed.emit()
	return true


func presentation_view(layout: Dictionary) -> Dictionary:
	if escalation_revision < 0: return {}
	var compact := bool(layout.get("compact", false))
	var state_budget := int(layout.get("m286_ship_state_slots", 3 if compact else 7))
	var event_budget := int(layout.get("m286_transition_slots", 2 if compact else 5))
	var states: Array = []
	for entity_id in entity_states: states.append((entity_states[entity_id] as Dictionary).duplicate(true))
	states.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _state_priority(a) > _state_priority(b))
	if states.size() > state_budget: states = states.slice(0, state_budget)
	var events := transition_feed.duplicate(true)
	if events.size() > event_budget: events = events.slice(events.size() - event_budget, events.size())
	return {"source":"SERVER", "environment":environment, "escalation_revision":escalation_revision, "transition_revision":transition_revision, "server_tick":last_server_tick, "entity_states":states, "transitions":events, "segment_damage":true, "staged_sinking":true, "placeholder_models":"REPLACEABLE", "authority":"PRESENTATION_ONLY", "compact":compact}


func local_accessibility_intent(request_id: String, action: String) -> Dictionary:
	var normalized := action.to_upper()
	if request_id.is_empty() or normalized not in ["REDUCE_PERSISTENT_SMOKE", "RESTORE_PERSISTENT_SMOKE", "REDUCE_DEBRIS", "RESTORE_DEBRIS", "REDUCE_SINKING_MOTION", "RESTORE_SINKING_MOTION"]: return {}
	return {"intent":"M286_" + normalized, "request_id":request_id, "environment":environment, "authority":"CLIENT_PRESENTATION_PREFERENCE_ONLY", "changes_damage":false, "changes_segment_state":false, "changes_defeat_phase":false}


func invalidate_from_world_resync() -> void:
	entity_states.clear()
	seen_event_ids.clear()
	transition_feed.clear()
	escalation_revision = -1
	transition_revision = -1
	last_event_sequence = -1
	changed.emit()


func _sanitize_entity_state(row: Dictionary) -> Dictionary:
	var entity_id := str(row.get("entity_id", ""))
	var phase := str(row.get("defeat_phase", "NONE")).to_upper()
	var profile := str(row.get("sinking_profile_id", "BOW_FIRST")).to_upper()
	if entity_id.is_empty() or phase not in DEFEAT_PHASES or profile not in SINKING_PROFILES: return {}
	var raw_segments := row.get("segment_states", {}) as Dictionary
	var segments: Dictionary = {}
	for segment in SEGMENTS:
		var state := str(raw_segments.get(segment, "INTACT")).to_upper()
		if state not in SEGMENT_STATES: return {}
		segments[segment] = state
	var sequence_id := str(row.get("defeat_sequence_id", ""))
	if phase != "NONE" and not _has_confirmed_defeat(entity_id, sequence_id): return {}
	return {"entity_id":entity_id, "entity_kind":str(row.get("entity_kind", "SHIP")).to_upper(), "segment_states":segments, "defeat_phase":phase, "defeat_sequence_id":sequence_id, "sinking_profile_id":profile, "presentation_seed":maxi(0, int(row.get("presentation_seed", 0))), "wreck_visual_id":str(row.get("wreck_visual_id", "")), "source":"SERVER", "server_verified":true}


func _sanitize_transition(event: Dictionary) -> Dictionary:
	return {"event_id":str(event.get("event_id", "")), "entity_id":str(event.get("entity_id", "")), "event_sequence":int(event.get("event_sequence", -1)), "transition_revision":int(event.get("transition_revision", -1)), "server_tick":int(event.get("server_tick", -1)), "presentation_seed":int(event.get("presentation_seed", -1)), "defeat_sequence_id":str(event.get("defeat_sequence_id", "")), "segment":str(event.get("segment", "")).to_upper(), "segment_state":str(event.get("segment_state", "")).to_upper(), "sinking_profile_id":str(event.get("sinking_profile_id", "")).to_upper(), "audio_hook":str(event.get("audio_hook", "")), "vfx_hook":str(event.get("vfx_hook", "")), "motion_hook":str(event.get("motion_hook", ""))}


func _matching_rigs(entity_id: String) -> Array[Node]:
	var matches: Array[Node] = []
	for node in get_tree().get_nodes_in_group("m286_ship_damage_overlay_rigs"):
		var ship := node.get_parent()
		if str(ship.get_meta("network_entity_id", "")) == entity_id: matches.append(node)
	return matches


func _route_state_to_rig(entity_id: String, state: Dictionary) -> void:
	for node in _matching_rigs(entity_id): (node as M286ShipDamageOverlayRig).apply_server_escalation(state, true)


func _route_transition_to_rig(entity_id: String, kind: String, event: Dictionary) -> void:
	for node in _matching_rigs(entity_id): (node as M286ShipDamageOverlayRig).play_server_transition(kind, event, true)


func _route_cleanup_to_rig(entity_id: String) -> void:
	for node in _matching_rigs(entity_id): (node as M286ShipDamageOverlayRig).confirm_visual_cleanup(true)


func _has_confirmed_defeat(entity_id: String, sequence_id: String) -> bool:
	if sequence_id.is_empty() or ship_damage_presentation == null: return false
	if str(ship_damage_presentation.completed_defeat_sequences.get(sequence_id, "")) == entity_id: return true
	var state := ship_damage_presentation.ship_states.get(entity_id, {}) as Dictionary
	return bool(state.get("defeated", false)) and str(state.get("defeat_sequence_id", "")) == sequence_id


func _phase_for_transition(kind: String) -> String:
	return {"FLOODING_START":"FLOODING", "BREAKUP_START":"BREAKUP", "SUBMERGED":"SUBMERGED", "WRECK_REVEAL":"CLEANUP_PENDING"}.get(kind, "")


func _state_priority(row: Dictionary) -> int:
	var phase_score := DEFEAT_PHASES.find(str(row.get("defeat_phase", "NONE"))) * 10
	var segment_score := 0
	for state in (row.get("segment_states", {}) as Dictionary).values(): segment_score += maxi(0, SEGMENT_STATES.find(str(state)))
	return phase_score + segment_score


func snapshot() -> Dictionary:
	return {"source":"SERVER" if escalation_revision >= 0 else "LOCAL_PREVIEW", "environment":environment, "escalation_revision":escalation_revision, "transition_revision":transition_revision, "server_tick":last_server_tick, "entity_count":entity_states.size(), "transition_count":transition_feed.size()}


func can_client_derive_segment_damage() -> bool: return false
func can_client_break_mast_or_sails() -> bool: return false
func can_client_choose_sinking_profile() -> bool: return false
func can_client_advance_defeat_phase() -> bool: return false
func can_client_spawn_wreck_or_loot() -> bool: return false
func can_client_cleanup_world_entity() -> bool: return false
