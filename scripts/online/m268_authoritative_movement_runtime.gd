class_name M268AuthoritativeMovementRuntime
extends Node
## M268 authoritative movement / prediction / reconciliation boundary.
## Tap-to-Sail is a client intent. Prediction is presentation-only; the server
## owns accepted movement, position, velocity, heading, movement revisions and
## all speed/teleport/route legality verdicts.
signal changed
signal correction_required(kind: String, reason: String)

var session_id := ""
var environment := ""
var instance_id := ""
var network_entity_id := ""
var spawn_generation := -1
var movement_revision := -1
var server_tick := -1
var last_acked_command_sequence := -1
var authoritative_state: Dictionary = {}
var predicted_state: Dictionary = {}
var pending_commands: Array = []
var correction_state: Dictionary = {}

func _ready() -> void:
	add_to_group("authoritative_movement_readiness")

func bind_world_replica(world: M267AuthoritativeWorldTransportRuntime, entity_id: String) -> bool:
	if world == null: return false
	var snap := world.snapshot()
	if str(snap.get("source", "")) != "SERVER": return false
	var entity := world.entity_state(entity_id)
	if entity.is_empty(): return false
	session_id = str(snap.get("session_id", ""))
	environment = str(snap.get("environment", "")).to_upper()
	instance_id = str(snap.get("instance_id", ""))
	network_entity_id = entity_id
	spawn_generation = int(entity.get("spawn_generation", -1))
	if session_id.is_empty() or instance_id.is_empty() or network_entity_id.is_empty() or spawn_generation < 0: return false
	var movement = entity.get("movement", {})
	if movement is Dictionary:
		authoritative_state = (movement as Dictionary).duplicate(true)
		predicted_state = authoritative_state.duplicate(true)
	movement_revision = int(entity.get("movement_revision", movement_revision))
	server_tick = int(snap.get("server_tick", server_tick))
	changed.emit()
	return true

func prepare_tap_to_sail_intent(destination: Vector2, command_sequence: int, request_id: String) -> Dictionary:
	if session_id.is_empty() or network_entity_id.is_empty() or request_id.is_empty() or command_sequence < 0: return {}
	return {
		"operation":"TAP_TO_SAIL",
		"session_id":session_id,"environment":environment,"instance_id":instance_id,
		"network_entity_id":network_entity_id,"spawn_generation":spawn_generation,
		"command_sequence":command_sequence,"request_id":request_id,
		"destination":{"x":destination.x,"y":destination.y},
		"known_movement_revision":movement_revision,"known_server_tick":server_tick,
		"authority":"CLIENT_REQUEST_ONLY","server_verified":false
	}

func apply_local_prediction(intent: Dictionary) -> bool:
	# Prediction can improve responsiveness, but never becomes durable/world truth.
	if str(intent.get("authority", "")) != "CLIENT_REQUEST_ONLY": return false
	if str(intent.get("operation", "")) != "TAP_TO_SAIL": return false
	if str(intent.get("session_id", "")) != session_id or str(intent.get("instance_id", "")) != instance_id: return false
	if str(intent.get("environment", "")).to_upper() != environment: return false
	if str(intent.get("network_entity_id", "")) != network_entity_id: return false
	if int(intent.get("spawn_generation", -1)) != spawn_generation: return false
	var seq := int(intent.get("command_sequence", -1))
	if seq <= last_acked_command_sequence: return false
	for row in pending_commands:
		if int((row as Dictionary).get("command_sequence", -2)) == seq: return false
	var destination = intent.get("destination", {})
	if not (destination is Dictionary): return false
	pending_commands.append(intent.duplicate(true))
	predicted_state["destination"] = (destination as Dictionary).duplicate(true)
	predicted_state["prediction_only"] = true
	predicted_state["pending_command_sequence"] = seq
	changed.emit()
	return true

func ingest_server_movement_verdict(verdict: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(verdict.get("session_id", "")) != session_id: return false
	if str(verdict.get("environment", "")).to_upper() != environment: return false
	if str(verdict.get("instance_id", "")) != instance_id: return false
	if str(verdict.get("network_entity_id", "")) != network_entity_id: return false
	if int(verdict.get("spawn_generation", -1)) != spawn_generation: return false
	var incoming_revision := int(verdict.get("movement_revision", -1))
	var incoming_tick := int(verdict.get("server_tick", -1))
	var ack_sequence := int(verdict.get("ack_command_sequence", -1))
	if incoming_revision <= movement_revision or incoming_tick < server_tick: return false
	if ack_sequence < last_acked_command_sequence: return false
	var accepted = verdict.get("authoritative_state", {})
	if not (accepted is Dictionary): return false
	var correction_kind := str(verdict.get("correction_kind", "NONE")).to_upper()
	if correction_kind not in ["NONE", "SMOOTH", "SNAP", "REJECTED"]: return false
	authoritative_state = (accepted as Dictionary).duplicate(true)
	movement_revision = incoming_revision
	server_tick = incoming_tick
	last_acked_command_sequence = ack_sequence
	var remaining: Array = []
	for raw in pending_commands:
		var command := raw as Dictionary
		if int(command.get("command_sequence", -1)) > ack_sequence: remaining.append(command)
	pending_commands = remaining
	predicted_state = authoritative_state.duplicate(true)
	# Reapply only presentation targets from still-pending commands. Physics/path
	# simulation remains an adapter concern and never changes authoritative_state.
	for raw in pending_commands:
		var command := raw as Dictionary
		predicted_state["destination"] = (command.get("destination", {}) as Dictionary).duplicate(true)
		predicted_state["prediction_only"] = true
		predicted_state["pending_command_sequence"] = int(command.get("command_sequence", -1))
	correction_state = {
		"kind":correction_kind,"reason":str(verdict.get("reason", "")),
		"server_tick":incoming_tick,"movement_revision":incoming_revision,
		"server_verified":true
	}
	if correction_kind != "NONE": correction_required.emit(correction_kind, str(correction_state.get("reason", "")))
	changed.emit()
	return true

func invalidate_from_world_resync() -> void:
	# Any world baseline replacement invalidates local command prediction until a
	# fresh server replica is bound again.
	pending_commands.clear()
	predicted_state.clear()
	correction_state = {"kind":"WORLD_RESYNC","reason":"fresh_world_baseline_required","server_verified":false}
	changed.emit()

func snapshot() -> Dictionary:
	return {
		"source":"SERVER" if not authoritative_state.is_empty() else "LOCAL_PREVIEW",
		"session_id":session_id,"environment":environment,"instance_id":instance_id,
		"network_entity_id":network_entity_id,"spawn_generation":spawn_generation,
		"movement_revision":movement_revision,"server_tick":server_tick,
		"last_acked_command_sequence":last_acked_command_sequence,
		"pending_prediction_count":pending_commands.size(),
		"authoritative_state":authoritative_state.duplicate(true),
		"predicted_state":predicted_state.duplicate(true),"correction":correction_state.duplicate(true)
	}

func can_client_commit_position() -> bool: return false
func can_client_commit_velocity() -> bool: return false
func can_client_commit_heading() -> bool: return false
func can_client_advance_movement_revision() -> bool: return false
func can_client_accept_teleport() -> bool: return false
func can_client_decide_speed_legality() -> bool: return false
func can_client_decide_route_legality() -> bool: return false
func can_client_ack_own_movement_command() -> bool: return false
func can_client_promote_prediction_to_authority() -> bool: return false
func can_client_transfer_test_movement_to_global() -> bool: return false
