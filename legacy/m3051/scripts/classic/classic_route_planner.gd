extends RefCounted
## M303.1: local seekarte routing, independent of the old M302 motor.
## Builds a small visibility graph around expanded circular shore obstacles.
## This is deterministic preview navigation, not server-authoritative pathfinding.

const SAMPLES_PER_ISLAND := 16
const EXTRA_MARGIN := 3.2
const EPSILON := 0.05

static func plan(start: Vector2, goal: Vector2, obstacles: Array[Dictionary], limit_x: float = 135.0, limit_z: float = 100.0) -> PackedVector2Array:
	var empty := PackedVector2Array()
	if not _within(goal, limit_x, limit_z):
		return empty
	if not _free_point(start, obstacles) or not _free_point(goal, obstacles):
		return empty
	if start.distance_to(goal) < 0.8:
		return empty
	if _clear_segment(start, goal, obstacles):
		return PackedVector2Array([goal])
	var nodes: Array[Vector2] = [start, goal]
	for obstacle in obstacles:
		var center3: Vector3 = obstacle["position"]
		var center := Vector2(center3.x, center3.z)
		var radius := (float(obstacle["radius"]) + EXTRA_MARGIN + 0.2) / cos(PI / float(SAMPLES_PER_ISLAND))
		for i in SAMPLES_PER_ISLAND:
			var angle := TAU * float(i) / float(SAMPLES_PER_ISLAND)
			var candidate := center + Vector2(cos(angle), sin(angle)) * radius
			if _within(candidate, limit_x, limit_z) and _free_point(candidate, obstacles):
				nodes.append(candidate)
	var distance: Array[float] = []
	var predecessor: Array[int] = []
	var visited: Array[bool] = []
	for _i in nodes.size():
		distance.append(INF)
		predecessor.append(-1)
		visited.append(false)
	distance[0] = 0.0
	for _step in nodes.size():
		var current := -1
		var best := INF
		for i in nodes.size():
			if not visited[i] and distance[i] < best:
				best = distance[i]
				current = i
		if current < 0 or current == 1:
			break
		visited[current] = true
		for j in nodes.size():
			if current == j or visited[j]:
				continue
			if not _clear_segment(nodes[current], nodes[j], obstacles):
				continue
			var cost := distance[current] + nodes[current].distance_to(nodes[j])
			if cost < distance[j]:
				distance[j] = cost
				predecessor[j] = current
	if predecessor[1] < 0:
		return empty
	var path: Array[Vector2] = []
	var cursor := 1
	while cursor > 0:
		path.append(nodes[cursor])
		cursor = predecessor[cursor]
		if cursor < 0:
			return empty
	path.reverse()
	return PackedVector2Array(path)


static func _within(point: Vector2, limit_x: float, limit_z: float) -> bool:
	return absf(point.x) <= limit_x and absf(point.y) <= limit_z


static func _free_point(point: Vector2, obstacles: Array[Dictionary]) -> bool:
	for obstacle in obstacles:
		var c3: Vector3 = obstacle["position"]
		var center := Vector2(c3.x, c3.z)
		if point.distance_to(center) < float(obstacle["radius"]) + EXTRA_MARGIN - EPSILON:
			return false
	return true


static func _clear_segment(start: Vector2, goal: Vector2, obstacles: Array[Dictionary]) -> bool:
	var segment := goal - start
	var denominator := segment.length_squared()
	if denominator < 0.0001:
		return true
	for obstacle in obstacles:
		var c3: Vector3 = obstacle["position"]
		var center := Vector2(c3.x, c3.z)
		var progress := clampf((center - start).dot(segment) / denominator, 0.0, 1.0)
		var closest := start + segment * progress
		if closest.distance_to(center) < float(obstacle["radius"]) + EXTRA_MARGIN - EPSILON:
			return false
	return true
