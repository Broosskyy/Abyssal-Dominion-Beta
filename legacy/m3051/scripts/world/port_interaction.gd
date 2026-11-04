class_name PortInteraction
extends Area3D

signal docking_state_changed(docked: bool, port_name: String)
signal harbor_proximity_changed(nearby: bool, ship: ShipMotor, port_name: String)

var port_name := "Harbor"
var spawn_position := Vector3.ZERO
var nearby_player: ShipMotor
var activated_for_visit := false
var m225_docked_player: ShipMotor = null


func _ready() -> void:
	monitoring = true
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func activate(player: ShipMotor) -> bool:
	if player == null or player != nearby_player:
		return false
	# M225: the same contextual harbor interaction toggles a real local docked state.
	# This never changes navigation/collision authority; leaving simply restores sea control.
	if m225_docked_player == player and bool(player.get_meta("m225_docked", false)):
		return undock(player)
	var health := player.get_node_or_null("Health") as ShipHealth
	if health != null and health.is_sunk:
		return false
	var input_node := player.get_node_or_null("PlayerInput") as PlayerShipInput
	if health != null:
		health.respawn_position = spawn_position
	var emergency_ammo := false
	if input_node != null:
		emergency_ammo = (player.get_node("Inventory") as PlayerInventory).emergency_standard_ammo()
	var missions := player.get_node_or_null("Missions") as MissionSystem
	if missions != null and not activated_for_visit:
		missions.record_dock()
	activated_for_visit = true
	player.set_meta("last_port", port_name)
	player.set_meta("m225_docked", true)
	player.set_meta("m225_docked_port", port_name)
	m225_docked_player = player
	var inventory := player.get_node("Inventory") as PlayerInventory
	var repair_quote := inventory.harbor_repair_quote()
	var dock_text := "DOCKED — LOCAL HARBOR SERVICES READY · REPAIR %d GOLD" % repair_quote if repair_quote > 0 else "DOCKED — LOCAL HARBOR SERVICES READY"
	if emergency_ammo:
		dock_text += " · EMERGENCY IRON +%d" % PlayerInventory.EMERGENCY_IRON_STOCK
	player.set_meta("dock_message", dock_text)
	player.set_meta("dock_message_until", Time.get_ticks_msec() / 1000.0 + 2.8)
	if port_name == "Haven's Reach" and not bool(player.get_meta("havens_reach_first_dock_seen", false)):
		player.set_meta("havens_reach_first_dock_seen", true)
		var viewport_size:=get_viewport().get_visible_rect().size
		var duration:=MobilePresentationBudget.float_value(viewport_size,float(DisplayServer.screen_get_dpi()),"first_dock_seconds",5.0)
		player.set_meta("havens_reach_first_dock_until", Time.get_ticks_msec() / 1000.0 + duration)
	player.stop_ship()
	player.set_meta("navigation_intent", "")
	for state in get_tree().get_nodes_in_group("game_state"):
		state.mark_dirty()
		state.save_now()
	docking_state_changed.emit(true, port_name)
	return true


func undock(player: ShipMotor) -> bool:
	if player == null or player != nearby_player or m225_docked_player != player:
		return false
	player.set_meta("m225_docked", false)
	player.remove_meta("m225_docked_port")
	m225_docked_player = null
	player.set_meta("dock_message", "ABLEGEN — ZURÜCK AUF SEE")
	player.set_meta("dock_message_until", Time.get_ticks_msec() / 1000.0 + 2.0)
	for state in get_tree().get_nodes_in_group("game_state"):
		state.mark_dirty()
	docking_state_changed.emit(false, port_name)
	return true


func _on_body_entered(body: Node3D) -> void:
	if not (body is ShipMotor and body.is_in_group("player")):
		return
	nearby_player = body as ShipMotor
	activated_for_visit = false
	body.set_meta("nearby_port", self)
	body.set_meta("nearby_port_name", port_name)
	harbor_proximity_changed.emit(true, body, port_name)


func _on_body_exited(body: Node3D) -> void:
	if body != nearby_player:
		return
	if body.get_meta("nearby_port", null) == self:
		body.remove_meta("nearby_port")
		body.remove_meta("nearby_port_name")
	if m225_docked_player == body:
		body.set_meta("m225_docked", false)
		body.remove_meta("m225_docked_port")
		m225_docked_player = null
	nearby_player = null
	activated_for_visit = false
	harbor_proximity_changed.emit(false, body, port_name)
