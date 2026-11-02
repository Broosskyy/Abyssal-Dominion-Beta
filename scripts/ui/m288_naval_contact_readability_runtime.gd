class_name M288NavalContactReadabilityRuntime
extends Node
## Server-confirmed contact presentation over M271 targeting/relationship truth.
signal changed
signal contact_state_changed(entity_id: String, state: Dictionary)
signal contact_event_requested(entity_id: String, kind: String, payload: Dictionary)

const CONTACT_CLASSES := ["PLAYER", "FLEET_ALLY", "FRIENDLY", "NEUTRAL", "HOSTILE", "ELITE", "ADMIRAL", "MONSTER", "BOSS"]
const ENGAGEMENT_STATES := ["PASSIVE", "AWARE", "AGGRO", "TARGETED", "IN_RANGE", "OUT_OF_RANGE", "PROTECTED", "DEFEATED"]
const EVENT_KINDS := ["TARGET_ACQUIRED", "TARGET_CLEARED", "THREAT_ENTER", "THREAT_EXIT", "RANGE_ENTER", "RANGE_EXIT", "PROTECTION_CHANGED", "PRIORITY_CHANGED"]

var targeting_authority: M271TargetingRelationshipAuthorityRuntime
var environment := ""
var contact_revision := -1
var event_revision := -1
var last_server_tick := -1
var last_event_sequence := -1
var contact_states: Dictionary = {}
var seen_event_ids: Dictionary = {}
var recent_events: Array = []


func _ready() -> void:
	add_to_group("naval_contact_readability_readiness")


func bind_targeting_authority(runtime: M271TargetingRelationshipAuthorityRuntime) -> bool:
	if runtime == null: return false
	var source := runtime.snapshot()
	if str(source.get("source", "")) != "SERVER": return false
	var candidate := str(source.get("environment", "")).to_upper()
	if candidate.is_empty(): return false
	targeting_authority = runtime
	environment = candidate
	last_server_tick = int(source.get("server_tick", -1))
	changed.emit()
	return true


func ingest_server_contact_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified or targeting_authority == null: return false
	if str(snapshot.get("source", "")) != "SERVER" or str(snapshot.get("environment", "")).to_upper() != environment: return false
	var revision := int(snapshot.get("contact_revision", -1))
	var tick := int(snapshot.get("server_tick", -1))
	if revision <= contact_revision or tick < last_server_tick: return false
	var next_states: Dictionary = {}
	for raw in snapshot.get("contacts", []) as Array:
		var safe := _sanitize_contact(raw as Dictionary)
		var entity_id := str(safe.get("entity_id", ""))
		if not entity_id.is_empty(): next_states[entity_id] = safe
	contact_states = next_states
	contact_revision = revision
	last_server_tick = tick
	for entity_id in contact_states:
		var state := (contact_states[entity_id] as Dictionary).duplicate(true)
		_route_state_to_rig(str(entity_id), state)
		contact_state_changed.emit(str(entity_id), state)
	changed.emit()
	return true


func ingest_server_contact_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified or targeting_authority == null: return false
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
	var safe := _sanitize_event(event)
	safe["kind"] = kind
	safe["source"] = "SERVER"
	safe["server_verified"] = true
	seen_event_ids[event_id] = true
	event_revision = revision
	last_event_sequence = sequence
	last_server_tick = tick
	recent_events.append(safe)
	if recent_events.size() > 24: recent_events.pop_front()
	_route_event_to_rig(entity_id, kind, safe)
	contact_event_requested.emit(entity_id, kind, safe.duplicate(true))
	changed.emit()
	return true


func presentation_view(layout: Dictionary) -> Dictionary:
	if contact_revision < 0: return {}
	var compact := bool(layout.get("compact", false))
	var contact_budget := int(layout.get("m288_contact_slots", 4 if compact else 9))
	var event_budget := int(layout.get("m288_contact_event_slots", 2 if compact else 4))
	var contacts: Array = []
	for entity_id in contact_states: contacts.append((contact_states[entity_id] as Dictionary).duplicate(true))
	contacts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _contact_priority(a) > _contact_priority(b))
	if contacts.size() > contact_budget: contacts = contacts.slice(0, contact_budget)
	var events := recent_events.duplicate(true)
	if events.size() > event_budget: events = events.slice(events.size() - event_budget, events.size())
	return {"source":"SERVER", "environment":environment, "contact_revision":contact_revision, "event_revision":event_revision, "server_tick":last_server_tick, "contacts":contacts, "recent_events":events, "world_overlays":"REPLACEABLE", "offscreen_guidance":"PRIORITY_BUDGETED", "ship_model_strategy":"SINGLE_COMPLETE_3D_MODEL", "authority":"PRESENTATION_ONLY", "compact":compact}


func local_accessibility_intent(request_id: String, action: String) -> Dictionary:
	var normalized := action.to_upper()
	if request_id.is_empty() or normalized not in ["REDUCE_THREAT_PULSE", "RESTORE_THREAT_PULSE", "REDUCE_OFFSCREEN_CUES", "RESTORE_OFFSCREEN_CUES", "HIGH_CONTRAST_RELATIONS", "STANDARD_RELATION_CONTRAST"]: return {}
	return {"intent":"M288_" + normalized, "request_id":request_id, "environment":environment, "authority":"CLIENT_PRESENTATION_PREFERENCE_ONLY", "changes_target":false, "changes_range":false, "changes_aggro":false, "changes_protection":false}


func invalidate_from_world_resync() -> void:
	contact_states.clear()
	seen_event_ids.clear()
	recent_events.clear()
	contact_revision = -1
	event_revision = -1
	last_event_sequence = -1
	for node in get_tree().get_nodes_in_group("m288_naval_contact_visual_rigs"):
		(node as M288NavalContactVisualRig).clear_server_contact(true)
	changed.emit()


func _sanitize_contact(row: Dictionary) -> Dictionary:
	var entity_id := str(row.get("entity_id", ""))
	var contact_class := str(row.get("contact_class", "NEUTRAL")).to_upper()
	var engagement := str(row.get("engagement_state", "PASSIVE")).to_upper()
	if entity_id.is_empty() or contact_class not in CONTACT_CLASSES or engagement not in ENGAGEMENT_STATES: return {}
	return {"entity_id":entity_id, "entity_kind":str(row.get("entity_kind", "SHIP")).to_upper(), "contact_class":contact_class, "engagement_state":engagement, "selected":bool(row.get("selected", false)), "attack_legal":bool(row.get("attack_legal", false)), "protected":bool(row.get("protected", false)), "in_range":bool(row.get("in_range", false)), "offscreen":bool(row.get("offscreen", false)), "edge_x":clampf(float(row.get("edge_x", 0.0)), -1.0, 1.0), "edge_y":clampf(float(row.get("edge_y", -1.0)), -1.0, 1.0), "priority":clampi(int(row.get("priority", 0)), 0, 100), "distance_m":maxf(0.0, float(row.get("distance_m", 0.0))), "presentation_seed":maxi(0, int(row.get("presentation_seed", 0))), "profile_id":str(row.get("profile_id", contact_class.to_lower())), "source":"SERVER", "server_verified":true}


func _sanitize_event(event: Dictionary) -> Dictionary:
	return {"event_id":str(event.get("event_id", "")), "entity_id":str(event.get("entity_id", "")), "event_sequence":int(event.get("event_sequence", -1)), "event_revision":int(event.get("event_revision", -1)), "server_tick":int(event.get("server_tick", -1)), "presentation_seed":int(event.get("presentation_seed", -1)), "contact_class":str(event.get("contact_class", "NEUTRAL")).to_upper(), "engagement_state":str(event.get("engagement_state", "PASSIVE")).to_upper(), "vfx_hook":str(event.get("vfx_hook", "")), "audio_hook":str(event.get("audio_hook", "")), "haptic_hook":str(event.get("haptic_hook", ""))}


func _matching_rigs(entity_id: String) -> Array[Node]:
	var matches: Array[Node] = []
	for node in get_tree().get_nodes_in_group("m288_naval_contact_visual_rigs"):
		var entity := node.get_parent()
		if str(entity.get_meta("network_entity_id", "")) == entity_id: matches.append(node)
	return matches


func _route_state_to_rig(entity_id: String, state: Dictionary) -> void:
	for node in _matching_rigs(entity_id): (node as M288NavalContactVisualRig).apply_server_contact(state, true)


func _route_event_to_rig(entity_id: String, kind: String, event: Dictionary) -> void:
	for node in _matching_rigs(entity_id): (node as M288NavalContactVisualRig).play_server_contact_event(kind, event, true)


func _contact_priority(row: Dictionary) -> int:
	var score := int(row.get("priority", 0))
	if bool(row.get("selected", false)): score += 1000
	if str(row.get("contact_class", "")) in ["BOSS", "ADMIRAL", "MONSTER", "ELITE"]: score += 300
	if str(row.get("engagement_state", "")) in ["AGGRO", "TARGETED", "IN_RANGE"]: score += 180
	if bool(row.get("offscreen", false)): score += 40
	return score


func snapshot() -> Dictionary:
	return {"source":"SERVER" if contact_revision >= 0 else "LOCAL_PREVIEW", "environment":environment, "contact_revision":contact_revision, "event_revision":event_revision, "server_tick":last_server_tick, "contact_count":contact_states.size(), "event_count":recent_events.size()}


func can_client_select_or_clear_target() -> bool: return false
func can_client_decide_attack_legality() -> bool: return false
func can_client_decide_range() -> bool: return false
func can_client_set_relationship_or_aggro() -> bool: return false
func can_client_remove_protection() -> bool: return false
func can_client_promote_contact_vfx_to_authority() -> bool: return false
func can_client_transfer_test_contacts_to_global() -> bool: return false
