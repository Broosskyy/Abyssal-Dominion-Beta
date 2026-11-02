extends RefCounted
## Shared authoritative LAN prototype. No client positions, damage, or balances accepted.
const PLANNER = preload("res://scripts/classic/classic_route_planner.gd")
const SPEED := 11.0
var players: Dictionary = {}
var npcs: Array[Dictionary] = []
var islands: Array[Dictionary] = []
var drops: Dictionary = {}
var events: Array[Dictionary] = []
var tick := 0
var serial := 0
var enemy_clock := 3.0

func _init() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/classic_zone.json"))
	for item in config.islands:
		islands.append({"position": Vector3(item.x, 0, item.z), "radius": float(item.radius)})
	for item in config.npcs:
		var npc: Dictionary = item.duplicate()
		npc["max_hp"] = int(npc.hp)
		npcs.append(npc)

func join(id: int) -> void:
	players[id] = {"id": id, "name": "Kapitän %d" % id, "x": float(posmod(id - 2,4) * 14), "z": 0.0,
		"yaw": 0.0, "hp": 100, "gold": 0, "kills": 0, "ammo": [100, 60, 18],
		"mode": "cannon", "target": -1, "firing": false, "reload": 0.0,
		"repair": 0.0, "respawn": 0.0, "path": [], "seq": 0, "message": "Verbunden · gemeinsame Testkarte"}

func command(id: int, cmd: Dictionary) -> bool:
	if not players.has(id) or not cmd.get("seq") is float and not cmd.get("seq") is int:
		return false
	var p: Dictionary = players[id]
	var seq := float(cmd.seq)
	if not is_finite(seq) or seq != floor(seq) or seq <= int(p.seq) or seq > int(p.seq) + 10000:
		return false
	p.seq = int(seq)
	var op := str(cmd.get("op", ""))
	if op == "hello":
		p.name = str(cmd.get("name", "Kapitän")).strip_edges().left(24)
		return true
	if int(p.hp) <= 0:
		return false
	match op:
		"move":
			if not _number(cmd.get("x")) or not _number(cmd.get("z")):
				return false
			var goal := Vector2(float(cmd.x), float(cmd.z))
			var path := PLANNER.plan(Vector2(p.x,p.z),goal,islands)
			if path.is_empty():
				p.message = "Kein sicherer Kurs"
				return false
			p.path = Array(path)
			p.message = "Kurs gesetzt"
		"target":
			if not _number(cmd.get("target")):
				return false
			var index := int(cmd.target)
			if index < -1 or index >= npcs.size():
				return false
			p.target = index
		"ammo":
			var mode := str(cmd.get("mode", ""))
			if mode not in ["cannon", "harpoon", "chain"]:
				return false
			p.mode = mode
			p.firing = false
		"fire":
			if not cmd.get("enabled") is bool:
				return false
			p.firing = cmd.enabled
		"repair":
			if float(p.repair) <= 0.0 and int(p.hp) < 100:
				p.hp = mini(100,int(p.hp)+35)
				p.repair = 18.0
		"buy":
			if not _number(cmd.get("item")):
				return false
			var item := int(cmd.item)
			if item < 0 or item > 2:
				return false
			var price: int = [15,18,20][item]
			if int(p.gold) < price:
				p.message = "Nicht genug Gold"
				return false
			p.gold -= price
			p.ammo[item] += [50,25,15][item]
		_:
			return false
	return true

func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

func step(dt: float) -> void:
	tick += 1
	for id in players:
		var p: Dictionary = players[id]
		p.repair = maxf(0.0, float(p.repair)-dt)
		p.reload = maxf(0.0, float(p.reload)-dt)
		if int(p.hp) <= 0:
			p.respawn -= dt
			if float(p.respawn) <= 0:
				p.hp = 100
				p.x = 0.0
				p.z = 0.0
			continue
		var travel := SPEED * dt
		while travel > 0 and not p.path.is_empty():
			var pos := Vector2(p.x,p.z)
			var goal: Vector2 = p.path[0]
			var distance := pos.distance_to(goal)
			if distance < 0.001:
				p.path.pop_front()
				continue
			var direction := pos.direction_to(goal)
			p.yaw = atan2(-direction.x,-direction.y)
			var amount := minf(travel,distance)
			pos += direction * amount
			p.x = pos.x
			p.z = pos.y
			travel -= amount
			if amount >= distance:
				p.path.pop_front()
		if p.firing and float(p.reload) <= 0:
			_shoot(id,p)
		for key in drops.keys():
			var d: Dictionary = drops[key]
			if int(d.owner) == id and Vector2(p.x,p.z).distance_to(Vector2(d.x,d.z)) <= 5.0:
				p.gold += int(d.gold)
				p.message = "+%d Gold eingesammelt" % int(d.gold)
				drops.erase(key)
	enemy_clock -= dt
	if enemy_clock <= 0:
		enemy_clock = 3.0
		for id in players:
			var p: Dictionary = players[id]
			if int(p.hp) <= 0:
				continue
			var attackers := 0
			for n in npcs:
				if int(n.hp) > 0 and n.kind == "ship" and Vector2(n.x,n.z).distance_to(Vector2(p.x,p.z)) < 23 and attackers < 2:
					attackers += 1
			p.hp = maxi(0,int(p.hp)-attackers*5)
			if int(p.hp) == 0:
				p.path = []
				p.firing = false
				p.respawn = 8.0
				p.message = "Versenkt · Rückkehr in 8 Sekunden"
	# Bound event memory; clients track monotonically increasing event IDs.
	if events.size() > 128:
		events = events.slice(events.size()-128)

func _shoot(id: int, p: Dictionary) -> void:
	var target := int(p.target)
	if target < 0 or target >= npcs.size() or int(npcs[target].hp) <= 0:
		p.firing = false
		return
	var n: Dictionary = npcs[target]
	var monster: bool = n.kind == "monster"
	if monster != (p.mode == "harpoon"):
		p.message = "Harpunen gegen Monster · Kanonen gegen Schiffe"
		p.firing = false
		return
	var range_limit := 35.0 if monster else 42.0
	if Vector2(p.x,p.z).distance_to(Vector2(n.x,n.z)) > range_limit:
		p.message = "Außer Reichweite"
		return
	var slot: int = {"cannon":0,"harpoon":1,"chain":2}[p.mode]
	if int(p.ammo[slot]) <= 0:
		p.firing = false
		p.message = "Munition leer"
		return
	p.ammo[slot] -= 1
	p.reload = 1.2
	var damage: int = [24,20,12][slot]
	n.hp = maxi(0,int(n.hp)-damage)
	serial += 1
	events.append({"id":serial,"source":id,"target":target,"damage":damage,"mode":p.mode,"x":p.x,"z":p.z})
	if int(n.hp) == 0:
		p.kills += 1
		drops[str(serial)] = {"owner":id,"x":n.x,"z":n.z,"gold":50}
		p.firing = false
		p.message = "Versenkt · Beute einsammeln"

func snapshot() -> Dictionary:
	var public: Array = []
	for p in players.values():
		var item: Dictionary = p.duplicate(true)
		item.erase("path")
		item["moving"] = not p.path.is_empty()
		public.append(item)
	return {"type":"snapshot","tick":tick,"players":public,"npcs":npcs,"drops":drops,"events":events}
