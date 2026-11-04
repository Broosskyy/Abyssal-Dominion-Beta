class_name EnemyShipAI
extends Node

@export var detection_range := 28.0
@export var desired_range := 10.0
@export var leash_range := 42.0
@export var disengage_seconds := 4.0
@export_enum("raider", "tank", "sniper", "scout", "leviathan") var archetype := "raider"

var target: ShipMotor
var spawn_anchor := Vector3.ZERO
var state := "PATROL"
var _last_tactical_update := 0.0
var _lost_target_time := 0.0
var _phase := 1
var _base_reload := 1.15
var _base_speed := 4.0
var _base_damage := 72.0
var _orbit_sign := 1.0
var passive_until_attacked := false
var provoked := false
var _reacquire_block_until_msec := 0
const M217_POST_RESPAWN_DISENGAGE_BUFFER_MSEC := 3500
const M218EncounterReadabilityScript = preload("res://scripts/visual/m218_encounter_readability.gd")
var _m218_recover_until_msec := 0
@onready var ship: ShipMotor = get_parent() as ShipMotor
@onready var weapons: ShipWeapons = get_parent().get_node("Weapons") as ShipWeapons
@onready var health: ShipHealth = get_parent().get_node("Health") as ShipHealth


func _ready() -> void:
	spawn_anchor = ship.global_position
	_orbit_sign = -1.0 if int(absf(spawn_anchor.x + spawn_anchor.z)) % 2 == 0 else 1.0
	match archetype:
		"tank":
			ship.cruise_speed = 3.4
			health.armor = 0.28
			weapons.cannon_index = 2
		"sniper":
			desired_range = 15.0
			weapons.projectile_speed = 24.0
			weapons.reload_seconds = 1.6
			weapons.damage = 92.0
		"scout":
			ship.cruise_speed = 6.8
			health.armor = 0.02
			weapons.cannon_index = 0
			weapons.ammo_index = 2
		"leviathan":
			detection_range = 34.0
			desired_range = 8.5
			leash_range = 55.0
			ship.cruise_speed = 5.2
			health.armor = 0.18
			weapons.cannon_index = 2
			weapons.ammo_index = 1
		_:
			weapons.ammo_index = 1
	_apply_regional_role()
	_base_reload = weapons.reload_seconds
	_base_speed = ship.cruise_speed
	_base_damage = weapons.damage
	passive_until_attacked = bool(ship.get_meta("passive_until_attacked", false))
	if passive_until_attacked:
		health.damage_applied.connect(_on_damage_applied)



func _apply_regional_role() -> void:
	var role := str(ship.get_meta("regional_combat_role", ""))
	match role:
		"storm_skirmisher":
			ship.cruise_speed *= 1.10
			desired_range = 11.5
			weapons.ammo_index = 2
		"storm_guard":
			health.armor = minf(0.42, health.armor + 0.08)
			desired_range = 9.0
		"storm_hunter":
			detection_range += 4.0
			weapons.projectile_speed *= 1.08
			weapons.ammo_index = 2
		"ember_brawler":
			desired_range = 7.5
			weapons.damage *= 1.10
			weapons.ammo_index = 1
		"ember_bulwark":
			health.armor = minf(0.48, health.armor + 0.12)
			ship.cruise_speed *= 0.92
			weapons.ammo_index = 6
		"ember_artillery":
			desired_range = 15.5
			weapons.projectile_speed *= 1.14
			weapons.reload_seconds *= 1.08
			weapons.ammo_index = 1
		"veil_stalker":
			ship.cruise_speed *= 1.08
			desired_range = 13.0
			weapons.ammo_index = 7
		"veil_marksman":
			desired_range = 17.0
			weapons.projectile_speed *= 1.18
			weapons.ammo_index = 7
		"veil_warden":
			health.armor = minf(0.44, health.armor + 0.08)
			weapons.ammo_index = 6
		"crimson_skirmisher":
			ship.cruise_speed *= 1.08; desired_range = 9.5; weapons.ammo_index = 1
		"crimson_guard":
			health.armor = minf(0.42, health.armor + 0.07); weapons.ammo_index = 0
		"crimson_hunter":
			detection_range += 4.0; desired_range = 13.0; weapons.ammo_index = 3
		"drowned_raider":
			ship.cruise_speed *= 1.04; weapons.ammo_index = 5
		"drowned_bulwark":
			health.armor = minf(0.46, health.armor + 0.10); ship.cruise_speed *= 0.94; weapons.ammo_index = 6
		"wraith_scout":
			ship.cruise_speed *= 1.13; desired_range = 12.0; weapons.ammo_index = 7
		"cursed_raider", "frontier_raider", "void_raider", "dominion_raider", "dreadwater_vanguard":
			ship.cruise_speed *= 1.06; weapons.ammo_index = 5
		"cursed_marksman", "frontier_status", "void_hunter", "rift_hunter", "dreadwater_marksman":
			desired_range = 15.0; weapons.projectile_speed *= 1.10; weapons.ammo_index = 7
		"cursed_bulwark", "frontier_bulwark", "void_guard", "legendary_guard", "ironmaw_siege_guard":
			health.armor = minf(0.50, health.armor + 0.11); ship.cruise_speed *= 0.93; weapons.ammo_index = 6
		"ancient_raider", "sovereign_raider":
			ship.cruise_speed *= 1.04; weapons.ammo_index = 3
		"relic_guard", "sovereign_guard":
			health.armor = minf(0.48, health.armor + 0.10); weapons.ammo_index = 3
		"titan_piercer", "ironmaw_mortar_line":
			desired_range = 16.5; weapons.projectile_speed *= 1.14; weapons.reload_seconds *= 1.08; weapons.ammo_index = 3
		"guardian_hunter", "banner_hunter", "frontier_hunter", "dreadwater_chain_hunter", "ironmaw_hunter":
			detection_range += 5.0; desired_range = 12.5; weapons.ammo_index = 2
		_:
			if role.ends_with("_admiral"):
				health.armor = minf(0.50, health.armor + 0.05)
				detection_range += 3.0

func _process(delta: float) -> void:
	if health.is_sunk:
		return
	_update_boss_phase()
	_acquire_target()
	if target == null:
		_patrol_or_return(delta)
		return
	if not _target_is_attackable(target):
		_m217_disengage_defeated_or_protected_target(target)
		_patrol_or_return(delta)
		return
	if target.get_meta("in_safe_zone", false):
		_drop_aggro()
		return

	var from_anchor := _flat_distance(ship.global_position, spawn_anchor)
	var target_from_anchor := _flat_distance(target.global_position, spawn_anchor)
	if from_anchor > leash_range or target_from_anchor > leash_range * 1.15:
		state = "RETURN"
		target = null
		_patrol_or_return(delta)
		return

	var delta_position := target.global_position - ship.global_position
	delta_position.y = 0.0
	var distance := delta_position.length()
	if distance > detection_range * 1.2:
		_lost_target_time += delta
		if _lost_target_time >= disengage_seconds:
			_drop_aggro()
			return
	else:
		_lost_target_time = 0.0

	if distance > detection_range and state == "PATROL":
		_patrol_or_return(delta)
		return
	state = "ENGAGE"
	_set_m218_tactical_state("PURSUE")
	_tactical_loadout()
	_engage(delta_position, distance)


func _acquire_target() -> void:
	if Time.get_ticks_msec() < _reacquire_block_until_msec:
		return
	if target != null and is_instance_valid(target):
		if not _target_is_attackable(target):
			target = null
			state = "PATROL"
		else:
			return
	if passive_until_attacked and not provoked:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var candidate := players[0] as ShipMotor
	if candidate == null or not _target_is_attackable(candidate):
		return
	if _flat_distance(ship.global_position, candidate.global_position) <= detection_range:
		target = candidate
		state = "PURSUE"
		_set_m218_tactical_state("PURSUE")
		_lost_target_time = 0.0


func _on_damage_applied(_target: Node3D, attacker: Node3D, _actual_damage: float, _slowed: bool, _critical: bool) -> void:
	if not passive_until_attacked or provoked:
		return
	if attacker == null or not is_instance_valid(attacker) or not attacker.is_in_group("player"):
		return
	provoked = true
	target = attacker as ShipMotor
	state = "PURSUE"
	_set_m218_tactical_state("PURSUE")
	_lost_target_time = 0.0
	ship.set_meta("provoked", true)
	# M74 presentation only: expose a short relation-change window for HUD/VFX.
	ship.set_meta("provoked_feedback_until", Time.get_ticks_msec() / 1000.0 + 2.4)
	CombatVfx.action(get_tree(), "npc_provoked", ship.global_position)


func _engage(delta_position: Vector3, distance: float) -> void:
	var target_direction := delta_position.normalized()
	var forward := ship.global_transform.basis.z.normalized()
	var signed_angle := rad_to_deg(forward.signed_angle_to(target_direction, Vector3.UP))
	var broadside_error: float = abs(signed_angle) - 90.0
	var turn_gain := 38.0 if archetype == "scout" else 42.0
	ship.turn_input = clamp(broadside_error / turn_gain * sign(signed_angle), -1.0, 1.0)
	var preferred := minf(desired_range, weapons.effective_range() * 0.78)
	match archetype:
		"sniper": preferred = weapons.effective_range() * 0.84
		"tank": preferred = weapons.effective_range() * 0.55
		"scout": preferred = weapons.effective_range() * 0.68
		"leviathan": preferred = weapons.effective_range() * (0.50 if _phase >= 3 else 0.62)
	var close_ratio := 0.68 if archetype != "sniper" else 0.78
	ship.throttle_input = 0.82 if distance > preferred else (-0.38 if distance < preferred * close_ratio else 0.12)
	if archetype == "scout" and distance <= preferred * 1.25:
		ship.turn_input = clamp(ship.turn_input + _orbit_sign * 0.28, -1.0, 1.0)
	if archetype == "leviathan" and _phase >= 2 and distance <= preferred * 1.15:
		ship.turn_input = clamp(ship.turn_input + _orbit_sign * 0.18, -1.0, 1.0)
	var fire_window := 18.0 if archetype in ["tank", "leviathan"] else 16.0
	var broadside_visual_alignment: bool = abs(abs(signed_angle) - 90.0) < fire_window
	# M239/V3.8 canonical combat hardening:
	# Facing/broadside alignment may steer presentation, but it must never gate a valid attack.
	# Target + correct weapon + range + reload are authoritative; the visible firing side is cosmetic.
	var canonical_attack_ready := distance <= weapons.effective_range()
	if Time.get_ticks_msec() < _m218_recover_until_msec:
		_set_m218_tactical_state("RECOVER")
	elif distance < preferred * close_ratio:
		_set_m218_tactical_state("KITE")
	elif canonical_attack_ready:
		_set_m218_tactical_state("BROADSIDE" if broadside_visual_alignment else "FIRE_READY")
		# M217 threat metadata is presentation-only and no longer implies an angle requirement.
		ship.set_meta("m217_broadside_threat_until", Time.get_ticks_msec() + 650)
		ship.set_meta("m217_broadside_threat_target", target.get_instance_id() if target != null else 0)
		weapons.fire_broadside()
		_m218_recover_until_msec = Time.get_ticks_msec() + 900
	else:
		_set_m218_tactical_state("ALIGN")


func _patrol_or_return(_delta: float) -> void:
	var to_anchor := spawn_anchor - ship.global_position
	to_anchor.y = 0.0
	var distance := to_anchor.length()
	if state == "RETURN" or distance > 9.0:
		state = "RETURN"
		if distance < 2.2:
			state = "PATROL"
			ship.throttle_input = 0.12
			ship.turn_input = 0.0
			return
		var direction := to_anchor.normalized()
		var forward := ship.global_transform.basis.z.normalized()
		var signed_angle := rad_to_deg(forward.signed_angle_to(direction, Vector3.UP))
		ship.turn_input = clamp(signed_angle / 48.0, -1.0, 1.0)
		ship.throttle_input = 0.78
		return
	state = "PATROL"
	# M228: existing ships visibly patrol their local regional territory instead of idling in place.
	# This is anchor-relative steering only; combat, leash, spawn count and world navigation authorities are unchanged.
	var patrol_radius:=maxf(4.0,float(ship.get_meta("m228_patrol_radius",8.0)))
	var patrol_pace:=clampf(float(ship.get_meta("m228_patrol_pace",0.32)),0.18,0.45)
	var orbit_tangent:=Vector3(-to_anchor.z,0.0,to_anchor.x).normalized()*_orbit_sign if distance>0.1 else ship.global_transform.basis.z.normalized()
	var radial_correction:=to_anchor.normalized()*clampf((distance-patrol_radius)/maxf(patrol_radius,1.0),-0.55,0.55) if distance>0.1 else Vector3.ZERO
	var patrol_direction:=(orbit_tangent+radial_correction).normalized()
	var patrol_forward:=ship.global_transform.basis.z.normalized()
	var patrol_angle:=rad_to_deg(patrol_forward.signed_angle_to(patrol_direction,Vector3.UP))
	ship.throttle_input = patrol_pace
	ship.turn_input = clamp(patrol_angle/58.0,-0.48,0.48)


func _drop_aggro() -> void:
	target = null
	_lost_target_time = 0.0
	state = "RETURN"



func _m217_disengage_defeated_or_protected_target(candidate: ShipMotor) -> void:
	# M217 defeat safety: a ship that sank or just respawned must not keep the previous NPC aggro chain.
	# This does not alter player protection duration; it only blocks this AI from immediately reacquiring and forces return-to-anchor.
	var now := Time.get_ticks_msec()
	var blocked_until := now + M217_POST_RESPAWN_DISENGAGE_BUFFER_MSEC
	if candidate != null and is_instance_valid(candidate):
		var respawn_at := int(candidate.get_meta("respawn_at_msec", 0))
		var protection_until := int(candidate.get_meta("respawn_protection_until", 0))
		if respawn_at > now:
			var protection_seconds := float(GameplayRuleset.rule_value(get_tree(), "respawn.protection_seconds", 5.0))
			blocked_until = maxi(blocked_until, respawn_at + roundi(protection_seconds * 1000.0) + M217_POST_RESPAWN_DISENGAGE_BUFFER_MSEC)
		blocked_until = maxi(blocked_until, protection_until + M217_POST_RESPAWN_DISENGAGE_BUFFER_MSEC)
	_reacquire_block_until_msec = maxi(_reacquire_block_until_msec, blocked_until)
	ship.set_meta("m217_reacquire_block_until", _reacquire_block_until_msec)
	ship.set_meta("m217_forced_disengage", true)
	if passive_until_attacked:
		provoked = false
		ship.set_meta("provoked", false)
	_drop_aggro()

func _target_is_attackable(candidate: ShipMotor) -> bool:
	if candidate == null or not is_instance_valid(candidate) or not candidate.is_inside_tree():
		return false
	if candidate.get_meta("in_safe_zone", false) or candidate.get_meta("veil_active", false):
		return false
	if Time.get_ticks_msec() < int(candidate.get_meta("respawn_protection_until", 0)):
		return false
	var candidate_health := candidate.get_node_or_null("Health") as ShipHealth
	return candidate_health != null and not candidate_health.is_sunk


func _update_boss_phase() -> void:
	if not bool(ship.get_meta("is_admiral", false)):
		return
	var ratio := health.normalized()
	var next_phase := 3 if ratio <= 0.32 else (2 if ratio <= 0.66 else 1)
	if next_phase == _phase:
		return
	_phase = next_phase
	ship.set_meta("boss_phase", _phase)
	M218EncounterReadabilityScript.boss_phase_read(ship, _phase)
	var profile:Dictionary=ship.get_meta("m158_phase_profile",{})
	if not profile.is_empty():
		var phase_row:Dictionary=profile.get(str(_phase),{})
		weapons.reload_seconds=_base_reload*float(phase_row.get("reload_mult",1.0))
		ship.cruise_speed=_base_speed*float(phase_row.get("speed_mult",1.0))
		weapons.damage=_base_damage*float(phase_row.get("damage_mult",1.0))
	elif _phase == 2:
		weapons.reload_seconds = _base_reload * 0.82
		ship.cruise_speed = _base_speed * 1.10
	elif _phase == 3:
		weapons.reload_seconds = _base_reload * 0.68
		ship.cruise_speed = _base_speed * 1.20
		weapons.damage = _base_damage * 1.12
	var hud := get_tree().get_first_node_in_group("hud") as GameHud
	var event_id := "boss_enrage" if _phase >= 3 else "boss_phase"
	if hud != null:
		hud.present_event(event_id, "%s · PHASE %d" % [ship.name.to_upper(), _phase], {"boss": ship.name.to_upper(), "phase": _phase})
	CombatVfx.action(get_tree(), event_id, ship.global_position)


func _tactical_loadout() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_tactical_update < 1.25 or target == null or not is_instance_valid(target):
		return
	_last_tactical_update = now
	var target_health := target.get_node_or_null("Health") as ShipHealth
	var target_armor := target_health.armor if target_health != null else 0.0
	var distance_ratio := ship.global_position.distance_to(target.global_position) / maxf(1.0, weapons.effective_range())
	var choice := CombatCatalog.recommended_ammo(distance_ratio, target_armor)
	var regional_role := str(ship.get_meta("regional_combat_role", ""))
	if regional_role.begins_with("storm_"): choice = 2
	elif regional_role.begins_with("ember_"): choice = 1 if "bulwark" not in regional_role else 6
	elif regional_role.begins_with("veil_"): choice = 7 if "warden" not in regional_role else 6
	if archetype == "scout" and distance_ratio < 0.9:
		choice = 2
	elif archetype == "sniper" and target_armor >= 0.18:
		choice = 0
	elif archetype == "leviathan" and _phase >= 2:
		choice = 1
	weapons.ammo_index = choice



func _set_m218_tactical_state(value: String) -> void:
	ship.set_meta("m218_tactical_state", value)
	ship.set_meta("m218_tactical_state_since", Time.get_ticks_msec())


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
