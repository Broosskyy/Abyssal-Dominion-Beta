extends RefCounted
## Independent fixed-step sea simulation. No dependency on legacy map scripts.
const WORLD := Vector2(4400, 3200)
const CELL := 48
const PLAYER_SPEED := 165.0
const PLAYER_HP := 2400
const START := Vector2(2100, 1450)
const AMMO_NAMES := ["cannon", "chain", "harpoon"]
var player: Dictionary
var npcs: Array[Dictionary] = []
var islands: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var events: Array[Dictionary] = []
var clock := 0.0
var next_id := 1000
var grid := AStarGrid2D.new()
var firing := false
var repairing := false
var target := -1
var ammo_mode := 0
var kills := 0
var claimed := false
var message := "Seekarte antippen: Kurs setzen · Schiff antippen: Ziel wählen"

func _init() -> void:
	player = {"id": 0, "pos": START, "heading": Vector2(-1, 0), "path": [], "hp": PLAYER_HP,
		"max_hp": PLAYER_HP, "speed": PLAYER_SPEED, "reload": 0.0, "gold": 240,
		"ammo": [600, 120, 100], "skin": 22, "last_hit": -100.0, "respawn": 0.0, "slow": 0.0}
	islands = [
		{"pos": Vector2(1530, 1250), "radius": 145.0, "art": "tropical", "width": 490.0, "name": "Port Azur"},
		{"pos": Vector2(2640, 1390), "radius": 120.0, "art": "rock", "width": 410.0, "name": "Korsarenbucht"},
		{"pos": Vector2(1650, 2060), "radius": 135.0, "art": "tropical", "width": 460.0, "name": "Smaragdriff"},
		{"pos": Vector2(2870, 2040), "radius": 150.0, "art": "snow", "width": 500.0, "name": "Frostklippen"},
		{"pos": Vector2(880, 1710), "radius": 118.0, "art": "rock", "width": 390.0, "name": "Schmugglerversteck"},
		{"pos": Vector2(2230, 620), "radius": 125.0, "art": "snow2", "width": 440.0, "name": "Nordwacht"},
		{"pos": Vector2(3580, 1020), "radius": 155.0, "art": "tropical", "width": 520.0, "name": "Sonnenhafen"},
		{"pos": Vector2(3570, 2670), "radius": 130.0, "art": "rock", "width": 450.0, "name": "Drachenzahn"},
		{"pos": Vector2(870, 2670), "radius": 130.0, "art": "snow2", "width": 460.0, "name": "Eiswacht"}]
	_build_grid()
	var starts = [Vector2(1870, 1220), Vector2(2420, 1510), Vector2(1840, 1760),
		Vector2(2230, 1910), Vector2(2990, 1580), Vector2(1170, 1350), Vector2(2420, 870),
		Vector2(3150, 810), Vector2(1130, 2140), Vector2(3310, 2320), Vector2(1810, 2550),
		Vector2(3720, 1520), Vector2(640, 980), Vector2(2940, 2650), Vector2(2170, 2440), Vector2(3650, 600)]
	var names = ["Roter Korsar", "Jadebrigg", "Kupfersegler", "Küstenfregatte", "Goldene Armada", "Eisfregatte", "Schattensegler", "Admiralswache", "Elite-Galeone", "Knochenschiff", "Brennender Holländer", "Schwarzbart", "Königsgaleone", "Kriegsschiff", "Schmuggler", "Fliegender Holländer"]
	for i in starts.size():
		var elite = i % 5 == 4
		npcs.append({"id": i + 1, "name": names[i % names.size()], "kind": "ship", "pos": starts[i],
			"home": starts[i], "heading": Vector2.LEFT, "path": [], "hp": 760 if elite else 420,
			"max_hp": 760 if elite else 420, "speed": 66.0 + float(i % 3) * 8.0,
			"reload": float(i % 4) * 0.6, "repath": 0.0, "state": "patrol", "patrol": i % 4,
			"aggressive": false, "slow": 0.0, "respawn": 0.0, "reward": 110 if elite else 55,
			"art": i, "elite": elite})
	npcs.append({"id": 100, "name": "Tiamat · Tiefenwächter", "kind": "monster", "pos": Vector2(2590, 1750),
		"home": Vector2(2590, 1750), "heading": Vector2.LEFT, "path": [], "hp": 1650,
		"max_hp": 1650, "speed": 48.0, "reload": 1.0, "repath": 0.0, "state": "patrol",
		"patrol": 0, "aggressive": false, "slow": 0.0, "respawn": 0.0, "reward": 240,
		"art": 0, "elite": true})
	_add_drop(START + Vector2(-170, 130), 25)
	_add_drop(START + Vector2(220, -120), 25)
	_add_drop(Vector2(2170, 1780), 30)

func _build_grid() -> void:
	grid.region = Rect2i(0, 0, ceili(WORLD.x / CELL), ceili(WORLD.y / CELL))
	grid.cell_size = Vector2.ONE * CELL
	grid.offset = Vector2.ONE * CELL * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			var cell = Vector2i(x, y)
			grid.set_point_solid(cell, blocked(grid.get_point_position(cell), 38.0))

func blocked(point: Vector2, margin: float = 22.0) -> bool:
	if point.x < margin or point.y < margin or point.x > WORLD.x - margin or point.y > WORLD.y - margin:
		return true
	for island in islands:
		if point.distance_to(island.pos) < float(island.radius) + margin:
			return true
	return false

func segment_free(a: Vector2, b: Vector2) -> bool:
	var steps = maxi(1, ceili(a.distance_to(b) / 18.0))
	for i in range(1, steps + 1):
		if blocked(a.lerp(b, float(i) / steps)):
			return false
	return true

func plan_path(start: Vector2, goal: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if blocked(goal):
		return result
	if segment_free(start, goal):
		result.append(goal)
		return result
	var a = Vector2i(start / CELL)
	var b = Vector2i(goal / CELL)
	if not grid.is_in_boundsv(a) or not grid.is_in_boundsv(b) or grid.is_point_solid(b):
		return result
	if grid.is_point_solid(a):
		var found = false
		for y in range(-2, 3):
			for x in range(-2, 3):
				var n = a + Vector2i(x, y)
				if grid.is_in_boundsv(n) and not grid.is_point_solid(n) and segment_free(start, grid.get_point_position(n)):
					a = n
					found = true
					break
			if found: break
		if not found: return result
	var raw = grid.get_point_path(a, b)
	var current = start
	var index = 0
	while index < raw.size():
		var furthest = index
		for j in range(index, raw.size()):
			if segment_free(current, raw[j]): furthest = j
			else: break
		if not segment_free(current, raw[furthest]): return []
		if current.distance_to(raw[furthest]) > 1:
			result.append(raw[furthest])
		current = raw[furthest]
		index = furthest + 1
	if segment_free(current, goal): result.append(goal)
	return result

func course(point: Vector2) -> bool:
	if int(player.hp) <= 0: return false
	var route = plan_path(player.pos, point)
	if route.is_empty():
		message = "Küste voraus · bitte freies Wasser wählen"
		return false
	player.path = route
	repairing = false
	message = "Kurs gesetzt"
	return true

func actor(id: int) -> Dictionary:
	if id == 0: return player
	for npc in npcs:
		if int(npc.id) == id: return npc
	return {}

func select(id: int) -> void:
	if id > 0 and not actor(id).is_empty() and int(actor(id).hp) > 0:
		target = id
		message = str(actor(id).name) + " anvisiert"
	else:
		target = -1
		firing = false

func set_ammo(index: int) -> void:
	if index < 0 or index >= AMMO_NAMES.size(): return
	ammo_mode = index
	message = ["Vollkugeln geladen", "Kettenkugeln geladen · verlangsamen Schiffe", "Harpunen geladen · gegen Seeungeheuer"][index]

func toggle_repair() -> void:
	if int(player.hp) <= 0 or int(player.hp) >= PLAYER_HP:
		message = "Rumpf ist vollständig intakt"
		return
	if clock - float(player.last_hit) < 6.0:
		message = "Reparatur: erst 6 Sekunden ohne Treffer"
		return
	repairing = not repairing
	if repairing:
		firing = false
		player.path = []
	message = "Reparatur läuft" if repairing else "Reparatur gestoppt"

func step(delta: float) -> void:
	clock += delta
	player.reload = maxf(0, float(player.reload) - delta)
	player.slow = maxf(0, float(player.slow) - delta)
	if int(player.hp) <= 0:
		player.respawn -= delta
		if float(player.respawn) <= 0:
			player.hp = PLAYER_HP
			player.pos = START
			player.last_hit = clock
			message = "Wieder auf See · Rumpf repariert"
	else:
		_move(player, delta)
		if repairing:
			player.hp = minf(PLAYER_HP, float(player.hp) + 90.0 * delta)
			if float(player.hp) >= PLAYER_HP: repairing = false
		if firing and target > 0 and float(player.reload) <= 0:
			_fire_player()
	for npc in npcs:
		_step_npc(npc, delta)
	_step_shots(delta)
	for i in range(drops.size() - 1, -1, -1):
		if int(player.hp) > 0 and player.pos.distance_to(drops[i].pos) < 80:
			var amount = int(drops[i].gold)
			player.gold += amount
			message = "+%d Gold · Beute geborgen" % amount
			_event("loot", drops[i].pos, amount, 0)
			drops.remove_at(i)
	if events.size() > 120: events = events.slice(events.size() - 120)

func _move(body: Dictionary, delta: float) -> void:
	var travel = float(body.speed) * (0.55 if float(body.slow) > 0 else 1.0) * delta
	while travel > 0.01 and not body.path.is_empty():
		var goal: Vector2 = body.path[0]
		var gap: Vector2 = goal - body.pos
		if gap.length() < 2.0:
			body.path.pop_front()
			continue
		body.heading = gap.normalized()
		var amount = minf(travel, gap.length())
		var next: Vector2 = body.pos + body.heading * amount
		if not segment_free(body.pos, next):
			body.path = []
			return
		body.pos = next
		travel -= amount
		if amount >= gap.length(): body.path.pop_front()

func _step_npc(npc: Dictionary, delta: float) -> void:
	if int(npc.hp) <= 0:
		npc.respawn -= delta
		if float(npc.respawn) <= 0:
			npc.hp = npc.max_hp
			npc.pos = npc.home
			npc.aggressive = false
			npc.path = []
		return
	npc.reload = maxf(0, float(npc.reload) - delta)
	npc.slow = maxf(0, float(npc.slow) - delta)
	npc.repath -= delta
	var distance: float = npc.pos.distance_to(player.pos)
	var pursue = int(player.hp) > 0 and (distance < 300 or bool(npc.aggressive)) and npc.pos.distance_to(npc.home) < 900
	if pursue:
		npc.state = "attack" if distance < 390 else "approach"
		if distance > 305 and float(npc.repath) <= 0:
			npc.path = plan_path(npc.pos, player.pos)
			npc.repath = 1.5
		elif distance <= 305:
			npc.path = []
		if distance < 420 and float(npc.reload) <= 0 and segment_free(npc.pos, player.pos):
			_launch(npc.id, 0, "harpoon" if npc.kind == "monster" else "cannon", 36 if npc.elite else 23, 2)
			npc.reload = 3.2 if npc.kind == "monster" else 2.6
	else:
		npc.state = "patrol"
		npc.aggressive = false
		if npc.path.is_empty():
			npc.patrol = (int(npc.patrol) + 1) % 4
			var offsets = [Vector2(140, 0), Vector2(0, 135), Vector2(-145, 0), Vector2(0, -135)]
			var destination: Vector2 = npc.home + offsets[int(npc.patrol)]
			npc.path = plan_path(npc.pos, destination)
	_move(npc, delta)

func _fire_player() -> void:
	var victim = actor(target)
	if victim.is_empty() or int(victim.hp) <= 0:
		firing = false
		return
	if (victim.kind == "monster") != (ammo_mode == 2):
		message = "Harpunen gegen Seeungeheuer" if victim.kind == "monster" else "Voll- oder Kettenkugeln gegen Schiffe"
		firing = false
		return
	if player.pos.distance_to(victim.pos) > 530:
		message = "Ziel außer Reichweite · näher heranfahren"
		player.reload = 0.3
		return
	if not segment_free(player.pos, victim.pos):
		message = "Insel versperrt die Schusslinie"
		player.reload = 0.3
		return
	var count = 1 if ammo_mode == 2 else 3
	if int(player.ammo[ammo_mode]) < count:
		message = "Munition leer · Nachschub in der Werft"
		firing = false
		return
	player.ammo[ammo_mode] -= count
	_launch(0, target, AMMO_NAMES[ammo_mode], [31, 19, 96][ammo_mode], count)
	player.reload = 1.65
	victim.aggressive = true
	repairing = false
	message = "Breitseite!" if ammo_mode != 2 else "Harpune abgefeuert"

func _launch(source_id: int, target_id: int, weapon: String, damage: int, count: int) -> void:
	var source = actor(source_id)
	var destination = actor(target_id)
	if source.is_empty() or destination.is_empty(): return
	for i in count:
		next_id += 1
		var start: Vector2 = source.pos + Vector2(0, (float(i) - float(count - 1) * 0.5) * 13)
		shots.append({"id": next_id, "source": source_id, "target": target_id, "pos": start,
			"start": start, "damage": damage, "weapon": weapon, "age": -float(i) * 0.08,
			"distance": maxf(1, start.distance_to(destination.pos)), "traveled": 0.0})
	_event("muzzle", source.pos, count, source_id)

func _step_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var shot = shots[i]
		shot.age += delta
		if float(shot.age) < 0: continue
		var victim = actor(int(shot.target))
		if victim.is_empty() or int(victim.hp) <= 0 or float(shot.age) > 5:
			shots.remove_at(i)
			continue
		var gap: Vector2 = victim.pos - shot.pos
		var speed = 530.0 if shot.weapon == "harpoon" else 470.0
		var amount = speed * delta
		if gap.length() <= amount + 12:
			_hit(shot, victim)
			shots.remove_at(i)
		else:
			shot.pos += gap.normalized() * amount
			shot.traveled += amount

func _hit(shot: Dictionary, victim: Dictionary) -> void:
	if int(victim.hp) <= 0: return
	victim.hp = maxi(0, int(victim.hp) - int(shot.damage))
	if shot.weapon == "chain": victim.slow = 4.0
	if int(victim.id) == 0:
		player.last_hit = clock
		repairing = false
	_event("impact", victim.pos, shot.damage, victim.id)
	if int(victim.hp) == 0:
		victim.path = []
		victim.respawn = 8.0 if int(victim.id) == 0 else 48.0
		_event("sunk", victim.pos, 0, victim.id)
		if int(victim.id) == 0:
			firing = false
			repairing = false
			message = "Versenkt · Rückkehr in 8 Sekunden"
		elif int(shot.source) == 0:
			kills += 1
			_add_drop(victim.pos, int(victim.reward))
			message = "Ziel versenkt · zur Beute fahren"
			if target == int(victim.id): firing = false

func _add_drop(point: Vector2, gold: int) -> void:
	next_id += 1
	drops.append({"id": next_id, "pos": point, "gold": gold})

func _event(kind: String, point: Vector2, value: int, id: int) -> void:
	events.append({"type": kind, "pos": point, "value": value, "actor": id, "time": clock})

func claim_quest() -> bool:
	if kills < 3 or claimed: return false
	claimed = true
	player.gold += 180
	message = "Auftrag abgeschlossen · +180 Gold"
	return true

func buy_ammo(index: int) -> bool:
	if index < 0 or index > 2 or int(player.hp) <= 0 or int(player.gold) < 30: return false
	player.gold -= 30
	player.ammo[index] += [150, 60, 40][index]
	message = "Munitionsvorrat aufgefüllt"
	return true
