class_name M287ShipMotionIdentityRuntime
extends Node
## Server-confirmed motion presentation over M268. Never movement or navigation authority.
signal changed
signal motion_state_changed(entity_id: String, state: Dictionary)
signal motion_event_requested(entity_id: String, kind: String, payload: Dictionary)

const MOTION_STATES := ["ANCHORED", "IDLE", "ACCELERATING", "CRUISE", "TURNING", "BRAKING", "DRIFTING", "CORRECTING"]
const PROFILE_IDS := ["LIGHT", "BALANCED", "HEAVY", "ADMIRAL", "ABYSSAL"]
const EVENT_KINDS := ["ANCHOR_SETTLE", "ACCELERATION_START", "TURN_ENTER", "BRAKE_START", "DRIFT_ENTER", "CORRECTION_PRESENTATION"]

var authoritative_movement: M268AuthoritativeMovementRuntime
var environment := ""
var motion_revision := -1
var event_revision := -1
var last_server_tick := -1
var last_event_sequence := -1
var entity_states: Dictionary = {}
var seen_event_ids: Dictionary = {}
var recent_events: Array = []


func _ready() -> void:
	add_to_group("ship_motion_identity_readiness")


func bind_authoritative_movement(runtime: M268AuthoritativeMovementRuntime) -> bool:
	if runtime == null: return false
	var source := runtime.snapshot()
	if str(source.get("source", "")) != "SERVER": return false
	var candidate := str(source.get("environment", "")).to_upper()
	if candidate.is_empty(): return false
	authoritative_movement = runtime
	environment = candidate
	last_server_tick = int(source.get("server_tick", -1))
	changed.emit()
	return true


func ingest_server_motion_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified or authoritative_movement == null: return false
	if str(snapshot.get("source", "")) != "SERVER" or str(snapshot.get("environment", "")).to_upper() != environment: return false
	var revision := int(snapshot.get("motion_revision", -1))
	var tick := int(snapshot.get("server_tick", -1))
	if revision <= motion_revision or tick < last_server_tick: return false
	var next_states: Dictionary = {}
	for raw in snapshot.get("entities", []) as Array:
		var safe := _sanitize_motion_state(raw as Dictionary)
		var entity_id := str(safe.get("entity_id", ""))
		if not entity_id.is_empty(): next_states[entity_id] = safe
	entity_states = next_states
	motion_revision = revision
	last_server_tick = tick
	for entity_id in entity_states:
		var state := (entity_states[entity_id] as Dictionary).duplicate(true)
		_route_state_to_rig(str(entity_id), state)
		motion_state_changed.emit(str(entity_id), state)
	changed.emit()
	return true


func ingest_server_motion_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified or authoritative_movement == null: return false
	if str(event.get("source", "")) != "SERVER" or str(event.get("environment", "")).to_upper() != environment: return false
	var event_id := str(event.get("event_id", ""))
	var entity_id := str(event.get("entity_id", ""))
	var kind := str(event.get("kind", "")).to_upper()
	if event_id.is_empty() or entity_id.is_empty() or kind not in EVENT_KINDS or seen_event_ids.has(event_id): return false
	var revision := int(event.get("event_revision", -1))
	var sequence := int(event.get("event_sequence", -1))
	var tick := int(event.get("server_tick", -1))
	var seed_value := int(event.get("presentation_seed", -1))
	if revision <= event_revision or sequence <= last_event_sequence or tick < last_server_tick or seed_value < 0: return false
	var safe := _sanitize_motion_event(event)
	safe["kind"] = kind
	safe["source"] = "SERVER"
	safe["server_verified"] = true
	seen_event_ids[event_id] = true
	event_revision = revision
	last_event_sequence = sequence
	last_server_tick = tick
	recent_events.append(safe)
	if recent_events.size() > 20: recent_events.pop_front()
	_route_event_to_rig(entity_id, kind, safe)
	motion_event_requested.emit(entity_id, kind, safe.duplicate(true))
	changed.emit()
	return true


func presentation_view(layout: Dictionary) -> Dictionary:
	if motion_revision < 0: return {}
	var compact := bool(layout.get("compact", false))
	var state_budget := int(layout.get("m287_motion_state_slots", 4 if compact else 8))
	var event_budget := int(layout.get("m287_motion_event_slots", 2 if compact else 4))
	var states: Array = []
	for entity_id in entity_states: states.append((entity_states[entity_id] as Dictionary).duplicate(true))
	states.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _motion_priority(str(a.get("motion_state", "IDLE"))) > _motion_priority(str(b.get("motion_state", "IDLE"))))
	if states.size() > state_budget: states = states.slice(0, state_budget)
	var events := recent_events.duplicate(true)
	if events.size() > event_budget: events = events.slice(events.size() - event_budget, events.size())
	return {"source":"SERVER", "environment":environment, "motion_revision":motion_revision, "event_revision":event_revision, "server_tick":last_server_tick, "entity_states":states, "recent_events":events, "motion_profiles":PROFILE_IDS.duplicate(), "tap_to_sail_unchanged":true, "camera_joystick":"CAMERA_ONLY", "placeholder_rigs":"REPLACEABLE", "authority":"PRESENTATION_ONLY", "compact":compact}


func local_accessibility_intent(request_id: String, action: String) -> Dictionary:
	var normalized := action.to_upper()
	if request_id.is_empty() or normalized not in ["REDUCE_WAKE", "RESTORE_WAKE", "REDUCE_SAIL_MOTION", "RESTORE_SAIL_MOTION", "REDUCE_CORRECTION_FEEDBACK", "RESTORE_CORRECTION_FEEDBACK"]: return {}
	return {"intent":"M287_" + normalized, "request_id":request_id, "environment":environment, "authority":"CLIENT_PRESENTATION_PREFERENCE_ONLY", "changes_speed":false, "changes_heading":false, "changes_route":false, "changes_collision":false}


func invalidate_from_world_resync() -> void:
	entity_states.clear()
	seen_event_ids.clear()
	recent_events.clear()
	motion_revision = -1
	event_revision = -1
	last_event_sequence = -1
	for node in get_tree().get_nodes_in_group("m287_ship_motion_visual_rigs"):
		(node as M287ShipMotionVisualRig).release_server_mode_after_resync(true)
	changed.emit()


func _sanitize_motion_state(row: Dictionary) -> Dictionary:
	var entity_id := str(row.get("entity_id", ""))
	var state := str(row.get("motion_state", "")).to_upper()
	var profile := str(row.get("motion_profile_id", "BALANCED")).to_upper()
	if entity_id.is_empty() or state not in MOTION_STATES or profile not in PROFILE_IDS: return {}
	return {"entity_id":entity_id, "entity_kind":str(row.get("entity_kind", "SHIP")).to_upper(), "motion_state":state, "motion_profile_id":profile, "speed_ratio":clampf(float(row.get("speed_ratio", 0.0)), 0.0, 1.25), "turn_ratio":clampf(float(row.get("turn_ratio", 0.0)), -1.0, 1.0), "presentation_seed":maxi(0, int(row.get("presentation_seed", 0))), "wake_profile_id":str(row.get("wake_profile_id", "")), "sail_profile_id":str(row.get("sail_profile_id", "")), "source":"SERVER", "server_verified":true}


func _sanitize_motion_event(event: Dictionary) -> Dictionary:
	return {"event_id":str(event.get("event_id", "")), "entity_id":str(event.get("entity_id", "")), "event_sequence":int(event.get("event_sequence", -1)), "event_revision":int(event.get("event_revision", -1)), "server_tick":int(event.get("server_tick", -1)), "presentation_seed":int(event.get("presentation_seed", -1)), "wake_hook":str(event.get("wake_hook", "")), "sail_hook":str(event.get("sail_hook", "")), "audio_hook":str(event.get("audio_hook", "")), "motion_hook":str(event.get("motion_hook", "")), "correction_kind":str(event.get("correction_kind", "NONE")).to_upper()}


func _matching_rigs(entity_id: String) -> Array[Node]:
	var matches: Array[Node] = []
	for node in get_tree().get_nodes_in_group("m287_ship_motion_visual_rigs"):
		var ship := node.get_parent()
		if str(ship.get_meta("network_entity_id", "")) == entity_id: matches.append(node)
	return matches


func _route_state_to_rig(entity_id: String, state: Dictionary) -> void:
	for node in _matching_rigs(entity_id): (node as M287ShipMotionVisualRig).apply_server_motion_state(state, true)


func _route_event_to_rig(entity_id: String, kind: String, event: Dictionary) -> void:
	for node in _matching_rigs(entity_id): (node as M287ShipMotionVisualRig).play_server_motion_event(kind, event, true)


func _motion_priority(state: String) -> int:
	return {"CORRECTING":8, "BRAKING":7, "TURNING":6, "ACCELERATING":5, "DRIFTING":4, "CRUISE":3, "ANCHORED":2, "IDLE":1}.get(state, 0)


func snapshot() -> Dictionary:
	return {"source":"SERVER" if motion_revision >= 0 else "LOCAL_PREVIEW", "environment":environment, "motion_revision":motion_revision, "event_revision":event_revision, "server_tick":last_server_tick, "entity_count":entity_states.size(), "event_count":recent_events.size()}


func can_client_commit_position() -> bool: return false
func can_client_commit_velocity() -> bool: return false
func can_client_commit_heading() -> bool: return false
func can_client_decide_speed_or_route() -> bool: return false
func can_client_turn_camera_input_into_ship_input() -> bool: return false
func can_client_promote_motion_vfx_to_authority() -> bool: return false
func can_client_transfer_test_motion_to_global() -> bool: return false
