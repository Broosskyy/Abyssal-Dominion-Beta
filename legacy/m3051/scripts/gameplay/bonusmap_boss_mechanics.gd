class_name BonusMapBossMechanics
extends Node
## Presentation-aware local boss mechanic executor using existing combat primitives.

signal mechanic_started(id: String)
signal mechanic_fired(id: String)
signal mechanic_resolved(id: String, result: String)

var ship: ShipMotor
var target: ShipMotor
var map_id := ""
var mechanic_ids: Array[String] = []
var cooldowns: Dictionary = {}
var fired_once: Dictionary = {}
var pending_id := ""
var telegraph_remaining := 0.0
var telegraph_duration := 0.0
var locked_position := Vector3.ZERO
var locked_origin := Vector3.ZERO
var telegraph_anchor := "target"
var telegraph_shape := "circle"
var telegraph_root: Node3D
var telegraph_mesh: MeshInstance3D
var telegraph_material: StandardMaterial3D
var elapsed := 0.0
var mechanic_count := 0

func setup(owner_ship: ShipMotor, captain: ShipMotor, bonusmap_id: String, ids: Array) -> void:
	ship = owner_ship
	target = captain
	map_id = bonusmap_id
	for value in ids:
		var id := str(value)
		if not id.is_empty() and not M177BonusMapBossRuntimeCatalog.mechanic(id).is_empty():
			mechanic_ids.append(id)
	for index in mechanic_ids.size():
		cooldowns[mechanic_ids[index]] = 3.5 + float(index) * 1.4
	ship.set_meta("m177_runtime_mechanics", mechanic_ids.duplicate())

func _process(delta: float) -> void:
	if ship == null or target == null or mechanic_ids.is_empty():
		_clear_telegraph()
		return
	var health := ship.get_node_or_null("Health") as ShipHealth
	if health == null or health.is_sunk:
		_clear_telegraph()
		return
	var target_health := target.get_node_or_null("Health") as ShipHealth
	if target_health == null or target_health.is_sunk:
		_cancel_pending("target_unavailable")
		return
	elapsed += delta
	if not pending_id.is_empty():
		telegraph_remaining -= delta
		_update_telegraph_visual()
		if telegraph_remaining <= 0.0:
			_fire_pending()
		return
	if ship.global_position.distance_to(target.global_position) > float(M177BonusMapBossRuntimeCatalog.data().get("activation_range", 64.0)): return
	for id in mechanic_ids:
		var row := M177BonusMapBossRuntimeCatalog.mechanic(id)
		if not _eligible(id, row, health): continue
		if elapsed >= float(cooldowns.get(id, 0.0)):
			_begin(id, row)
			return

func _eligible(id: String, row: Dictionary, health: ShipHealth) -> bool:
	var trigger := str(row.get("trigger", "interval"))
	if trigger == "phase_once":
		return not bool(fired_once.get(id, false)) and int(ship.get_meta("boss_phase", 1)) >= int(row.get("phase", 3))
	if trigger == "health_once":
		return not bool(fired_once.get(id, false)) and health.normalized() <= float(row.get("health_ratio", 0.25))
	return trigger == "interval"

func _begin(id: String, row: Dictionary) -> void:
	pending_id = id
	telegraph_duration = maxf(0.35, float(row.get("telegraph", 1.0)))
	telegraph_remaining = telegraph_duration
	telegraph_anchor = str(row.get("telegraph_anchor", "target"))
	telegraph_shape = str(row.get("telegraph_shape", "circle"))
	locked_origin = ship.global_position
	locked_position = ship.global_position if telegraph_anchor == "boss" else target.global_position
	ship.set_meta("danger_telegraph", id)
	ship.set_meta("danger_telegraph_until", Time.get_ticks_msec() / 1000.0 + telegraph_remaining)
	ship.set_meta("danger_telegraph_duration", telegraph_duration)
	ship.set_meta("danger_telegraph_position", locked_position)
	ship.set_meta("danger_telegraph_origin", locked_origin)
	ship.set_meta("danger_telegraph_shape", telegraph_shape)
	ship.set_meta("danger_telegraph_color", str(row.get("telegraph_color", "#B46CFF")))
	ship.set_meta("boss_mechanic_label", str(row.get("label", id.replace("_", " ").capitalize())))
	_build_telegraph(row)
	_present(id, row, true)
	mechanic_started.emit(id)

func _fire_pending() -> void:
	var id := pending_id
	var row := M177BonusMapBossRuntimeCatalog.mechanic(id)
	var in_cast_range := locked_origin.distance_to(locked_position) <= float(row.get("range", 999.0))
	var inside_zone := _inside_telegraph(target.global_position, row)
	var hits_target := in_cast_range and (inside_zone or not bool(row.get("dodgeable", false)))
	var target_health := target.get_node_or_null("Health") as ShipHealth
	var boss_health := ship.get_node_or_null("Health") as ShipHealth
	match str(row.get("action", "")):
		"target_damage":
			if hits_target and target_health != null:
				target_health.apply_damage(float(row.get("amount", 0.0)), ship, float(row.get("armor_pierce", 0.0)), float(row.get("slow", 0.0)), false)
		"repair_block":
			if hits_target and target_health != null:
				target_health.apply_damage(float(row.get("amount", 0.0)), ship, float(row.get("armor_pierce", 0.0)))
				target_health.block_repair(float(row.get("duration", 0.0)))
		"target_status":
			if hits_target and target_health != null:
				target_health.apply_damage(float(row.get("amount", 0.0)), ship)
				target_health.apply_ammo_effect(str(row.get("status_id", "spectral_mark")), float(row.get("power", 0.0)), float(row.get("duration", 0.0)), ship)
		"boss_barrier":
			if boss_health != null: boss_health.grant_temporary_barrier(boss_health.max_health * float(row.get("amount_ratio", 0.1)), float(row.get("duration", 4.0)))
		"boss_enrage":
			if boss_health != null: boss_health.grant_temporary_barrier(boss_health.max_health * float(row.get("barrier_ratio", 0.08)), float(row.get("duration", 5.0)))
			var weapons := ship.get_node_or_null("Weapons") as ShipWeapons
			if weapons != null and not bool(fired_once.get(id, false)): weapons.damage *= float(row.get("damage_mult", 1.0))
	var target_action := str(row.get("action", "")).begins_with("target_") or str(row.get("action", "")) == "repair_block"
	CombatVfx.action(get_tree(), str(row.get("vfx_action", "boss_phase")), ship.global_position, target if target_action and hits_target else null)
	mechanic_count += 1
	ship.set_meta("last_boss_mechanic", id)
	var result := "self" if telegraph_anchor == "boss" else ("hit" if hits_target else "dodged")
	ship.set_meta("last_boss_mechanic_result", result)
	ship.set_meta("boss_mechanic_count", mechanic_count)
	fired_once[id] = true
	cooldowns[id] = elapsed + maxf(2.0, float(row.get("cooldown", 9999.0)))
	_present_result(id, row, result)
	_clear_telegraph()
	mechanic_fired.emit(id)
	mechanic_resolved.emit(id, result)

func _inside_telegraph(point: Vector3, row: Dictionary) -> bool:
	if telegraph_shape == "line":
		return _distance_to_segment_xz(point, locked_origin, locked_position) <= maxf(0.5, float(row.get("line_width", 4.0))) * 0.5
	return point.distance_to(locked_position) <= float(row.get("hit_radius", 4.5))

func _distance_to_segment_xz(point: Vector3, start: Vector3, finish: Vector3) -> float:
	var p := Vector2(point.x, point.z)
	var a := Vector2(start.x, start.z)
	var b := Vector2(finish.x, finish.z)
	var segment := b - a
	if segment.length_squared() <= 0.0001: return p.distance_to(a)
	var amount := clampf((p - a).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return p.distance_to(a + segment * amount)

func _build_telegraph(row: Dictionary) -> void:
	_clear_telegraph_visual()
	telegraph_root = Node3D.new()
	telegraph_material = StandardMaterial3D.new()
	telegraph_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	telegraph_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	telegraph_material.emission_enabled = true
	_add_ring(maxf(1.5, float(row.get("hit_radius", 4.5))))
	if telegraph_shape == "line": _add_line(maxf(0.5, float(row.get("line_width", 4.0))))
	var slot_id := str(row.get("telegraph_slot", "vfx_boss_telegraph_legendary"))
	var replacement := VisualAssetCatalog.resource_override("vfx", slot_id, ["tscn"]) as PackedScene
	if replacement != null:
		var accent := replacement.instantiate() as Node3D
		if accent != null:
			accent.name = "AuthoredTelegraphAccent"
			telegraph_root.add_child(accent)
	telegraph_root.name = "M179BossTelegraphShape"
	add_child(telegraph_root)
	telegraph_root.top_level = true
	_update_telegraph_visual()

func _add_ring(radius: float) -> void:
	telegraph_mesh = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = maxf(0.25, radius - 0.22)
	ring.outer_radius = radius
	ring.rings = 32
	ring.ring_segments = 10
	telegraph_mesh.mesh = ring
	telegraph_mesh.rotation_degrees.x = 90.0
	telegraph_mesh.material_override = telegraph_material
	telegraph_root.add_child(telegraph_mesh)

func _add_line(width: float) -> void:
	var delta := locked_position - locked_origin
	delta.y = 0.0
	var length := maxf(0.1, delta.length())
	var lane := MeshInstance3D.new()
	var lane_mesh := BoxMesh.new()
	lane_mesh.size = Vector3(width, 0.045, length)
	lane.mesh = lane_mesh
	lane.position = (locked_origin - locked_position) * 0.5
	lane.rotation.y = atan2(delta.x, delta.z)
	lane.material_override = telegraph_material
	telegraph_root.add_child(lane)

func _update_telegraph_visual() -> void:
	if telegraph_root == null: return
	if telegraph_anchor == "boss" and ship != null: locked_position = ship.global_position
	telegraph_root.global_position = locked_position + Vector3.UP * 0.08
	var progress := clampf(1.0 - telegraph_remaining / maxf(0.01, telegraph_duration), 0.0, 1.0)
	var settings := ClientSettings.current(get_tree())
	var reduced_motion := settings != null and bool(settings.values.get("reduced_motion", false))
	var intensity := clampf(float(settings.values.get("effect_intensity", 1.0)), 0.0, 1.0) if settings != null else 1.0
	var pulse := 1.0 if reduced_motion else lerpf(0.84, 1.04, progress)
	telegraph_root.scale = Vector3.ONE * pulse
	if telegraph_material != null:
		var color := Color(str(ship.get_meta("danger_telegraph_color", "#B46CFF")))
		color.a = maxf(0.42, lerpf(0.42, 0.9, intensity))
		telegraph_material.albedo_color = color
		telegraph_material.emission = Color(color.r, color.g, color.b, 1.0)
		telegraph_material.emission_energy_multiplier = lerpf(0.7, 1.8, intensity)

func _clear_telegraph() -> void:
	pending_id = ""
	telegraph_remaining = 0.0
	telegraph_duration = 0.0
	if ship != null:
		ship.set_meta("danger_telegraph", "")
		ship.remove_meta("danger_telegraph_until")
		ship.remove_meta("danger_telegraph_duration")
		ship.remove_meta("danger_telegraph_position")
		ship.remove_meta("danger_telegraph_origin")
		ship.remove_meta("danger_telegraph_shape")
	_clear_telegraph_visual()

func _cancel_pending(reason: String) -> void:
	if pending_id.is_empty(): return
	var id := pending_id
	if ship != null:
		ship.set_meta("last_boss_mechanic", id)
		ship.set_meta("last_boss_mechanic_result", "cancelled")
		ship.set_meta("last_boss_mechanic_cancel_reason", reason)
	_clear_telegraph()
	mechanic_resolved.emit(id, "cancelled")

func _exit_tree() -> void:
	_clear_telegraph()

func _clear_telegraph_visual() -> void:
	if telegraph_root != null and is_instance_valid(telegraph_root):
		telegraph_root.queue_free()
	telegraph_root = null
	telegraph_mesh = null
	telegraph_material = null

func _present(id: String, row: Dictionary, telegraph: bool) -> void:
	var hud := get_tree().get_first_node_in_group("hud") as GameHud
	if hud == null: return
	var label := str(row.get("label", id.replace("_", " ").capitalize())).to_upper()
	hud.present_event("boss_mechanic", "%s · %s" % [ship.name.to_upper(), label], {"boss": ship.name.to_upper(), "mechanic": label, "state": "TELEGRAPH" if telegraph else "AKTIV"})

func _present_result(id: String, row: Dictionary, result: String) -> void:
	if result == "self": return
	var hud := get_tree().get_first_node_in_group("hud") as GameHud
	if hud == null: return
	var label := str(row.get("label", id.replace("_", " ").capitalize())).to_upper()
	if result == "dodged":
		hud.present_event("boss_dodged", "AUSGEWICHEN · %s" % label, {"mechanic": label})
	else:
		hud.present_event("boss_hit", "TREFFER · %s" % label, {"mechanic": label})
