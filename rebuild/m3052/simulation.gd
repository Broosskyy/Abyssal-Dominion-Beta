extends RefCounted
const CONTENT = preload("res://content.gd")
const NAV=preload("res://navigation.gd")
const STAFF=preload("res://staff.gd")
const GUILD_OPS = preload("res://sim_guild_ops.gd")
const BONUS_OPS = preload("res://sim_bonus_ops.gd")
const STAFF_OPS = preload("res://sim_staff_ops.gd")
const LOOKALIKE := {"0":"O","1":"I","3":"E","4":"A","5":"S","7":"T","8":"B"}
var island_shapes: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/visuals/island_collision.json")).entries
## Independent fixed-step sea simulation. No dependency on legacy map scripts.
const WORLD := Vector2(4400, 3200)
const CELL := 48
const PLAYER_SPEED := 165.0
const PLAYER_HP := 2400
const PLAYER_SHIELD := 1000
const SHIELD_DELAY := 8.0
const BASE_CANNON_SLOTS := 10
const MAX_CANNONS := 40
const BASE_RELOAD := 1.65
const START := Vector2(2100, 1450)
const AMMO_NAMES := ["cannon", "chain", "harpoon", "flare", "pumpkin", "snow", "ice", "fire", "poison", "shrapnel", "lightning", "holy", "shadow", "wind", "earth", "water", "cursed", "bleed", "necro", "gold", "crystal", "explosive", "arcane", "spectral", "lava", "light", "armor_piercing", "gas"]
const AMMO_LABELS := ["Vollkugeln geladen", "Kettenkugeln geladen · verlangsamen Schiffe", "Harpunen geladen · gegen Seeungeheuer", "Leuchtkugeln geladen · markieren das Ziel", "Kürbismunition geladen · Splitter im Umkreis", "Schneemunition geladen · starke Verlangsamung", "Eismunition geladen · friert das Ziel ein", "Feuerkugeln geladen · Grafik-Beta", "Giftkugeln geladen · Grafik-Beta", "Schrapnellkugeln geladen · Grafik-Beta", "Blitzkugeln geladen · Grafik-Beta", "Heilige Kugeln geladen · Grafik-Beta", "Schattenkugeln geladen · Grafik-Beta", "Wirbelkugeln geladen · Grafik-Beta", "Erdkugeln geladen · Grafik-Beta", "Wasserkugeln geladen · Grafik-Beta", "Fluchkugeln geladen · Grafik-Beta", "Blutkugeln geladen · Grafik-Beta", "Nekrokugeln geladen · Grafik-Beta", "Goldkugeln geladen · Grafik-Beta", "Kristallkugeln geladen · Grafik-Beta", "Explosivkugeln geladen · Grafik-Beta", "Arkankugeln geladen · Grafik-Beta", "Geisterkugeln geladen · Grafik-Beta", "Lavakugeln geladen · Grafik-Beta", "Lichtkugeln geladen · Grafik-Beta", "Panzerbrecher geladen · Grafik-Beta", "Gaskugeln geladen · Grafik-Beta"]
var player: Dictionary
# Retired historical skins 0-30 migrate to shaded ship (skin 0).
# Only schema 5+ saves can select separate Corsair test skin 1 and ten new Elite color skins 2-11.
const FINAL_PLAYER_SKIN := 0
const ELITE_ONE_PLAYER_SKIN := 1
## Local captain identity until the server issues persistent multiplayer IDs.
var captain_id := ""
var npcs: Array[Dictionary] = []
var islands: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var sparkles: Array[Dictionary] = []
var events: Array[Dictionary] = []
var clock := 0.0
var next_id := 1000
var grid := AStarGrid2D.new()
var rng := RandomNumberGenerator.new()
var firing := false
var repairing := false
var target := -1
var pending_portal := -1
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
var tower_kills := 0
var visited: Array = []
var upgrades := {"cannon":0, "hull":0, "sails":0, "crew":0, "harpoon":0, "war":0}
var supplies := {"powder":10, "plates":10, "repair_kit":2, "shield_charge":2,"skyfire":2,"healing_amulet":2,"blessing_flask":1}
var powder_on := false
var plates_on := false
var cooldowns := {"repair_kit":0.0, "shield_charge":0.0}
var buffs := {"blessing":0.0, "tide_deck":0.0, "storm_deck":0.0, "salvage_deck":0.0}
var essence := 3
var fragments := 0
# Assembled parchment segments for Bronze/Silber/Gold, retained across restarts.
var bonus_pieces := [0,0,0]
var scrolls := [0, 0, 0]
var kessel_meter := 0
var kessel_throws := 0
var free_flask_day := ""
var decks: Array = []
var deck_slots := [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]
var bonus: Dictionary = {}
var bonus_runs := 0
var captain_name := "Kapitän"
var battle_points := 0 # Awarded only by an authoritative PvP server, never NPC kills.
const EXPANSION=preload("res://sea_expansion.gd")
var event_mode := "halloween"
var event_tokens := {"halloween":0,"columbus":0}
var event_pickups: Array[Dictionary]=[]
var rewards := preload("res://reward_ledger.gd").new()
var guild_holdings: Dictionary={}
var tower_levels: Array = CONTENT.normalized_tower_levels()
var guild: Dictionary = {}
var fortress_conquests := 0
var fortress_hold := 0.0
var portals: Array[Dictionary] = []
const HARBOR_SIZE := Vector2(350,350)
const HARBOR_OFFSET := Vector2(343,231)
var harbor_outline := PackedVector2Array()
var harbor_bounds := Rect2()
var harbor := Vector2(1920,1450)
var base_islands: Array[Dictionary] = []
var base_npcs: Array[Dictionary] = []
var map_states: Dictionary = {}
var staff := STAFF.new()
var staff_kills := 0
var staff_marked := false
var message := "Seekarte antippen: Kurs setzen · Schiff antippen: Ziel wählen"

func _init() -> void:
	visited.resize(CONTENT.MAPS.size());visited.fill(false);visited[0]=true
	for key: String in CONTENT.SUPPLY_KEYS:
		if not supplies.has(key):supplies[key]=0
		if not cooldowns.has(key):cooldowns[key]=0.0
	for key in ["wind_draught","smoke_bomb","salvage_charm"]:buffs[key]=0.0
	captain_id = Crypto.new().generate_random_bytes(6).hex_encode().to_upper()
	rng.seed = 3060
	var fresh_skin: int=FINAL_PLAYER_SKIN
	player = {"id": 0, "pos": START, "heading": Vector2(-1, 0), "path": [], "hp": PLAYER_HP,
		"max_hp": PLAYER_HP, "shield": PLAYER_SHIELD, "max_shield": PLAYER_SHIELD, "speed": PLAYER_SPEED,
		"reload": 0.0, "gold": 240, "ammo": [600, 120, 100, 40, 24, 40, 24, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12], "cannons": BASE_CANNON_SLOTS, "skin": fresh_skin,
		"last_hit": -100.0, "respawn": 0.0, "slow": 0.0}
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
	# Atomic visual migration: never publish new names/stats over old hull art.
	# Only enable the nine-model roster when every one of its PNG sprites exists.
	var meshy_ready=true
	for spec: Dictionary in CONTENT.NPC_MESHY_ROSTER:
		if not ResourceLoader.exists("res://assets/npc/meshy/models/"+str(spec.key)+".glb"):
			meshy_ready=false
			break
	var legacy_names=["Roter Korsar","Jadebrigg","Kupfersegler","Küstenfregatte","Goldene Armada","Eisfregatte","Schattensegler","Admiralswache","Elite-Galeone","Knochenschiff","Brennender Holländer","Schwarzbart","Königsgaleone","Kriegsschiff","Schmuggler","Fliegender Holländer"]
	for i in starts.size():
		var spec: Dictionary=CONTENT.NPC_MESHY_ROSTER[int(CONTENT.NPC_MESHY_ASSIGNMENTS[i])]
		var elite=bool(spec.elite) if meshy_ready else i%5==4
		var hull=int(spec.hp) if meshy_ready else (760 if elite else 420)
		var shield=int(spec.shield) if meshy_ready else (roundi(hull*.25) if elite else 0)
		var name=str(spec.name) if meshy_ready else legacy_names[i]
		npcs.append({"id":i+1,"name":name,"kind":"ship","pos":starts[i],
			"home":starts[i],"heading":Vector2.LEFT,"path":[],"hp":hull,"max_hp":hull,
			"shield":shield,"max_shield":shield,"speed":float(spec.speed) if meshy_ready else 38.0+float(i%3)*3.0,
			"power":int(spec.power) if meshy_ready else (36 if elite else 23),"reload":float(i%4)*.6,"repath":0.0,"state":"patrol",
			"patrol":i%4,"aggressive":false,"slow":0.0,"respawn":0.0,
			"reward":int(spec.reward) if meshy_ready else (110 if elite else 55),"art":i,"elite":elite,
			"visual_key":str(spec.key),"view_count":4,"renderer":"mesh" if meshy_ready else "sprite",
			"navigation":"free" if meshy_ready else "four_diagonal","last_hit":-100.0})
	npcs.append({"id": 100, "name": "Tiamat · Tiefenwächter", "kind": "monster", "pos": Vector2(2590, 1750),
		"home": Vector2(2590, 1750), "heading": Vector2.LEFT, "path": [], "hp": 1650,
		"max_hp": 1650, "shield": 0, "max_shield": 0, "speed": 28.0, "reload": 1.0, "repath": 0.0, "state": "patrol",
		"patrol": 0, "aggressive": false, "slow": 0.0, "respawn": 0.0, "reward": 240,
		"art": 0, "elite": true, "last_hit": -100.0})
	_add_drop(START + Vector2(-170, 130), 25)
	_add_drop(START + Vector2(220, -120), 25)
	_add_drop(Vector2(2170, 1780), 30)
	base_islands = islands.duplicate(true)
	base_npcs = npcs.duplicate(true)
	configure_map(0)

func _build_grid() -> void:
	for island: Dictionary in islands:
		var polygon=PackedVector2Array()
		if bool(island.get("guild_fortress",false)):
			# Deliberately concave U coast: wide navigable water basin and
			# unblocked southern entrance, not an artificial solid island.
			var dimensions: Vector2=Vector2(float(island.width),float(island.width)*CONTENT.GUILD_FORTRESS_ASPECT)
			var outline: Array[Vector2]=[
				Vector2(.146,.878),Vector2(.092,.75),Vector2(.048,.54),Vector2(.09,.30),
				Vector2(.23,.13),Vector2(.43,.075),Vector2(.67,.06),Vector2(.85,.20),
				Vector2(.96,.49),Vector2(.89,.79),Vector2(.84,.878),Vector2(.70,.915),
				Vector2(.692,.68),Vector2(.64,.422),Vector2(.50,.380),Vector2(.399,.422),
				Vector2(.305,.68),Vector2(.298,.915)]
			for vertex: Vector2 in outline:
				polygon.append(island.pos+(vertex-Vector2(.5,.65))*dimensions)
		else:
			var shape: Dictionary=island_shapes[str(island.art)]
			var dimensions=Vector2(float(island.width),float(island.width)*float(shape.size[1])/float(shape.size[0]))
			for vertex: Array in shape.points:polygon.append(island.pos+(Vector2(vertex[0],vertex[1])-Vector2(0.5,0.65))*dimensions)
		island.outline=polygon
		var bounds=Rect2(polygon[0],Vector2.ZERO)
		for vertex: Vector2 in polygon:bounds=bounds.expand(vertex)
		island.bounds=bounds
	grid.region = Rect2i(0, 0, ceili(WORLD.x / CELL), ceili(WORLD.y / CELL))
	grid.cell_size = Vector2.ONE * CELL
	grid.offset = Vector2.ONE * CELL * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			var cell = Vector2i(x, y)
			grid.set_point_solid(cell, blocked(grid.get_point_position(cell), 48.0))

func blocked(point: Vector2, margin: float = 36.0) -> bool:
	if point.x < margin or point.y < margin or point.x > WORLD.x - margin or point.y > WORLD.y - margin:
		return true
	if not harbor_outline.is_empty() and harbor_bounds.grow(margin).has_point(point):
		if Geometry2D.is_point_in_polygon(point,harbor_outline):return true
		for i in harbor_outline.size():
			if Geometry2D.get_closest_point_to_segment(point,harbor_outline[i],harbor_outline[(i+1)%harbor_outline.size()]).distance_to(point)<margin:return true
	for island in islands:
		if not island.bounds.grow(margin).has_point(point):continue
		var polygon: PackedVector2Array=island.outline
		if Geometry2D.is_point_in_polygon(point,polygon):return true
		for i in polygon.size():
			if Geometry2D.get_closest_point_to_segment(point,polygon[i],polygon[(i+1)%polygon.size()]).distance_to(point)<margin:return true
	return false

func on_land(point: Vector2) -> bool:
	if not harbor_outline.is_empty() and Geometry2D.is_point_in_polygon(point,harbor_outline):return true
	for island in islands:
		if island.bounds.has_point(point) and Geometry2D.is_point_in_polygon(point,island.outline):return true
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

func plan_actor_path(body: Dictionary,goal: Vector2) -> Array[Vector2]:
	var base=plan_path(body.pos,goal)
	if int(body.get("view_count",8))!=4 or str(body.get("renderer","sprite"))!="sprite":return base
	var result: Array[Vector2]=[]
	var before: Vector2=body.pos
	for waypoint: Vector2 in base:
		var accepted=false
		var cross_heading: float=body.heading.y if absf(waypoint.x-before.x)>=absf(waypoint.y-before.y) else body.heading.x
		var preferred_side=1 if cross_heading>0.01 else (-1 if cross_heading< -0.01 else (1 if int(body.id)%2==0 else -1))
		for size in [150.0,96.0,48.0,24.0,12.0]:
			for side in [preferred_side,-preferred_side]:
				var legs=NAV.diagonal_leg(before,waypoint,size,side)
				var cursor=before
				var safe=true
				for leg: Vector2 in legs:
					if not segment_free(cursor,leg):safe=false;break
					cursor=leg
				if safe:
					result.append_array(legs);accepted=true;break
			if accepted:break
		if not accepted:return []
		before=waypoint
	return result

func course(point: Vector2) -> bool:
	pending_portal=-1
	if docked: return false
	if int(player.hp) <= 0: return false
	var route: Array[Vector2] = []
	if staff.flag("no_collision"): route.append(point.clamp(Vector2(40, 40), WORLD - Vector2(40, 40)))
	else: route = plan_path(player.pos, point)
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

func clear_target() -> void:
	# Stops fresh cannon salvos immediately. Already-fired projectiles keep
	# their trajectory; navigation, pending portals and ammo are untouched.
	target = -1
	firing = false
	message = "Zielauswahl aufgehoben"

func select(id: int) -> void:
	if id > 0 and not actor(id).is_empty() and int(actor(id).hp) > 0:
		if target != id:firing = false
		target = id
		message = str(actor(id).name) + " anvisiert"
	else:
		clear_target()

func set_ammo(index: int) -> void:
	if index < 0 or index >= AMMO_NAMES.size(): return
	ammo_mode = index
	message = AMMO_LABELS[index]

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
		pending_portal=-1
		player.path = []
	message = "Reparatur läuft" if repairing else "Reparatur gestoppt"

# --- Ship supplies -----------------------------------------------------------------

func toggle_supply(key: String) -> bool:
	if not key in ["powder","plates"]: return false
	var active: bool = powder_on if key == "powder" else plates_on
	if not active and int(supplies[key]) <= 0:
		message = "Keine %s mehr · Nachschub im Hafen oder im Kessel" % CONTENT.SUPPLIES[key].name
		return false
	if key == "powder": powder_on = not powder_on
	else: plates_on = not plates_on
	active = not active
	message = "%s %s" % [CONTENT.SUPPLIES[key].name, "aktiv" if active else "aus"]
	return true

func use_supply(key: String) -> bool:
	if not CONTENT.SUPPLIES.has(key) or bool(CONTENT.SUPPLIES[key].toggle) or docked or int(player.hp) <= 0: return false
	var config: Dictionary = CONTENT.SUPPLIES[key]
	if float(cooldowns[key]) > 0:
		message = "%s lädt noch %d s" % [config.name, ceili(float(cooldowns[key]))]
		return false
	if int(supplies[key]) <= 0:
		message = "Keine %s mehr · Nachschub im Hafen oder im Kessel" % config.name
		return false
	if key=="skyfire":
		var victim: Dictionary=actor(target)
		if victim.is_empty() or int(victim.hp)<=0 or victim.kind=="monster" or (victim.kind=="tower" and tower_friendly()) or player.pos.distance_to(victim.pos)>650 or (victim.kind!="tower" and not segment_free(player.pos,victim.pos)):
			message="Himmelsbrand: Schiff oder feindlichen Turm in 650 m Reichweite anvisieren"
			return false
		_launch(0,target,"explosive",240,1);victim.aggressive=true;repairing=false
	elif key=="healing_amulet" or key=="blessing_flask":
		if key=="healing_amulet" and float(player.hp)>=float(player.max_hp):return false
		player.hp=minf(float(player.max_hp),float(player.hp)+float(player.max_hp)*(.25 if key=="healing_amulet" else .20))
		if key=="blessing_flask":activate_blessing(120)
	elif key == "repair_kit":
		if float(player.hp) >= float(player.max_hp):
			message = "Rumpf ist vollständig intakt"
			return false
		player.hp = minf(float(player.max_hp), float(player.hp) + float(player.max_hp) * 0.35)
	elif key == "shield_charge":
		if float(player.shield) >= float(player.max_shield):
			message = "Schild ist voll geladen"
			return false
		player.shield = minf(float(player.max_shield), float(player.shield) + float(player.max_shield) * 0.5)
	elif key=="cleansing_rum":
		if float(player.slow)<=0:return false
		player.slow=0.0
	elif key=="wind_draught":buffs.wind_draught=20.0
	elif key=="smoke_bomb":buffs.smoke_bomb=8.0
	elif key=="salvage_charm":buffs.salvage_charm=60.0
	supplies[key] -= 1
	cooldowns[key] = float(config.cooldown)
	_event("supply", player.pos, 0, 0)
	message = "%s eingesetzt" % config.name
	return true

func buy_supply(key: String) -> bool:
	if not CONTENT.SUPPLIES.has(key) or not docked: return false
	var config: Dictionary = CONTENT.SUPPLIES[key]
	if int(player.gold) < int(config.price): return false
	player.gold -= int(config.price)
	supplies[key] += int(config.pack)
	message = "%d× %s gekauft" % [config.pack, config.name]
	return true

func buy_cannons() -> bool:
	if not docked or int(player.cannons) >= MAX_CANNONS or int(player.gold) < cannon_price(): return false
	player.gold -= cannon_price()
	player.cannons = mini(MAX_CANNONS, int(player.cannons) + 2)
	message = "2 Kanonen gekauft · %d an Bord" % player.cannons
	return true

func cannon_price() -> int:
	return 160 + maxi(0, int(player.cannons) - BASE_CANNON_SLOTS) * 20

# --- Buffs, decks and derived ship values ------------------------------------------

func has_blessing() -> bool:
	return float(buffs.blessing) > 0

func activate_blessing(seconds: float = CONTENT.BLESSING_SECONDS) -> void:
	var before := float(player.max_hp)
	buffs.blessing = maxf(float(buffs.blessing), seconds)
	apply_upgrades()
	player.hp = minf(float(player.max_hp), float(player.hp) + maxf(0, float(player.max_hp) - before))
	_event("blessing", player.pos, 0, 0)

func add_tide_deck(seconds: float) -> void:
	buffs.tide_deck = minf(CONTENT.TIDE_DECK_CAP, float(buffs.tide_deck) + seconds)
	_event("tide_deck", player.pos, 0, 0)

func deck_value(type: String) -> float:
	var total := 0.0
	for slot in deck_slots:
		if int(slot) < 0 or int(slot) >= decks.size(): continue
		var deck: Dictionary = decks[int(slot)]
		if str(deck.type) == type: total += float(CONTENT.DECKS[type].values[int(deck.tier)])
	return total

func cannon_slots() -> int:
	return BASE_CANNON_SLOTS + roundi(deck_value("cannon")) + (10 if float(buffs.tide_deck) > 0 else 0) + (5 if has_blessing() else 0)

func equipped_cannons() -> int:
	return mini(int(player.cannons), cannon_slots())

func owns_deck(type: String, tier: int) -> bool:
	for deck: Dictionary in decks:
		if str(deck.type) == type and int(deck.tier) == tier: return true
	return false

func grant_deck(type: String, tier: int, purchased: bool = false) -> bool:
	if not CONTENT.DECKS.has(type): return false
	tier = clampi(tier, 0, CONTENT.DECK_TIERS.size() - 1)
	var title := "%s %s" % [CONTENT.DECKS[type].name, CONTENT.DECK_TIERS[tier]]
	if not purchased and owns_deck(type, tier):
		essence += CONTENT.DUPLICATE_DECK_ESSENCE
		message = "%s doppelt · in %d Gezeitenessenz umgewandelt" % [title, CONTENT.DUPLICATE_DECK_ESSENCE]
		return false
	if decks.size()>=CONTENT.DECK_INVENTORY_MAX:
		message="Decklager voll";return false
	decks.append({"type":type, "tier":tier})
	for i in deck_slots.size():
		if int(deck_slots[i]) < 0:
			deck_slots[i] = decks.size() - 1
			break
	apply_upgrades()
	message = "Neues Deck: %s" % title
	return true

func equip_deck(index: int, slot: int) -> bool:
	if index < 0 or index >= decks.size() or slot < 0 or slot >= deck_slots.size(): return false
	if not docked:
		message = "Decks werden im Hafen umgebaut"
		return false
	# A physical deck may move between slots, but never occupy two slots at once.
	for other in deck_slots.size():
		if other!=slot and int(deck_slots[other])==index:deck_slots[other]=-1
	deck_slots[slot] = index
	apply_upgrades()
	message = "%s montiert" % CONTENT.DECKS[str(decks[index].type)].name
	return true

func unequip_deck(slot: int) -> bool:
	if slot < 0 or slot >= deck_slots.size() or int(deck_slots[slot]) < 0 or not docked: return false
	deck_slots[slot] = -1
	apply_upgrades()
	message = "Deckplatz %d frei" % (slot + 1)
	return true

func buy_deck(type: String) -> bool:
	if not docked or not CONTENT.DECKS.has(type) or decks.size()>=CONTENT.DECK_INVENTORY_MAX:return false
	var price=int(CONTENT.DECKS[type].price)
	if int(player.gold)<price:return false
	if not grant_deck(type,0,true):return false
	player.gold-=price
	return true

func upgrade_deck(index: int) -> bool:
	if not docked or index<0 or index>=decks.size():return false
	var tier=int(decks[index].tier)
	if tier>=CONTENT.DECK_TIERS.size()-1:return false
	if level<int(CONTENT.DECK_UPGRADE_LEVEL[tier]):
		message="%sdecks ab Kapitänsstufe %d" % [CONTENT.DECK_TIERS[tier+1],CONTENT.DECK_UPGRADE_LEVEL[tier]];return false
	var gold=int(CONTENT.DECK_UPGRADE_GOLD[tier])
	var cost=int(CONTENT.DECK_UPGRADE_ESSENCE[tier])
	if int(player.gold)<gold or essence<cost:return false
	player.gold-=gold;essence-=cost
	decks[index].tier=tier+1
	apply_upgrades()
	message="Deck zu %s verbessert" % CONTENT.DECK_TIERS[tier+1]
	return true

func add_special_deck(key: String,seconds: float) -> bool:
	if not CONTENT.SPECIAL_DECKS.has(key) or seconds<=0:return false
	buffs[key]=minf(CONTENT.TIDE_DECK_CAP,float(buffs[key])+seconds)
	apply_upgrades()
	message="%s aktiv" % CONTENT.SPECIAL_DECKS[key].name
	return true

func buy_special_deck(key: String) -> bool:
	if not docked or not CONTENT.SPECIAL_DECKS.has(key):return false
	var config: Dictionary=CONTENT.SPECIAL_DECKS[key]
	if level<int(config.level) or int(player.gold)<int(config.price):return false
	player.gold-=int(config.price)
	return add_special_deck(key,float(config.seconds))

func reload_time() -> float:
	return BASE_RELOAD * (1.0 - 0.04 * float(upgrades.crew))

func loot_gold(amount: int) -> int:
	var factor := (1.2 if float(buffs.get("salvage_charm",0))>0 else 1.0) + 0.08 * float(upgrades.crew) + deck_value("logistics") / 100.0 + (0.1 if guild_island_held() else 0.0) + (0.15 if float(buffs.salvage_deck)>0 else 0.0)
	return roundi(float(amount) * factor)

# --- Simulation step ---------------------------------------------------------------

func _tick_timers(delta: float) -> void:
	for key in ["wind_draught","smoke_bomb","salvage_charm"]:buffs[key]=maxf(0,float(buffs[key])-delta)
	for key in cooldowns.keys(): cooldowns[key] = maxf(0.0, float(cooldowns[key]) - delta)
	if has_blessing():
		buffs.blessing = maxf(0.0, float(buffs.blessing) - delta)
		if not has_blessing():
			apply_upgrades()
			message = "Kristallsegen verblasst"
	if float(buffs.tide_deck) > 0:
		buffs.tide_deck = maxf(0.0, float(buffs.tide_deck) - delta)
		if float(buffs.tide_deck) <= 0: message = "Gezeitendeck abgelaufen · Kanonenplätze wieder %d" % cannon_slots()
	for key: String in CONTENT.SPECIAL_DECKS:
		if float(buffs[key])<=0:continue
		buffs[key]=maxf(0.0,float(buffs[key])-delta)
		if float(buffs[key])<=0:
			apply_upgrades();message="%s abgelaufen" % CONTENT.SPECIAL_DECKS[key].name
	for key: String in guild_holdings:
		if int(key)!=map_id:guild_holdings[key].remaining=maxf(0,float(guild_holdings[key].remaining)-delta)
	if fortress_hold > 0:
		fortress_hold = maxf(0.0, fortress_hold - delta)
		if fortress_hold <= 0 and not guild.is_empty(): message = "Korsaren erobern die Festung zurück"
	if int(player.hp) > 0 and clock - float(player.last_hit) >= SHIELD_DELAY:
		player.shield = minf(float(player.max_shield), float(player.shield) + float(player.max_shield) * 0.05 * delta)
	for sparkle in sparkles:
		if float(sparkle.respawn) > 0:
			sparkle.respawn = float(sparkle.respawn) - delta
			if float(sparkle.respawn) <= 0: sparkle.pos = _sparkle_point()

func step(delta: float) -> void:
	clock += delta
	_tick_timers(delta)
	player.reload = maxf(0, float(player.reload) - delta)
	player.slow = maxf(0, float(player.slow) - delta)
	if docked:
		for npc in npcs:_step_npc(npc,delta)
		return
	if int(player.hp) <= 0:
		player.respawn -= delta
		if float(player.respawn) <= 0:
			player.hp = player.max_hp
			player.shield = player.max_shield
			player.pos = START
			player.last_hit = clock
			message = "Neuer Versuch · die Welle wartet" if in_bonus_map() else "Wieder auf See · Rumpf repariert"
	else:
		_move(player, delta)
		if pending_portal>=0 and near_portal()==pending_portal:
			if clock-float(player.last_hit)<6.0:
				message="Portal wartet · noch %d Sekunden ohne Treffer" % ceili(6.0-clock+float(player.last_hit))
			elif travel(pending_portal):return
		if repairing:
			player.hp = minf(float(player.max_hp), float(player.hp) + 90.0 * (1.5 if has_blessing() else 1.0) * delta)
			if float(player.hp) >= float(player.max_hp): repairing = false
		if firing and target > 0 and float(player.reload) <= 0:
			_fire_player()
		_collect_sparkles()
		EXPANSION.collect(self,delta)
	for npc in npcs:
		_step_npc(npc, delta)
	_step_shots(delta)
	_step_bonus(delta)
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
	var slow_rate = float(body.get("slow_rate", 0.55)) if float(body.slow) > 0 else 1.0
	var travel = float(body.speed) * slow_rate * delta * (1.25 if int(body.id)==0 and float(buffs.get("wind_draught",0))>0 else 1.0)
	var phasing := int(body.id) == 0 and staff.flag("no_collision")
	if int(body.id) == 0 and staff.flag("speed"): travel *= 2.5
	while travel > 0.01 and not body.path.is_empty():
		var goal: Vector2 = body.path[0]
		var gap: Vector2 = goal - body.pos
		if gap.length() < 0.001:
			body.pos=goal
			body.path.pop_front()
			continue
		body.heading = gap.normalized()
		var amount = minf(travel, gap.length())
		var next: Vector2 = body.pos + body.heading * amount
		if not phasing and not segment_free(body.pos, next):
			body.path = []
			return
		body.pos = next
		travel -= amount
		if amount >= gap.length(): body.path.pop_front()

func npc_engages(npc: Dictionary) -> bool:
	if docked or int(player.hp)<=0: return false
	if staff.hidden() or staff.flag("no_aggro"): return false
	if npc.kind == "tower": return not tower_friendly() and npc.pos.distance_to(player.pos) <= float(npc.range)
	# Bonus-wave hunters chase anywhere on their instance.
	if bool(npc.get("hunter",false)): return true
	# Entry regions are neutral: proximity and selecting a target never provoke fire.
	return npc.pos.distance_to(npc.home)<900 and npc.pos.distance_to(player.pos)<1000 and (bool(npc.aggressive) or (bool(CONTENT.MAPS[map_id].npc_hostile) and npc.pos.distance_to(player.pos)<380))

func _patrol_path(npc: Dictionary) -> Array[Vector2]:
	# Wide patrol circuits: real GLB hulls can sail direct courses rather than\n\t# injecting frequent diagonal turns solely for legacy four-view sprites.
	var offsets=[Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]
	for radius in [520.0, 380.0]:
		for attempt in 4:
			var index=posmod(int(npc.patrol)+1+attempt,4)
			var goal: Vector2=npc.home+offsets[index]*radius
			if npc.pos.distance_to(goal)<60:continue
			var route=plan_actor_path(npc,goal)
			if not route.is_empty():
				npc.patrol=index
				return route
	return []

func _step_npc(npc: Dictionary, delta: float) -> void:
	if npc.kind == "tower":
		_step_tower(npc, delta)
		return
	if int(npc.hp) <= 0:
		if bool(npc.get("wave",false)) or bool(npc.get("staff_spawn",false)): return
		npc.respawn -= delta
		if float(npc.respawn) <= 0:
			npc.hp = npc.max_hp
			npc.shield = npc.get("max_shield",0)
			npc.pos = npc.home
			npc.aggressive = false
			npc.path = []
		return
	if bool(npc.get("frozen",false)):
		npc.path = []
		npc.state = "frozen"
		return
	if float(npc.get("ice", 0.0)) > 0.0:
		npc.ice = maxf(0.0, float(npc.ice) - delta)
		npc.path = []
		npc.state = "ice"
		return
	npc.reload = maxf(0, float(npc.reload) - delta)
	npc.slow = maxf(0, float(npc.slow) - delta)
	if float(npc.get("max_shield",0)) > 0 and clock - float(npc.get("last_hit",-100.0)) >= SHIELD_DELAY:
		npc.shield = minf(float(npc.max_shield), float(npc.shield) + float(npc.max_shield) * 0.03 * delta)
	npc.repath -= delta
	var distance: float = npc.pos.distance_to(player.pos)
	var pursue = npc_engages(npc)
	if pursue:
		npc.state = "attack" if distance < 390 else "approach"
		if distance > 305 and float(npc.repath) <= 0:
			npc.path = plan_actor_path(npc,player.pos)
			npc.repath = 4.5 # Avoid chasing a new moving destination every few frames.
		elif distance <= 305:
			npc.path = []
		if distance < 420 and float(npc.reload) <= 0 and segment_free(npc.pos, player.pos):
			var power := float(npc.get("power", 36.0 if npc.elite else 23.0))
			_launch(npc.id, 0, "harpoon" if npc.kind == "monster" else "cannon", roundi(power*float(CONTENT.MAPS[map_id].enemy_scale)), 2)
			npc.reload = 3.2 if npc.kind == "monster" else 2.6
	else:
		if npc.state!="patrol":
			# A pursuit timer must not leave a harmless patroller frozen for
			# several seconds after the captain docks or escapes combat.
			npc.path=[]
			npc.repath=0.0
		npc.state = "patrol"
		npc.aggressive = false
		if npc.path.is_empty() and float(npc.repath)<=0:
			npc.path = _patrol_path(npc)
			npc.repath = 9.0 if npc.path.is_empty() else 0.0
	# Let a completed patrol breathe before starting an unrelated new course.
	# A blocked route also gets a brief retry delay, preventing jitter loops.
	var was_patrolling: bool=npc.state=="patrol" and not npc.path.is_empty()
	_move(npc, delta)
	if was_patrolling and npc.path.is_empty():
		npc.repath=maxf(float(npc.repath),2.0)

func _fire_player() -> void:
	if docked or int(player.hp)<=0: return
	if staff.spectating():
		message = "Zuschauer-Modus · kein Feuer"
		firing = false
		return
	var victim = actor(target)
	if victim.is_empty() or int(victim.hp) <= 0:
		firing = false
		return
	if victim.kind == "tower" and tower_friendly():
		message = "Diese Türme gehören deiner Gilde"
		firing = false
		return
	if (victim.kind == "monster") != (ammo_mode == 2):
		message = "Harpunen gegen Seeungeheuer" if victim.kind == "monster" else "Diese Munition wirkt gegen Schiffe und Türme"
		firing = false
		return
	if player.pos.distance_to(victim.pos) > 530:
		message = "Ziel außer Reichweite · näher heranfahren"
		player.reload = 0.3
		return
	# Towers stand above the coastline, so islands never block the line to them.
	if victim.kind != "tower" and not segment_free(player.pos, victim.pos):
		message = "Insel versperrt die Schusslinie"
		player.reload = 0.3
		return
	var count = 1 if ammo_mode >= 2 else 3
	var unlimited := staff.flag("unlimited_ammo")
	if not unlimited and int(player.ammo[ammo_mode]) < count:
		message = "Munition leer · Nachschub in der Werft"
		firing = false
		return
	if not unlimited: player.ammo[ammo_mode] -= count
	var damage := float(weapon_damage(ammo_mode))
	if bool(victim.elite) or victim.kind == "tower": damage *= 1.0 + 0.1 * float(upgrades.war)
	var powdered := powder_on and ammo_mode < 2 and int(supplies.powder) > 0
	if powdered:
		damage *= 1.4
		supplies.powder -= 1
		if int(supplies.powder) <= 0: powder_on = false
	_launch(0, target, AMMO_NAMES[ammo_mode], roundi(damage), count,powdered)
	player.reload = 0.25 if staff.flag("instant_reload") else reload_time()
	victim.aggressive = true
	repairing = false
	message = AMMO_LABELS[ammo_mode] if ammo_mode >= 2 else ("Breitseite mit Schwarzpulver!" if powdered else "Breitseite!")

# The cannon turrets are tall sprites whose rendered masonry is above their
# land-footprint origin. Targeting their base visually looks like a ricochet.
func _projectile_target(victim: Dictionary) -> Vector2:
	return Vector2(victim.pos)-Vector2(0,56) if str(victim.get("kind",""))=="tower" else Vector2(victim.pos)

func _launch(source_id: int, target_id: int, weapon: String, damage: int, count: int,powdered: bool=false) -> void:
	var source = actor(source_id)
	var destination = actor(target_id)
	if source.is_empty() or destination.is_empty(): return
	# Flight metadata is presentation-only. Damage, speed, shot spread, range
	# and 80 ms salvo staggering stay exactly as before M3100.
	var visual_start: Vector2=_projectile_target(source)
	var visual_heading: Vector2=(_projectile_target(destination)-visual_start).normalized()
	if visual_heading.length_squared()<0.001:visual_heading=Vector2.RIGHT
	# One render group per real salvo. All three original damage-bearing shots
	# remain independent; the visual renderer draws ONE tightly packed pile.
	var group_id: int=next_id+1
	for i in count:
		next_id += 1
		var start: Vector2 = visual_start + Vector2(0, (float(i) - float(count - 1) * 0.5) * 13)
		shots.append({"id": next_id, "source": source_id, "target": target_id, "pos": start,
			"start": start, "damage": damage, "powder":powdered, "weapon": weapon, "age": -float(i) * 0.08,
			"distance": maxf(1, start.distance_to(_projectile_target(destination))), "traveled": 0.0,
			"visual_heading": visual_heading, "salvo_index": i,
			"salvo_count": count, "salvo_group": group_id, "salvo_origin": source.pos})
	_event("muzzle", visual_start, count, source_id)
	if not events.is_empty():
		events.back()["powder"]=powdered
		events.back()["weapon"]=weapon
		events.back()["heading"]=visual_heading

func _step_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var shot = shots[i]
		shot.age += delta
		if float(shot.age) < 0: continue
		var victim = actor(int(shot.target))
		if victim.is_empty() or int(victim.hp) <= 0 or float(shot.age) > 5:
			shots.remove_at(i)
			continue
		var gap: Vector2 = _projectile_target(victim) - shot.pos
		var speed = 530.0 if shot.weapon == "harpoon" else (380.0 if shot.weapon == "mortar" else 470.0)
		var amount = speed * delta
		if gap.length() <= amount + 12:
			_hit(shot, victim)
			shots.remove_at(i)
		else:
			shot.pos += gap.normalized() * amount
			shot.traveled += amount

## Shields absorb first; armor plates reduce the player's incoming damage before that.
func apply_damage(victim: Dictionary, amount: int) -> int:
	if int(victim.id) == 0 and (staff.flag("god") or staff.hidden()): return 0
	var dealt := amount
	if int(victim.id) == 0 and plates_on and int(supplies.plates) > 0:
		dealt = roundi(float(dealt) * 0.65)
		supplies.plates -= 1
		if int(supplies.plates) <= 0: plates_on = false
	var absorbed := mini(int(victim.get("shield", 0)), dealt)
	victim.shield = int(victim.get("shield", 0)) - absorbed
	victim.hp = maxi(0, int(victim.hp) - (dealt - absorbed))
	return dealt

func _hit(shot: Dictionary, victim: Dictionary) -> void:
	if int(victim.hp) <= 0: return
	var damage_amount := int(shot.damage)
	if float(victim.get("spotted", 0.0)) > clock and str(shot.weapon) != "flare":
		damage_amount = roundi(float(damage_amount) * 1.15)
	if int(victim.id)==0 and float(buffs.get("smoke_bomb",0))>0:damage_amount=roundi(float(damage_amount)*.7)
	var plated: bool=int(victim.id)==0 and plates_on and int(supplies.plates)>0
	var dealt := apply_damage(victim, damage_amount)
	if shot.weapon == "chain":
		victim.slow = 4.0
		victim.slow_rate = 0.55
	elif shot.weapon == "snow":
		victim.slow = 7.5
		victim.slow_rate = 0.38
	elif shot.weapon == "ice":
		if int(victim.id) == 0:
			victim.slow = 3.5
			victim.slow_rate = 0.42
		else:
			victim.ice = 3.2
			victim.path = []
	elif shot.weapon == "flare":
		victim.spotted = clock + 8.0
	elif shot.weapon == "pumpkin" and int(shot.source) == 0:
		for other in npcs:
			if int(other.id) == int(victim.id) or int(other.hp) <= 0: continue
			if other.pos.distance_to(victim.pos) > 110.0: continue
			apply_damage(other, maxi(1, roundi(float(shot.damage) * 0.35)))
			other.last_hit = clock
	if int(victim.id) == 0:
		player.last_hit = clock
		repairing = false
	else:
		victim.last_hit = clock
	_event("impact", _projectile_target(victim), dealt, victim.id)
	if not events.is_empty():
		events.back()["structure"]=str(victim.get("kind",""))=="tower"
		events.back()["powder"]=bool(shot.get("powder",false))
		events.back()["plates"]=plated
		events.back()["weapon"]=str(shot.weapon)
		events.back()["vfx_seed"]=int(shot.get("id",int(victim.id))) # synthetic admin/test hits have no projectile ID
	if int(victim.hp) == 0:
		victim.path = []
		victim.respawn = 8.0 if int(victim.id) == 0 else (90.0 if victim.kind == "tower" else 48.0)
		_event("sunk", victim.pos, 0, victim.id)
		if int(victim.id) == 0:
			pending_portal=-1
			firing = false
			repairing = false
			message = "Versenkt · neuer Versuch in 8 Sekunden" if in_bonus_map() else "Versenkt · Rückkehr in 8 Sekunden"
		elif int(shot.source) == 0:
			if target == int(victim.id): firing = false
			# Staff results never reach rankings, quests or the economy.
			if staff.active() or bool(victim.get("staff_spawn", false)):
				staff_kills += 1
				message = "%s versenkt · Staff-Abschuss zählt nicht" % victim.name
				return
			if victim.kind == "tower":
				tower_kills += 1
				award_xp(80)
				message = "%s zerstört" % victim.name
				_check_fortress()
				return
			kills += 1
			if victim.kind == "monster": monster_kills += 1
			elif victim.elite: elite_kills += 1
			award_xp(150 if victim.kind == "monster" else (60 if victim.elite else 25))
			_add_drop(victim.pos, loot_gold(int(victim.reward)))
			_roll_essence(victim)
			message = "Ziel versenkt · zur Beute fahren"

func _roll_essence(victim: Dictionary) -> void:
	var amount := 0
	if victim.kind == "monster": amount = 2
	elif rng.randf() < (0.5 if bool(victim.elite) else 0.25): amount = 1
	if amount <= 0: return
	essence += amount
	_event("essence", victim.pos, amount, 0)

func _add_drop(point: Vector2, gold: int) -> void:
	next_id += 1
	drops.append({"id": next_id, "pos": point, "gold": gold, "art":2 if gold>=200 else (1 if gold>=100 else 0)})

func _event(kind: String, point: Vector2, value: int, id: int) -> void:
	events.append({"type": kind, "pos": point, "value": value, "actor": id, "time": clock})

# --- Gezeitenessenz: sparkles and the cauldron -------------------------------------

func _sparkle_point() -> Vector2:
	var avoid: Array[Vector2] = [START, harbor]
	for portal in portals: avoid.append(portal.pos)
	for attempt in 40:
		var point := Vector2(rng.randf_range(260, WORLD.x - 260), rng.randf_range(260, WORLD.y - 260))
		if blocked(point, 70.0): continue
		var clear := true
		for spot in avoid: clear = clear and point.distance_to(spot) > 300
		if clear: return point
	return Vector2(WORLD.x * 0.5, WORLD.y * 0.25)

func _spawn_sparkles() -> void:
	sparkles.clear()
	for i in 5:
		next_id += 1
		sparkles.append({"id": next_id, "pos": _sparkle_point(), "respawn": 0.0})

func _collect_sparkles() -> void:
	for sparkle in sparkles:
		if float(sparkle.respawn) > 0 or player.pos.distance_to(sparkle.pos) > 70: continue
		essence += 1
		_event("essence", sparkle.pos, 1, 0)
		message = "Glitzernde Strömung · +1 Gezeitenessenz"
		sparkle.respawn = 90.0

func free_flask_ready(today: String) -> bool:
	return not today.is_empty() and free_flask_day != today

func claim_free_flask(today: String) -> Array:
	if not docked or not free_flask_ready(today):
		message = "Die Tagesflasche gibt es einmal täglich im Hafen"
		return []
	free_flask_day = today
	var results := [_kessel_draw()]
	_kessel_meter_step(results)
	message = "Tagesflasche geworfen · %s" % results[0].text
	return results

func throw_kessel(count: int, today: String = "") -> Array:
	if not count in CONTENT.KESSEL_THROWS: return []
	if not docked:
		message = "Der Gezeitenkessel steht im Hafen · zuerst andocken"
		return []
	if essence < count:
		message = "Zu wenig Gezeitenessenz · %d benötigt" % count
		return []
	essence -= count
	var results := []
	for i in count:
		results.append(_kessel_draw())
		_kessel_meter_step(results)
	message = "%d× in den Kessel geworfen" % count
	return results

func _kessel_draw() -> Dictionary:
	var roll := rng.randi_range(1, 100)
	var entry: Dictionary = CONTENT.KESSEL_POOL[0]
	for candidate: Dictionary in CONTENT.KESSEL_POOL:
		roll -= int(candidate.weight)
		if roll <= 0:
			entry = candidate
			break
	kessel_throws += 1
	return _grant(str(entry.id), int(entry.amount), str(entry.name), int(entry.rarity))

func _kessel_meter_step(results: Array) -> void:
	kessel_meter += 1
	for milestone: Dictionary in CONTENT.KESSEL_MILESTONES:
		if int(milestone.at) == kessel_meter:
			var reward := _grant(str(milestone.id), int(milestone.amount), str(milestone.name), 3)
			reward.milestone = true
			results.append(reward)
	if kessel_meter >= CONTENT.KESSEL_CYCLE: kessel_meter = 0

func _grant(id: String, amount: int, title: String, rarity: int) -> Dictionary:
	var text := title
	match id:
		"fragment":
			fragments += amount
			text = "%d× Schriftrollenfragment" % amount
		"ammo0", "ammo1", "ammo2":
			player.ammo[int(id.right(1))] += amount
			text = "%d %s" % [amount, title]
		"powder", "plates", "repair_kit", "shield_charge":
			supplies[id] += amount
			text = "%d× %s" % [amount, CONTENT.SUPPLIES[id].name]
		"gold":
			player.gold += amount
			text = "%d Gold" % amount
		"essence":
			essence += amount
			text = "%d Gezeitenessenz" % amount
		"tide_deck":
			add_tide_deck(float(amount))
			text = "Gezeitendeck +%d min" % roundi(amount / 60.0)
		"scroll0", "scroll1", "scroll2":
			scrolls[int(id.right(1))] += amount
			text = "%s-Schriftrolle" % CONTENT.BONUS_TIERS[int(id.right(1))].name
		"blessing":
			activate_blessing(float(amount))
			text = "Kristallsegen %d min" % roundi(amount / 60.0)
		_:
			if id == "deck" or id.begins_with("deck_"):
				var parts := id.split("_")
				var type: String = parts[1] if parts.size() > 1 else CONTENT.DECK_KEYS[rng.randi_range(0, CONTENT.DECK_KEYS.size() - 1)]
				var tier := int(parts[2]) if parts.size() > 2 else 0
				var fresh := grant_deck(type, tier)
				text = "%s %s%s" % [CONTENT.DECKS[type].name, CONTENT.DECK_TIERS[tier], "" if fresh else " · Duplikat → %d Essenz" % CONTENT.DUPLICATE_DECK_ESSENCE]
	return {"id": id, "text": text, "rarity": rarity}

# --- Bonus maps --------------------------------------------------------------------

func in_bonus_map() -> bool:
	return bool(CONTENT.MAPS[map_id].get("bonus", false))

func has_harbor() -> bool:
	return not in_bonus_map()

func assign_bonus_piece(tier: int) -> bool:
	return BONUS_OPS.assign_bonus_piece(self, tier)

func craft_scroll(tier: int) -> bool:
	return BONUS_OPS.craft_scroll(self, tier)

func start_bonus(tier: int) -> bool:
	return BONUS_OPS.start_bonus(self, tier)

func leave_bonus() -> bool:
	return BONUS_OPS.leave_bonus(self)

func _arrive(point: Vector2) -> void:
	BONUS_OPS._arrive(self, point)

func bonus_wave_alive() -> int:
	return BONUS_OPS.bonus_wave_alive(self)

func _step_bonus(delta: float) -> void:
	BONUS_OPS._step_bonus(self, delta)

func _spawn_wave() -> void:
	BONUS_OPS._spawn_wave(self)

func _spawn_point(angle: float) -> Vector2:
	return BONUS_OPS._spawn_point(self, angle)

func _finish_wave() -> void:
	BONUS_OPS._finish_wave(self)

# --- Guild and fortress ------------------------------------------------------------

func found_guild(title: String, tag: String) -> bool:
	title = title.strip_edges()
	tag = tag.strip_edges().to_upper()
	if not guild.is_empty():
		message = "Du führst bereits die Gilde %s" % guild.name
		return false
	if title.length() < 3 or title.length() > 24:
		message = "Gildenname: 3 bis 24 Zeichen"
		return false
	var valid := tag.length() >= 2 and tag.length() <= 4
	for character in tag: valid = valid and (character >= "A" and character <= "Z" or character >= "0" and character <= "9")
	if not valid or tag == CONTENT.FORTRESS_TAG:
		message = "Kürzel: 2 bis 4 Buchstaben oder Ziffern"
		return false
	if reserved_tag(tag):
		message = "Kürzel [%s] ist dem Spielteam vorbehalten" % tag
		return false
	if int(player.gold) < CONTENT.GUILD_COST:
		message = "Gildengründung kostet %d Gold" % CONTENT.GUILD_COST
		return false
	player.gold -= CONTENT.GUILD_COST
	guild = {"name": title, "tag": tag}
	message = "Gilde [%s] %s gegründet" % [tag, title]
	return true

## Staff badges are reserved, including digit look-alikes such as 4DM or M0D.
static func reserved_tag(tag: String) -> bool:
	var plain := ""
	for character in tag.to_upper(): plain += str(LOOKALIKE.get(character, character))
	if plain in CONTENT.RESERVED_TAGS: return true
	for prefix: String in CONTENT.RESERVED_PREFIXES:
		if plain.begins_with(prefix): return true
	return false

func leave_guild() -> bool:
	return GUILD_OPS.leave_guild(self)

func guild_island_held() -> bool:
	return GUILD_OPS.guild_island_held(self)

func tower_friendly() -> bool:
	return GUILD_OPS.tower_friendly(self)

func tower_tag() -> String:
	return GUILD_OPS.tower_tag(self)

func fortress_island() -> Dictionary:
	return GUILD_OPS.fortress_island(self)

func _add_fortress() -> void:
	GUILD_OPS._add_fortress(self)

func towers_alive() -> int:
	return GUILD_OPS.towers_alive(self)

func _step_tower(npc: Dictionary, delta: float) -> void:
	GUILD_OPS._step_tower(self, npc, delta)

func _guardian_alive() -> bool:
	return GUILD_OPS._guardian_alive(self)

func _check_fortress() -> void:
	GUILD_OPS._check_fortress(self)

# --- Staff tools -------------------------------------------------------------------
# Every tool validates its input, then asks staff.authorize(), which writes the audit entry.

const STAFF_SPAWN_CAP := 12
const STAFF_PLACES := ["harbor","start","portal_east","portal_west","fortress"]
var staff_inspected := -1

func staff_sign_in(code: String) -> bool:
	return STAFF_OPS.staff_sign_in(self, code)

func staff_sign_out(restore: bool) -> bool:
	return STAFF_OPS.staff_sign_out(self, restore)

func _staff_allow(permission: String, action: String, detail: String = "") -> bool:
	return STAFF_OPS._staff_allow(self, permission, action, detail)

func staff_set_presence(mode: String) -> bool:
	return STAFF_OPS.staff_set_presence(self, mode)

func staff_toggle(key: String) -> bool:
	return STAFF_OPS.staff_toggle(self, key)

func staff_set_tap_teleport(on: bool) -> bool:
	return STAFF_OPS.staff_set_tap_teleport(self, on)

func _calm_all() -> void:
	STAFF_OPS._calm_all(self)

func staff_ship(action: String) -> bool:
	return STAFF_OPS.staff_ship(self, action)

func staff_place_point(place: String) -> Vector2:
	return STAFF_OPS.staff_place_point(self, place)

func staff_teleport(destination: int, place: String = "start", point: Vector2 = Vector2(-1, -1)) -> bool:
	return STAFF_OPS.staff_teleport(self, destination, place, point)

func staff_teleport_target() -> bool:
	return STAFF_OPS.staff_teleport_target(self)

func staff_summon_target() -> bool:
	return STAFF_OPS.staff_summon_target(self)

func staff_spawn_count() -> int:
	return STAFF_OPS.staff_spawn_count(self)

func staff_spawn(kind: String) -> bool:
	return STAFF_OPS.staff_spawn(self, kind)

func _clear_staff_spawns() -> void:
	STAFF_OPS._clear_staff_spawns(self)

func staff_clear_spawns() -> bool:
	return STAFF_OPS.staff_clear_spawns(self)

func staff_target(action: String) -> bool:
	return STAFF_OPS.staff_target(self, action)

func staff_world(action: String) -> bool:
	return STAFF_OPS.staff_world(self, action)

func staff_grant(kind: String) -> bool:
	return STAFF_OPS.staff_grant(self, kind)

func staff_inspect() -> Dictionary:
	return STAFF_OPS.staff_inspect(self)

func _free_water(goal: Vector2) -> Vector2:
	var low := Vector2(80, 80)
	var high := WORLD - Vector2(80, 80)
	goal = goal.clamp(low, high) if goal.is_finite() else START
	if not blocked(goal): return goal
	for radius in [70.0, 140.0, 210.0, 300.0, 420.0, 560.0, 760.0]:
		for turn in 12:
			var point: Vector2 = (goal + Vector2.from_angle(TAU * float(turn) / 12.0) * radius).clamp(low, high)
			if not blocked(point): return point
	return START

# --- Quests, economy and progression -----------------------------------------------

func claim_quest() -> bool:
	var quest = current_quest()
	if quest.is_empty() or quest_progress() < int(quest.goal): return false
	player.gold += int(quest.gold)
	essence += int(quest.get("essence", 0))
	award_xp(int(quest.xp))
	quest_index += 1
	claimed = true
	message = "Auftrag abgeschlossen · +%d Gold · +%d EP · +%d Essenz" % [quest.gold,quest.xp,quest.get("essence",0)]
	return true

func buy_ammo(index: int) -> bool:
	if index < 0 or index >= AMMO_NAMES.size() or int(player.hp) <= 0: return false
	var price = 30 if index < 3 else 80
	var pack = ammo_pack(index)
	if int(player.gold) < price: return false
	player.gold -= price
	player.ammo[index] += pack
	message = "Munitionsvorrat aufgefüllt"
	return true

func ammo_pack(index: int) -> int:
	if index<0 or index>=AMMO_NAMES.size():return 0
	return [150,60,40,12,8,12,8][index] if index<7 else 12

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
	if mode >= 3:
		var special: float = 31.0 * ([0.75, 1.2, 0.8, 0.95][mode-3] if mode<7 else 1.0) # M3105 visual-first test ammo: neutral placeholder value
		special *= float(equipped_cannons()) / float(BASE_CANNON_SLOTS)
		if has_blessing(): special *= 1.15
		return roundi(special)
	var key = "harpoon" if mode == 2 else "cannon"
	var bonus_rate = 0.35 if mode == 2 else 0.25
	var value: float = float([31,19,96][mode]) * (1.0 + float(upgrades[key]) * bonus_rate)
	if mode < 2: value *= float(equipped_cannons()) / float(BASE_CANNON_SLOTS)
	else: value *= 1.0 + deck_value("hunter") / 100.0
	if has_blessing(): value *= 1.15
	return roundi(value)

func apply_upgrades() -> void:
	var armor := 1.0 + deck_value("armor") / 100.0
	var blessed := has_blessing()
	player.max_hp = roundi(float(PLAYER_HP + int(upgrades.hull) * 400) * armor * (1.2 if blessed else 1.0))
	player.max_shield = roundi(float(PLAYER_SHIELD + int(upgrades.hull) * 120) * armor)
	player.hp = minf(float(player.hp),float(player.max_hp))
	player.shield = minf(float(player.shield),float(player.max_shield))
	player.speed = PLAYER_SPEED * (1.0 + 0.12 * float(upgrades.sails) + deck_value("navigation") / 100.0) * (1.1 if blessed else 1.0) * (1.12 if float(buffs.storm_deck)>0 else 1.0)

## Captain level paces the castles: levels 1-3 are always open, then one more every three levels.
func castle_cap() -> int:
	return mini(CONTENT.CASTLE_MAX, 3 + floori(level / 3.0))

func upgrade_cost(key: String) -> int:
	if not upgrades.has(key) or int(upgrades[key]) >= CONTENT.CASTLE_MAX: return -1
	return CONTENT.CASTLE_COSTS[int(upgrades[key])]

func buy_upgrade(key: String) -> bool:
	var cost = upgrade_cost(key)
	if not docked or cost < 0 or int(player.gold) < cost: return false
	if int(upgrades[key]) >= castle_cap():
		message = "%s Stufe %d: Kapitänsstufe %d benötigt" % [CONTENT.UPGRADES[key].name, int(upgrades[key]) + 1, (int(upgrades[key]) - 2) * 3]
		return false
	player.gold -= cost
	upgrades[key] += 1
	apply_upgrades()
	message = "%s auf Stufe %d ausgebaut" % [CONTENT.UPGRADES[key].name,upgrades[key]]
	return true

func can_dock() -> bool:
	return has_harbor() and int(player.hp) > 0 and player.pos.distance_to(harbor) <= 160 and clock - float(player.last_hit) >= 6.0

func dock() -> bool:
	if not can_dock():
		message = "Zum Hafen fahren · Andocken erst 6 Sekunden ohne Treffer"
		return false
	docked = true
	pending_portal=-1
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

func request_portal(destination: int) -> bool:
	pending_portal=-1
	if docked:message="Vor der Überfahrt zuerst im Hafen ablegen";return false
	if int(player.hp)<=0:return false
	if destination<0 or not destination in CONTENT.SEA_MAP_IDS or destination==map_id:return false
	if level<int(CONTENT.MAPS[destination].level):
		message="%s: Kapitänsstufe %d benötigt" % [CONTENT.MAPS[destination].name,CONTENT.MAPS[destination].level]
		return false
	for portal in portals:
		if int(portal.destination)!=destination:continue
		if player.pos.distance_to(portal.pos)<=135:
			if clock-float(player.last_hit)>=6.0:return travel(destination)
			player.path=[];pending_portal=destination
			message="Portal wartet · erst 6 Sekunden ohne Treffer"
			return true
		if not course(portal.pos):return false
		pending_portal=destination
		firing=false
		message="Kurs zum Portal · %s" % CONTENT.MAPS[destination].name
		return true
	return false

func travel(destination: int) -> bool:
	if destination < 0 or not destination in CONTENT.SEA_MAP_IDS or destination == map_id or docked or int(player.hp) <= 0: return false
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
	_arrive(START)
	message = "%s erreicht · Karte %s" % [CONTENT.MAPS[map_id].name,CONTENT.MAPS[map_id].code]
	return true

# The collision JSON is authored from the true opaque island silhouettes;
# snow and snow2 have more transparent margins than the tropical atlas.
# Scale BOTH painted art and measured collision polygon by the same ratio.
# This keeps similar-sized visible landmass across map art variations.
func island_art_scale(art: String) -> float:
	if not island_shapes.has(art):return 1.0
	var points: Array=island_shapes[art].points
	if points.is_empty():return 1.0
	var lo: float=1.0
	var hi: float=0.0
	for pair: Array in points:
		lo=minf(lo,float(pair[0]))
		hi=maxf(hi,float(pair[0]))
	return clampf(.70/maxf(.1,hi-lo),.95,1.15)

func _harbor_site_for_map() -> Vector2:
	if not harbor_outline.is_empty():return harbor
	var cached: PackedVector2Array=harbor_outline
	harbor_outline=PackedVector2Array()
	var site: Vector2=_find_harbor_site()
	harbor_outline=cached
	return site

func _find_harbor_site() -> Vector2:
	# The same berth mirrors with its neighbouring coast on maps 1 and 2.
	# A fallback location is chosen deterministically, not re-rolled on a
	# revisit (which would break staff teleport, saves and the minimap).
	var primary: Vector2=_map_point(Vector2(1920,1450))
	for offset in [Vector2.ZERO,Vector2(0,-230),Vector2(240,0),Vector2(0,260),Vector2(-250,0),Vector2(300,210)]:
		var candidate: Vector2=primary+offset
		if not blocked(candidate,94.0) and candidate.distance_to(START)>165.0:
			var safe:=true
			for portal: Dictionary in portals:
				if candidate.distance_to(portal.pos)<220.0:safe=false
			if safe:return candidate
	return primary

func _map_point(point: Vector2) -> Vector2:
	match map_id%6:
		1, 4: return Vector2(WORLD.x - point.x,point.y)
		2, 5: return Vector2(point.x,WORLD.y - point.y)
		3: return WORLD - point
	return point

func configure_map(destination: int) -> void:
	_store_fortress_state()
	harbor_outline.clear()
	event_pickups.clear()
	map_id = clampi(destination,0,CONTENT.MAPS.size()-1)
	if map_id < visited.size(): visited[map_id] = true
	var config = CONTENT.MAPS[map_id]
	var holding: Dictionary=guild_holdings.get(str(map_id),{})
	fortress_hold=float(holding.get("remaining",0.0))
	tower_levels=CONTENT.normalized_tower_levels(holding.get("levels"))
	portals.clear()
	if bool(config.get("bonus", false)):
		var tier := map_id - CONTENT.REGION_COUNT
		islands.clear()
		for i in CONTENT.BONUS_ISLANDS.size():
			var island: Dictionary = base_islands[CONTENT.BONUS_ISLANDS[i]].duplicate(true)
			island.pos = _map_point(island.pos)
			island.art = config.art[i]
			island.width=float(base_islands[CONTENT.BONUS_ISLANDS[i]].width)*island_art_scale(str(config.art[i]))
			island.name = CONTENT.BONUS_ISLAND_NAMES[tier][i]
			islands.append(island)
		npcs.clear()
		drops.clear()
		sparkles.clear()
		_build_grid()
		return
	islands = base_islands.duplicate(true)
	for i in islands.size():
		islands[i].pos = _map_point(base_islands[i].pos)
		islands[i].art = config.art[i]
		# Preserve the authored width, but normalize the *visible* footprint
		# of each atlas and its land collision together.
		islands[i].width=float(base_islands[i].width)*island_art_scale(str(config.art[i]))
		if map_id > 0: islands[i].name = (["Eishafen","Frostbucht","Weißes Riff","Gletscherwacht","Eisbrecherbucht","Nordstern","Winterhafen","Frostzahn","Polarwacht"] if map_id == 1 else ["Nebelwacht","Schwarze Bucht","Totenriff","Schattenklippen","Korsarenfestung","Nachtwacht","Dämmerhafen","Drachenzahn","Knochenriff"])[i]
	npcs = base_npcs.duplicate(true)
	for npc in npcs:
		npc.pos = _map_point(npc.pos)
		npc.home = npc.pos
		npc.path = []
		npc.hp = roundi(float(npc.max_hp) * float(config.enemy_scale))
		npc.max_hp = npc.hp
		npc.max_shield = roundi(float(npc.max_shield) * float(config.enemy_scale))
		npc.shield = npc.max_shield
		npc.reward = roundi(float(npc.reward) * float(config.enemy_scale))
		if map_id >=6: npc.name="%s · " % config.code+str(npc.name)
		elif map_id > 0: npc.name = ("Frost · " if map_id == 1 else "Schatten · ") + str(npc.name)
	var restored := map_states.has(map_id)
	if restored:
		npcs = map_states[map_id].npcs.duplicate(true)
		drops = map_states[map_id].drops.duplicate(true)
	else:
		drops.clear()
		_add_drop(START + Vector2(-170,130),25 + map_id * 15)
		_add_drop(START + Vector2(220,-120),25 + map_id * 15)
		_add_drop(_map_point(Vector2(2170,1780)),30 + map_id * 20)
	var exits: Array[Vector2]=[Vector2(4070,1600),Vector2(330,1600),Vector2(2200,300)]
	var neighbors: Array[int]=CONTENT.sea_neighbors(map_id)
	for i in neighbors.size():portals.append({"pos":exits[i],"destination":neighbors[i]})
	if CONTENT.has_guild_island(map_id):
		# A purpose-built island with integrated coastal walls, an open sea gate,
		# navigable central harbor and twelve independent physical defenses.
		var fortress: Dictionary=islands[CONTENT.FORTRESS_ISLAND]
		fortress.art="rock"
		fortress["guild_fortress"]=true
		fortress.width=float(base_islands[CONTENT.FORTRESS_ISLAND].width)*island_art_scale(str(fortress.art))*CONTENT.GUILD_ISLAND_SCALE
	_build_grid()
	harbor=_harbor_site_for_map()
	var primary_port: Vector2=harbor
	for offset in [Vector2.ZERO,Vector2(320,0),Vector2(0,320),Vector2(0,-320),Vector2(-320,0),Vector2(420,260),Vector2(-420,-260),START-primary_port]:
		harbor=primary_port+offset
		_set_harbor_collision()
		_build_grid()
		if not blocked(harbor) and not plan_path(START,harbor).is_empty():break

	# Never initialize a patrol or chest inside newly introduced harbor land.
	for npc: Dictionary in npcs:
		if str(npc.kind)!="tower" and blocked(npc.pos):npc.pos=_free_water(npc.pos);npc.home=npc.pos;npc.path=[]
	for drop: Dictionary in drops:
		if blocked(drop.pos):drop.pos=_free_water(drop.pos)

	if CONTENT.has_guild_island(map_id):
		islands[CONTENT.FORTRESS_ISLAND].name = "Korsarenfestung"
		if not restored: _add_fortress()
	if not restored:EXPANSION.spawn_monsters(self)
	_spawn_sparkles()
	EXPANSION.spawn_collectibles(self)

func export_save() -> Dictionary:
	_store_fortress_state()
	var region := map_id
	var position: Vector2 = player.pos
	if in_bonus_map() and not bonus.is_empty():
		region = int(bonus.origin)
		position = Vector2(float(bonus.origin_pos[0]), float(bonus.origin_pos[1]))
	var run := {}
	if not bonus.is_empty() and not bool(bonus.get("staff", false)):
		run = {"tier": int(bonus.tier), "wave": int(bonus.wave), "done": str(bonus.state) == "done", "origin": int(bonus.origin), "origin_pos": bonus.origin_pos.duplicate()}
	return {"schema":8,"event_mode":event_mode,"event_tokens":event_tokens.duplicate(),"cooldowns":cooldowns.duplicate(),"captain_name":captain_name,"battle_points":battle_points,"rewards":rewards.snapshot(),"tower_levels":tower_levels.duplicate(),"guild_holdings":guild_holdings.duplicate(true),"captain_id":captain_id,"ammo_mode":ammo_mode,"gold":player.gold,"ammo":player.ammo.duplicate(),"skin":player.skin,
		"kills":kills,"claimed":claimed,"quest_index":quest_index,"loot_collected":loot_collected,
		"monster_kills":monster_kills,"elite_kills":elite_kills,"tower_kills":tower_kills,"level":level,"xp":xp,
		"upgrades":upgrades.duplicate(),"visited":visited.duplicate(),"map_id":region,
		"position":[position.x,position.y],"hp":player.hp,"shield":player.shield,"docked":docked,
		"cannons":player.cannons,"supplies":supplies.duplicate(),"buffs":buffs.duplicate(),
		"essence":essence,"fragments":fragments,"bonus_pieces":bonus_pieces.duplicate(),"scrolls":scrolls.duplicate(),"kessel_meter":kessel_meter,
		"kessel_throws":kessel_throws,"free_flask_day":free_flask_day,"decks":decks.duplicate(true),
		"deck_slots":deck_slots.duplicate(),"bonus":run,"bonus_runs":bonus_runs,"guild":guild.duplicate(),
		"fortress_conquests":fortress_conquests,"fortress_hold":fortress_hold,"staff_marked":staff_marked or staff.touched}

func restore_save(data: Dictionary) -> bool:
	if not int(data.get("schema",0)) in [1,2,3,4,5,6,7,8]: return false
	event_mode=str(data.get("event_mode","halloween"))
	if not EXPANSION.EVENT_NAMES.has(event_mode):event_mode="halloween"
	var saved_tokens: Variant=data.get("event_tokens",{})
	if saved_tokens is Dictionary:
		for key in event_tokens:event_tokens[key]=clampi(int(saved_tokens.get(key,0)),0,999999)
	var saved_cooldowns: Variant=data.get("cooldowns",{})
	if saved_cooldowns is Dictionary:
		for key in CONTENT.SUPPLY_KEYS:cooldowns[key]=clampf(float(saved_cooldowns.get(key,0)),0,float(CONTENT.SUPPLIES[key].get("cooldown",0)))
	captain_name=str(data.get("captain_name","Kapitän")).strip_edges().left(24)
	if captain_name.is_empty():captain_name="Kapitän"
	battle_points=maxi(0,int(data.get("battle_points",0)))
	rewards.restore(data.get("rewards",{}))
	tower_levels=CONTENT.normalized_tower_levels(data.get("tower_levels"))
	var stored_id := str(data.get("captain_id","")).strip_edges().to_upper()
	if stored_id.length()==12 and stored_id.is_valid_hex_number():captain_id=stored_id
	player.gold=clampi(int(data.get("gold",240)),0,99999999)
	# Never interpret old skin 1 from schema 1-4 as the new Elite-Design 1.
	# Save schema 5 introduced separate Black Crown test skin 1.
	# Skins 2-11 extend it with ten actual Elite V2 albedo variants.
	# All retired skin IDs from older schemas remain migrated to skin 0.
	var candidate_skin: int=int(data.get("skin",0))
	player.skin=candidate_skin if int(data.get("schema",0))>=5 and candidate_skin>=1 and candidate_skin<=13 and (candidate_skin<=11 or int(data.get("schema",0))>=7) else FINAL_PLAYER_SKIN
	ammo_mode=clampi(int(data.get("ammo_mode",0)),0,AMMO_NAMES.size()-1)
	kills=maxi(0,int(data.get("kills",0)))
	claimed=bool(data.get("claimed",false))
	quest_index=clampi(int(data.get("quest_index",1 if claimed else 0)),0,CONTENT.QUESTS.size())
	loot_collected=maxi(0,int(data.get("loot_collected",0)))
	monster_kills=maxi(0,int(data.get("monster_kills",0)))
	elite_kills=maxi(0,int(data.get("elite_kills",0)))
	tower_kills=maxi(0,int(data.get("tower_kills",0)))
	level=clampi(int(data.get("level",1)),1,20)
	xp=clampi(int(data.get("xp",0)),0,xp_required()-1)
	var saved_upgrades: Variant=data.get("upgrades",{})
	if saved_upgrades is Dictionary:
		for key in CONTENT.UPGRADE_KEYS:upgrades[key]=clampi(int(saved_upgrades.get(key,0)),0,CONTENT.CASTLE_MAX)
	player.cannons=clampi(int(data.get("cannons",BASE_CANNON_SLOTS)),BASE_CANNON_SLOTS,MAX_CANNONS)
	var saved_supplies: Variant=data.get("supplies",{})
	if saved_supplies is Dictionary:
		for key in CONTENT.SUPPLY_KEYS:supplies[key]=clampi(int(saved_supplies.get(key,supplies[key])),0,99999)
	var saved_buffs: Variant=data.get("buffs",{})
	if saved_buffs is Dictionary:
		for key in ["wind_draught","smoke_bomb","salvage_charm"]:buffs[key]=clampf(float(saved_buffs.get(key,0)),0,60)
		buffs.blessing=clampf(float(saved_buffs.get("blessing",0.0)),0.0,CONTENT.BLESSING_SECONDS)
		buffs.tide_deck=clampf(float(saved_buffs.get("tide_deck",0.0)),0.0,CONTENT.TIDE_DECK_CAP)
		for key: String in CONTENT.SPECIAL_DECKS:buffs[key]=clampf(float(saved_buffs.get(key,0.0)),0.0,CONTENT.TIDE_DECK_CAP)
	essence=clampi(int(data.get("essence",essence)),0,99999)
	fragments=clampi(int(data.get("fragments",0)),0,99999)
	var saved_pieces: Variant=data.get("bonus_pieces",[])
	bonus_pieces=[0,0,0]
	if saved_pieces is Array:
		for i in mini(saved_pieces.size(),bonus_pieces.size()):
			bonus_pieces[i]=clampi(int(saved_pieces[i]),0,int(CONTENT.BONUS_TIERS[i].fragments))
	var saved_scrolls: Variant=data.get("scrolls",[])
	if saved_scrolls is Array and saved_scrolls.size()==scrolls.size():
		for i in scrolls.size():scrolls[i]=clampi(int(saved_scrolls[i]),0,999)
	kessel_meter=clampi(int(data.get("kessel_meter",0)),0,CONTENT.KESSEL_CYCLE-1)
	kessel_throws=maxi(0,int(data.get("kessel_throws",0)))
	free_flask_day=str(data.get("free_flask_day",""))
	decks.clear()
	var saved_decks: Variant=data.get("decks",[])
	if saved_decks is Array:
		for entry: Variant in saved_decks:
			if entry is Dictionary and CONTENT.DECKS.has(str(entry.get("type",""))):
				decks.append({"type":str(entry.type),"tier":clampi(int(entry.get("tier",0)),0,CONTENT.DECK_TIERS.size()-1)})
	deck_slots=[-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]
	var saved_slots: Variant=data.get("deck_slots",[])
	if saved_slots is Array:
		for i in mini(saved_slots.size(),CONTENT.DECK_SLOT_COUNT):
			var index:=int(saved_slots[i])
			if index>=0 and index<decks.size() and not index in deck_slots:deck_slots[i]=index
	bonus={}
	bonus_runs=maxi(0,int(data.get("bonus_runs",0)))
	var run: Variant=data.get("bonus",{})
	if run is Dictionary and not run.is_empty():
		if bool(run.get("done",false)):
			bonus_runs+=1
		else:
			var origin_pos: Variant=run.get("origin_pos",[START.x,START.y])
			bonus={"tier":clampi(int(run.get("tier",0)),0,CONTENT.BONUS_TIERS.size()-1),"wave":clampi(int(run.get("wave",0)),0,CONTENT.BONUS_WAVES.size()-1),
				"state":"break","timer":3.0,"origin":int(run.get("origin",0)) if int(run.get("origin",0)) in CONTENT.SEA_MAP_IDS else 0,
				"origin_pos":origin_pos if origin_pos is Array and origin_pos.size()==2 else [START.x,START.y]}
	guild={}
	var saved_guild: Variant=data.get("guild",{})
	if saved_guild is Dictionary and saved_guild.has("name") and saved_guild.has("tag"):
		guild={"name":str(saved_guild.name).left(24),"tag":str(saved_guild.tag).left(4).to_upper()}
	fortress_conquests=maxi(0,int(data.get("fortress_conquests",0)))
	staff_marked=bool(data.get("staff_marked",false))
	guild_holdings={}
	var saved_holdings: Variant=data.get("guild_holdings",{})
	if saved_holdings is Dictionary and not guild.is_empty():
		for key in saved_holdings:
			if not str(key).is_valid_int() or not CONTENT.has_guild_island(int(key)):continue
			var entry: Variant=saved_holdings[key]
			if not entry is Dictionary:continue
			var levels: Array=CONTENT.normalized_tower_levels(entry.get("levels"))
			guild_holdings[str(key)]={"remaining":clampf(float(entry.get("remaining",0)),0,CONTENT.FORTRESS_HOLD),"levels":levels}
	if not guild.is_empty() and not guild_holdings.has(str(CONTENT.FORTRESS_MAP)) and float(data.get("fortress_hold",0))>0:
		guild_holdings[str(CONTENT.FORTRESS_MAP)]={"remaining":clampf(float(data.get("fortress_hold",0)),0,CONTENT.FORTRESS_HOLD),"levels":tower_levels.duplicate()}
	fortress_hold=0.0 # configure_map restores only its own island, never another sea's owner.
	map_id=0
	apply_upgrades()
	var stock: Variant=data.get("ammo",[])
	if stock is Array and stock.size()>=3:
		for i in mini(stock.size(), player.ammo.size()): player.ammo[i]=clampi(int(stock[i]),0,999999)
	var saved_visited: Variant=data.get("visited",[])
	if saved_visited is Array:
		for i in mini(saved_visited.size(),visited.size()):visited[i]=bool(saved_visited[i])
	var restored_map: int=int(data.get("map_id",0))
	configure_map(restored_map if restored_map in CONTENT.SEA_MAP_IDS else 0)
	player.pos=START
	var position: Variant=data.get("position",[])
	if position is Array and position.size()==2:
		var point=Vector2(float(position[0]),float(position[1]))
		if point.is_finite() and not blocked(point):player.pos=point
	player.hp=clampi(int(data.get("hp",player.max_hp)),0,int(player.max_hp))
	player.shield=clampi(int(data.get("shield",player.max_shield)),0,int(player.max_shield))
	if int(player.hp)==0:player.respawn=8.0
	powder_on=false
	plates_on=false
	docked=bool(data.get("docked",false)) and can_dock()
	return true


func upgrade_guild_tower(index: int) -> bool:
	if not tower_friendly() or not CONTENT.has_guild_island(map_id) or index<0 or index>=CONTENT.TOWERS.size():return false
	var tier: int=int(tower_levels[index])
	var cost: int=300*tier*tier
	if tier>=5 or int(player.gold)<cost:return false
	player.gold-=cost;tower_levels[index]=tier+1
	for actor: Dictionary in npcs:
		if int(actor.id)==400+index:
			var config: Dictionary=CONTENT.TOWERS[index]
			actor.max_hp=roundi(float(config.hp)*(1.0+.35*tier));actor.hp=actor.max_hp
			actor.damage=roundi(float(config.damage)*(1.0+.2*tier));actor.tower_level=tier+1
			actor.max_shield=roundi(float(actor.max_hp)*.3);actor.shield=actor.max_shield
	message="%s auf Stufe %d ausgebaut" % [CONTENT.TOWERS[index].name,tier+1]
	return true

func _store_fortress_state() -> void:
	if CONTENT.has_guild_island(map_id) and not guild.is_empty():
		guild_holdings[str(map_id)]={"remaining":fortress_hold,"levels":tower_levels.duplicate()}

func _set_harbor_collision() -> void:
	harbor_outline.clear()
	for vertex: Array in island_shapes.island_harbor.points:
		harbor_outline.append(harbor-HARBOR_OFFSET+Vector2(vertex[0],vertex[1])*HARBOR_SIZE)
	harbor_bounds=Rect2(harbor_outline[0],Vector2.ZERO)
	for vertex: Vector2 in harbor_outline:harbor_bounds=harbor_bounds.expand(vertex)
