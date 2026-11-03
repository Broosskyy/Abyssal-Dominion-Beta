extends RefCounted
const CONTENT = preload("res://content.gd")
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
var map_id := 0
var docked := false
var level := 1
var xp := 0
var quest_index := 0
var loot_collected := 0
var monster_kills := 0
var elite_kills := 0
var visited := [true, false, false]
var upgrades := {"cannon":0, "harpoon":0, "hull":0, "sails":0}
var portals: Array[Dictionary] = [
	{"pos":Vector2(4070,1600),"destination":1},
	{"pos":Vector2(330,1600),"destination":2}]
var harbor := Vector2(1920,1450)
var base_islands: Array[Dictionary] = []
var base_npcs: Array[Dictionary] = []
var map_states: Dictionary = {}
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
	base_islands = islands.duplicate(true)
	base_npcs = npcs.duplicate(true)
	configure_map(0)

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
	if docked: return false
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
	if docked: return
	if int(player.hp) <= 0 or int(player.hp) >= int(player.max_hp):
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
	if docked: return
	clock += delta
	player.reload = maxf(0, float(player.reload) - delta)
	player.slow = maxf(0, float(player.slow) - delta)
	if int(player.hp) <= 0:
		player.respawn -= delta
		if float(player.respawn) <= 0:
			player.hp = player.max_hp
			player.pos = START
			player.last_hit = clock
			message = "Wieder auf See · Rumpf repariert"
	else:
		_move(player, delta)
		if repairing:
			player.hp = minf(float(player.max_hp), float(player.hp) + 90.0 * delta)
			if float(player.hp) >= float(player.max_hp): repairing = false
		if firing and target > 0 and float(player.reload) <= 0:
			_fire_player()
	for npc in npcs:
		_step_npc(npc, delta)
	_step_shots(delta)
	for i in range(drops.size() - 1, -1, -1):
		if int(player.hp) > 0 and player.pos.distance_to(drops[i].pos) < 80:
			var amount = int(drops[i].gold)
			player.gold += amount
			loot_collected += 1
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
			_launch(npc.id, 0, "harpoon" if npc.kind == "monster" else "cannon", roundi((36.0 if npc.elite else 23.0)*float(CONTENT.MAPS[map_id].enemy_scale)), 2)
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
	if docked or int(player.hp)<=0: return
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
		_launch(0, target, AMMO_NAMES[ammo_mode], weapon_damage(ammo_mode), count)
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
			if victim.kind == "monster": monster_kills += 1
			elif victim.elite: elite_kills += 1
			award_xp(150 if victim.kind == "monster" else (60 if victim.elite else 25))
			_add_drop(victim.pos, int(victim.reward))
			message = "Ziel versenkt · zur Beute fahren"
			if target == int(victim.id): firing = false

func _add_drop(point: Vector2, gold: int) -> void:
	next_id += 1
	drops.append({"id": next_id, "pos": point, "gold": gold, "art":2 if gold>=200 else (1 if gold>=100 else 0)})

func _event(kind: String, point: Vector2, value: int, id: int) -> void:
	events.append({"type": kind, "pos": point, "value": value, "actor": id, "time": clock})

func claim_quest() -> bool:
	var quest = current_quest()
	if quest.is_empty() or quest_progress() < int(quest.goal): return false
	player.gold += int(quest.gold)
	award_xp(int(quest.xp))
	quest_index += 1
	claimed = true
	message = "Auftrag abgeschlossen · +%d Gold · +%d EP" % [quest.gold,quest.xp]
	return true

func buy_ammo(index: int) -> bool:
	if index < 0 or index > 2 or int(player.hp) <= 0 or int(player.gold) < 30: return false
	player.gold -= 30
	player.ammo[index] += [150, 60, 40][index]
	message = "Munitionsvorrat aufgefüllt"
	return true

func xp_required() -> int:
	return 100 + (level - 1) * 70

func award_xp(amount: int) -> void:
	if amount <= 0 or level >= 20: return
	xp += amount
	while level < 20 and xp >= xp_required():
		xp -= xp_required()
		level += 1
		_event("level", player.pos, level, 0)
	if level >= 20: xp = 0

func current_quest() -> Dictionary:
	return CONTENT.QUESTS[quest_index] if quest_index < CONTENT.QUESTS.size() else {}

func quest_progress() -> int:
	var quest = current_quest()
	if quest.is_empty(): return 0
	match str(quest.stat):
		"kills": return kills
		"loot": return loot_collected
		"monsters": return monster_kills
		"elites": return elite_kills
		"north": return 1 if visited[1] else 0
		"abyss": return 1 if visited[2] else 0
	return 0

func weapon_damage(mode: int) -> int:
	var key = "harpoon" if mode == 2 else "cannon"
	var bonus = 0.35 if mode == 2 else 0.25
	return roundi(float([31,19,96][mode]) * (1.0 + float(upgrades[key]) * bonus))

func apply_upgrades() -> void:
	player.max_hp = PLAYER_HP + int(upgrades.hull) * 400
	player.hp = minf(float(player.hp),float(player.max_hp))
	player.speed = PLAYER_SPEED * (1.0 + 0.12 * float(upgrades.sails))

func upgrade_cost(key: String) -> int:
	if not upgrades.has(key) or int(upgrades[key]) >= 3: return -1
	return [150,400,850][int(upgrades[key])]

func buy_upgrade(key: String) -> bool:
	var cost = upgrade_cost(key)
	if not docked or cost < 0 or int(player.gold) < cost: return false
	player.gold -= cost
	upgrades[key] += 1
	apply_upgrades()
	message = "%s auf Stufe %d verbessert" % [CONTENT.UPGRADES[key].name,upgrades[key]]
	return true

func can_dock() -> bool:
	return int(player.hp) > 0 and player.pos.distance_to(harbor) <= 160 and clock - float(player.last_hit) >= 6.0

func dock() -> bool:
	if not can_dock():
		message = "Zum Hafen fahren · Andocken erst 6 Sekunden ohne Treffer"
		return false
	docked = true
	firing = false
	repairing = false
	player.path = []
	shots.clear()
	message = "Im Hafen · Schiff ausrüsten und Vorräte ergänzen"
	return true

func depart() -> void:
	docked = false
	message = "Leinen los · gute Fahrt, Kapitän!"

func harbor_repair_cost() -> int:
	return maxi(0,ceili((float(player.max_hp) - float(player.hp)) / 40.0))

func harbor_repair() -> bool:
	var cost = harbor_repair_cost()
	if not docked or cost <= 0 or int(player.gold) < cost: return false
	player.gold -= cost
	player.hp = player.max_hp
	message = "Rumpf im Trockendock vollständig repariert"
	return true

func near_portal() -> int:
	for portal in portals:
		if player.pos.distance_to(portal.pos) <= 135: return int(portal.destination)
	return -1

func travel(destination: int) -> bool:
	if destination < 0 or destination >= CONTENT.MAPS.size() or destination == map_id or docked or int(player.hp) <= 0: return false
	if near_portal() != destination:
		message = "Für den Kartenwechsel zum Portal fahren"
		return false
	if level < int(CONTENT.MAPS[destination].level):
		message = "Dieses Seegebiet öffnet ab Kapitänsstufe %d" % CONTENT.MAPS[destination].level
		return false
	if clock - float(player.last_hit) < 6.0:
		message = "Kartenwechsel erst 6 Sekunden ohne Treffer"
		return false
	map_states[map_id] = {"npcs":npcs.duplicate(true),"drops":drops.duplicate(true)}
	configure_map(destination)
	player.pos = START
	player.path = []
	firing = false
	repairing = false
	target = -1
	shots.clear()
	events.clear()
	message = "%s erreicht · Karte %s" % [CONTENT.MAPS[map_id].name,CONTENT.MAPS[map_id].code]
	return true

func _map_point(point: Vector2) -> Vector2:
	if map_id == 1: return Vector2(WORLD.x - point.x,point.y)
	if map_id == 2: return Vector2(point.x,WORLD.y - point.y)
	return point

func configure_map(destination: int) -> void:
	map_id = clampi(destination,0,CONTENT.MAPS.size()-1)
	visited[map_id] = true
	var config = CONTENT.MAPS[map_id]
	islands = base_islands.duplicate(true)
	for i in islands.size():
		islands[i].pos = _map_point(base_islands[i].pos)
		islands[i].art = config.art[i]
		if map_id > 0: islands[i].name = (["Eishafen","Frostbucht","Weißes Riff","Gletscherwacht","Eisbrecherbucht","Nordstern","Winterhafen","Frostzahn","Polarwacht"] if map_id == 1 else ["Nebelwacht","Schwarze Bucht","Totenriff","Schattenklippen","Korsarenfestung","Nachtwacht","Dämmerhafen","Drachenzahn","Knochenriff"])[i]
	npcs = base_npcs.duplicate(true)
	for npc in npcs:
		npc.pos = _map_point(npc.pos)
		npc.home = npc.pos
		npc.path = []
		npc.hp = roundi(float(npc.max_hp) * float(config.enemy_scale))
		npc.max_hp = npc.hp
		npc.reward = roundi(float(npc.reward) * float(config.enemy_scale))
		if map_id > 0: npc.name = ("Frost · " if map_id == 1 else "Schatten · ") + str(npc.name)
	if map_states.has(map_id):
		npcs = map_states[map_id].npcs.duplicate(true)
		drops = map_states[map_id].drops.duplicate(true)
	else:
		drops.clear()
		_add_drop(START + Vector2(-170,130),25 + map_id * 15)
		_add_drop(START + Vector2(220,-120),25 + map_id * 15)
		_add_drop(_map_point(Vector2(2170,1780)),30 + map_id * 20)
	portals[0].destination = (map_id + 1) % 3
	portals[1].destination = (map_id + 2) % 3
	_build_grid()

func export_save() -> Dictionary:
	return {"schema":2,"gold":player.gold,"ammo":player.ammo.duplicate(),"skin":player.skin,
		"kills":kills,"claimed":claimed,"quest_index":quest_index,"loot_collected":loot_collected,
		"monster_kills":monster_kills,"elite_kills":elite_kills,"level":level,"xp":xp,
		"upgrades":upgrades.duplicate(),"visited":visited.duplicate(),"map_id":map_id,
		"position":[player.pos.x,player.pos.y],"hp":player.hp,"docked":docked}

func restore_save(data: Dictionary) -> bool:
	if int(data.get("schema",0)) not in [1,2]: return false
	player.gold=clampi(int(data.get("gold",240)),0,99999999)
	player.skin=clampi(int(data.get("skin",22)),0,25)
	kills=maxi(0,int(data.get("kills",0)))
	claimed=bool(data.get("claimed",false))
	quest_index=clampi(int(data.get("quest_index",1 if claimed else 0)),0,CONTENT.QUESTS.size())
	loot_collected=maxi(0,int(data.get("loot_collected",0)))
	monster_kills=maxi(0,int(data.get("monster_kills",0)))
	elite_kills=maxi(0,int(data.get("elite_kills",0)))
	level=clampi(int(data.get("level",1)),1,20)
	xp=clampi(int(data.get("xp",0)),0,xp_required()-1)
	var saved_upgrades: Variant=data.get("upgrades",{})
	if saved_upgrades is Dictionary:
		for key in CONTENT.UPGRADE_KEYS:upgrades[key]=clampi(int(saved_upgrades.get(key,0)),0,3)
	apply_upgrades()
	var stock: Variant=data.get("ammo",[])
	if stock is Array and stock.size()==3:
		for i in 3:player.ammo[i]=clampi(int(stock[i]),0,999999)
	var saved_visited: Variant=data.get("visited",[])
	if saved_visited is Array and saved_visited.size()==3:
		for i in 3:visited[i]=bool(saved_visited[i])
	configure_map(clampi(int(data.get("map_id",0)),0,2))
	player.pos=START
	var position: Variant=data.get("position",[])
	if position is Array and position.size()==2:
		var point=Vector2(float(position[0]),float(position[1]))
		if point.is_finite() and not blocked(point):player.pos=point
	player.hp=clampi(int(data.get("hp",player.max_hp)),0,int(player.max_hp))
	if int(player.hp)==0:player.respawn=8.0
	docked=bool(data.get("docked",false)) and can_dock()
	return true
