class_name M294SailingObservationRuntime
extends Node
## Local-development route telemetry only. Never steers the ship or certifies M268 movement.
signal changed

const STATES := ["IDLE", "INTENT_ONLY", "MOTION_OBSERVED", "ARRIVAL_OBSERVED", "INTERRUPTED"]
const ARRIVAL_DISTANCE := 1.35 # Same local arrival radius as PlayerShipInput._follow_navigation_target.

var player: ShipMotor
var input: PlayerShipInput
var environment := "LOCAL_DEVELOPMENT"
var state := "IDLE"
var target := Vector3.ZERO
var origin := Vector3.ZERO
var previous_distance := INF
var route_generation := 0
var interruption_reason := ""


func _ready() -> void:
	add_to_group("first_sortie_sailing_observer")
	environment = str(get_tree().root.get_meta("environment_id", "LOCAL_DEVELOPMENT")).to_upper()
	set_process(true)


func configure(player_value: ShipMotor) -> void:
	player = player_value
	input = null
	if player != null: input = player.get_node_or_null("PlayerInput") as PlayerShipInput
	if input != null and not input.navigation_intent_created.is_connected(_on_navigation_intent):
		input.navigation_intent_created.connect(_on_navigation_intent)


func _local_observation_allowed() -> bool:
	return environment == "LOCAL_DEVELOPMENT" and not bool(get_tree().root.get_meta("server_authority_verified", false))


func _on_navigation_intent(world_target: Vector3, intent: String) -> void:
	if not _local_observation_allowed() or player == null: return
	if intent != "water":
		if state in ["INTENT_ONLY", "MOTION_OBSERVED"]: _interrupt("ROUTE_REPLACED")
		return
	if bool(player.get_meta("m225_docked", false)): return
	route_generation += 1
	origin = player.global_position
	target = world_target
	previous_distance = origin.distance_to(target)
	interruption_reason = ""
	state = "INTENT_ONLY"
	changed.emit()


func _process(_delta: float) -> void:
	if state not in ["INTENT_ONLY", "MOTION_OBSERVED"]: return
	if not _local_observation_allowed():
		_interrupt("AUTHORITY_CHANGED")
		return
	if player == null or not is_instance_valid(player) or input == null or not is_instance_valid(input):
		_interrupt("PLAYER_OR_INPUT_GONE")
		return
	var health := player.get_node_or_null("Health") as ShipHealth
	if bool(player.get_meta("m225_docked", false)) or (health != null and health.is_sunk):
		_interrupt("DOCKED_OR_SUNK")
		return
	var distance := player.global_position.distance_to(target)
	if input.has_navigation_target:
		if input.navigation_target.distance_to(target) > 0.01:
			_interrupt("ROUTE_REPLACED")
			return
		if state == "INTENT_ONLY" and player.current_speed > 0.0 and origin.distance_to(player.global_position) > 0.01 and distance < previous_distance:
			state = "MOTION_OBSERVED"
			changed.emit()
		previous_distance = distance
		return
	if state == "MOTION_OBSERVED" and distance <= ARRIVAL_DISTANCE:
		state = "ARRIVAL_OBSERVED"
		changed.emit()
	else:
		_interrupt("NO_ARRIVAL_OBSERVED")


func _interrupt(reason: String) -> void:
	state = "INTERRUPTED"
	interruption_reason = reason
	changed.emit()


func presentation_view() -> Dictionary:
	return {"milestone":"M294", "state":state, "route_generation":route_generation, "interruption_reason":interruption_reason, "source":"LOCAL_DEVELOPMENT" if environment == "LOCAL_DEVELOPMENT" else "NOT_EVALUATED", "server_verified":false, "arrival_is_server_truth":false, "movement_authority":false, "release_approved":false}


func can_set_route_or_move_ship() -> bool: return false
func can_confirm_server_movement_or_arrival() -> bool: return false
func can_mark_native_qa_pass() -> bool: return false
