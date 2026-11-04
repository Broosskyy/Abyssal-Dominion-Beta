class_name TargetingSystem
extends Node

signal target_changed(target: ShipMotor)

var target: ShipMotor

func _process(_delta: float) -> void:
	if target != null and not valid_hostile(target):
		set_target(null)


func valid_hostile(value: ShipMotor) -> bool:
	if not is_instance_valid(value) or not value.is_inside_tree() or value.is_queued_for_deletion() or not value.is_in_group("enemies"):
		return false
	var health := value.get_node_or_null("Health") as ShipHealth
	return health != null and not health.is_sunk


func pick_at(point: Vector2, camera: Camera3D) -> ShipMotor:
	if camera == null:
		return null
	var origin := camera.project_ray_origin(point)
	var hit := _ray_hit(origin, origin + camera.project_ray_normal(point) * camera.far)
	if not hit.is_empty():
		var direct := hit.collider as ShipMotor
		if valid_hostile(direct):
			set_target(direct)
			return direct
		# A physical island, pier or friendly hull in front must not select behind it.
		return null
	var best: ShipMotor
	var distance := INF
	for value in get_tree().get_nodes_in_group("enemies"):
		var candidate := value as ShipMotor
		if not valid_hostile(candidate) or camera.is_position_behind(candidate.global_position):
			continue
		var center := camera.unproject_position(candidate.global_position + Vector3.UP)
		var score := point.distance_squared_to(center)
		if score <= 36 * 36 and score < distance:
			var obstruction := _ray_hit(origin, candidate.global_position + Vector3.UP * 0.25)
			if not obstruction.is_empty() and obstruction.collider != candidate:
				continue
			best = candidate
			distance = score
	if best != null:
		set_target(best)
	return best


func _ray_hit(from: Vector3, to: Vector3) -> Dictionary:
	var player := get_parent() as ShipMotor
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [player.get_rid()])
	query.collide_with_areas = false
	return player.get_world_3d().direct_space_state.intersect_ray(query)


func target_range_state(max_range: float) -> String:
	if target == null or not valid_hostile(target):
		return "NONE"
	var distance: float = get_parent().global_position.distance_to(target.global_position)
	if distance <= max_range * 0.7:
		return "OPTIMAL"
	if distance <= max_range:
		return "EDGE"
	return "OUT"


# M212: compact combat-readiness payload for HUD composition. Visual/read-only only.
func target_readiness(max_range: float) -> Dictionary:
	if target == null or not valid_hostile(target):
		return {"state":"NO_TARGET","distance":0.0,"range":max_range,"ratio":0.0}
	var distance: float = get_parent().global_position.distance_to(target.global_position)
	var ratio := distance / maxf(1.0, max_range)
	return {
		"state": target_range_state(max_range),
		"distance": distance,
		"range": max_range,
		"ratio": ratio,
		"in_range": distance <= max_range
	}


func nearest_hostile_in_range(max_range: float) -> ShipMotor:
	var best: ShipMotor = null
	var best_score := INF
	for value in get_tree().get_nodes_in_group("enemies"):
		var candidate := value as ShipMotor
		if not valid_hostile(candidate):
			continue
		var distance: float = get_parent().global_position.distance_to(candidate.global_position)
		if distance > max_range:
			continue
		var rank_bonus := 0.0
		var rank := str(candidate.get_meta("encounter_rank", "normal"))
		if rank == "boss": rank_bonus = 7.0
		elif rank == "elite": rank_bonus = 3.0
		var score: float = distance - rank_bonus
		if score < best_score:
			best_score = score
			best = candidate
	return best

func cycle_target() -> ShipMotor:
	var hostiles: Array[ShipMotor] = []
	for candidate in get_tree().get_nodes_in_group("enemies"):
		var ship := candidate as ShipMotor
		if ship == null:
			continue
		var health := ship.get_node_or_null("Health") as ShipHealth
		if health != null and not health.is_sunk:
			hostiles.append(ship)
	hostiles.sort_custom(func(a: ShipMotor, b: ShipMotor) -> bool:
		return get_parent().global_position.distance_squared_to(a.global_position) < get_parent().global_position.distance_squared_to(b.global_position)
	)
	if hostiles.is_empty():
		set_target(null)
		return null
	var next_index := 0
	if target != null:
		var current_index := hostiles.find(target)
		if current_index >= 0:
			next_index = (current_index + 1) % hostiles.size()
	set_target(hostiles[next_index])
	return target


func set_target(value: ShipMotor) -> void:
	if value != null and not valid_hostile(value):
		value = null
	if value == target:
		return
	_set_ring(target, false)
	target = value
	_set_ring(target, true)
	target_changed.emit(target)
	if target == null:
		var weapons := get_parent().get_node_or_null("Weapons") as ShipWeapons
		if weapons != null:
			weapons.auto_fire = false


func _set_ring(ship: ShipMotor, enabled: bool) -> void:
	if ship == null or not is_instance_valid(ship):
		return
	var ring := ship.get_node_or_null("Visual/SelectionRing") as MeshInstance3D
	if ring != null:
		ring.visible = enabled
		ring.scale = Vector3(1.12, 1.12, 1.12) if enabled else Vector3.ONE
		ship.set_meta("m199_selected_target", enabled)
