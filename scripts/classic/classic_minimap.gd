extends Control
## M304 chart radar: live ship/enemy/island positions, compass and readable
## navigation rings. All markers derive from actual world state each frame.
var player_position := Vector2.ZERO
var islands: Array[Dictionary] = []
var enemies: Array[Vector2] = []

const OCEAN := Color("092c40")
const SHALLOW := Color("21637b")
const GOLD := Color("c6a66f")
const ENEMY := Color("ef8d59")
const PLAYER := Color("76ee9e")

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.445
	if radius < 8.0:
		return
	draw_circle(center, radius + 5.0, Color("8f754b"))
	draw_circle(center, radius + 2.0, Color("101d2a"))
	draw_circle(center, radius - 1.0, OCEAN)
	var region := radius - 5.0
	# The grid is intentionally subtle and directly positioned in map space.
	for t in [-0.5, 0.0, 0.5]:
		var offset: float = region * float(t)
		var x: float = center.x + offset
		var y: float = center.y + offset
		var edge: float = sqrt(maxf(0.0, region * region - offset * offset))
		draw_line(Vector2(x, center.y - edge), Vector2(x, center.y + edge), Color("32617a68"), 1.0)
		draw_line(Vector2(center.x - edge, y), Vector2(center.x + edge, y), Color("32617a68"), 1.0)
	draw_arc(center, region * 0.48, 0.0, TAU, 80, Color("43758a88"), 1.0, true)
	draw_arc(center, region * 0.8, 0.0, TAU, 80, Color("43758a76"), 1.0, true)
	for index in islands.size():
		var island: Dictionary = islands[index]
		var world_position: Vector3 = island["position"]
		var spot := center + (Vector2(world_position.x, world_position.z) - player_position) * 0.52
		var island_radius := clampf(float(island["radius"]) * 0.25, 3.0, 12.0)
		if spot.distance_to(center) + island_radius >= region:
			continue
		draw_circle(spot, island_radius + 2.0, SHALLOW)
		_draw_island(spot, island_radius, index)
	for enemy_position in enemies:
		var spot := center + (enemy_position - player_position) * 0.52
		if spot.distance_to(center) > region - 4.0:
			continue
		# Diamond = enemy ship, not an ambiguous generic red dot.
		var diamond := PackedVector2Array([
			spot + Vector2(0, -4), spot + Vector2(3.8, 0),
			spot + Vector2(0, 4), spot + Vector2(-3.8, 0)])
		draw_colored_polygon(diamond, ENEMY)
	draw_circle(center, 6.0, Color("142c30"))
	draw_circle(center, 3.8, PLAYER)
	draw_line(center, center + Vector2(0.0, -8.0), PLAYER, 1.5, true)
	draw_arc(center, radius - 1.0, 0.0, TAU, 96, GOLD, 1.4, true)
	# Tick marks, fixed North arrow and actual minimap coordinates.
	for k in 12:
		var angle := TAU * float(k) / 12.0
		var direction := Vector2(sin(angle), -cos(angle))
		var inner := radius - (6.0 if k % 3 == 0 else 3.5)
		draw_line(center + direction * inner, center + direction * radius, GOLD, 1.4)
	var font: Font = ThemeDB.fallback_font
	if font != null and radius >= 43.0:
		draw_string(font, center + Vector2(-4.0, -radius + 14.0), "N",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fae2a9"))
		draw_string(font, Vector2(6.0, size.y - 4.0),
			"%d:%d" % [roundi(player_position.x), roundi(player_position.y)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("bad2d8"))


func _draw_island(at: Vector2, radius: float, index: int) -> void:
	var coast := PackedVector2Array()
	for n in 9:
		var a := TAU * float(n) / 9.0
		var jitter := 0.82 + 0.15 * sin(float(index * 13 + n * 5))
		coast.append(at + Vector2(cos(a), sin(a)) * radius * jitter)
	draw_colored_polygon(coast, Color("a7b8a5"))
	draw_circle(at + Vector2(-radius * 0.15, -radius * 0.13), radius * 0.48, Color("708b6f"))
