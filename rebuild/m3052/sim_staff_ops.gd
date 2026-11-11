extends RefCounted
## Staff tools: sign-in, presence, teleport, spawns, grants and inspection.
## Static helpers operating on the sea simulation passed as `s`.
const CONTENT = preload("res://content.gd")

static func staff_sign_in(s, code: String) -> bool:
	if s.staff.active():
		s.message = "Bereits angemeldet · %s" % s.staff.title()
		return false
	if not s.staff.sign_in(code, s.export_save()):
		s.message = "Staff-Zugang abgelehnt · Code prüfen"
		return false
	s.staff_inspected = -1
	s.message = "Staff-Zugang · %s · %s" % [s.staff.title(), CONTENT.STAFF_ENVIRONMENT]
	return true

## Restoring rewinds to the snapshot taken at sign-in; keeping marks the save as staff-modified.
static func staff_sign_out(s, restore: bool) -> bool:
	if not s.staff.active(): return false
	var snapshot: Dictionary = s.staff.snapshot.duplicate(true)
	var restored = restore and not snapshot.is_empty()
	var touched = s.staff.touched
	if bool(s.bonus.get("staff", false)) and s.in_bonus_map():
		var origin = int(s.bonus.origin) if int(s.bonus.origin) in CONTENT.SEA_MAP_IDS else 0
		var saved: Array = s.bonus.origin_pos
		s.bonus = {}
		s.configure_map(origin)
		s._arrive(s._free_water(Vector2(float(saved[0]), float(saved[1]))))
	s.staff.sign_out(restored)
	s._clear_staff_spawns()
	for npc in s.npcs: npc.erase("frozen")
	if restored:
		s.map_states.clear()
		s.restore_save(snapshot)
		s.target = -1
		s.firing = false
		s.shots.clear()
		s.events.clear()
		s.pending_portal = -1
		s.message = "Staff abgemeldet · Spielstand wie vor der Anmeldung"
	else:
		if touched: s.staff_marked = true
		s.message = "Staff abgemeldet · Änderungen behalten" + (" · Spielstand markiert" if touched else "")
	s.staff_inspected = -1
	return true

static func _staff_allow(s, permission: String, action: String, detail: String = "") -> bool:
	if not s.staff.active():
		s.message = "Kein Staff-Zugang aktiv"
		return false
	if s.staff.authorize(permission, action, detail): return true
	s.message = "Recht fehlt · %s" % CONTENT.STAFF_PERMISSIONS.get(permission, permission)
	return false

static func staff_set_presence(s, mode: String) -> bool:
	if not mode in CONTENT.STAFF_PRESENCE_ORDER or mode == s.staff.presence: return false
	if not s._staff_allow("presence", "Sichtbarkeit", CONTENT.STAFF_PRESENCE[mode].name): return false
	s.staff.presence = mode
	if s.staff.hidden(): s._calm_all()
	if s.staff.spectating(): s.firing = false
	s.message = "Sichtbarkeit: %s · %s" % [CONTENT.STAFF_PRESENCE[mode].name, CONTENT.STAFF_PRESENCE[mode].effect]
	return true

static func staff_toggle(s, key: String) -> bool:
	if not CONTENT.STAFF_FLAGS.has(key): return false
	var on = not s.staff.flag(key)
	if not s._staff_allow("ship", CONTENT.STAFF_FLAGS[key], "an" if on else "aus"): return false
	s.staff.flags[key] = on
	if key == "no_aggro" and on: s._calm_all()
	s.message = "%s %s" % [CONTENT.STAFF_FLAGS[key], "an" if on else "aus"]
	return true

static func staff_set_tap_teleport(s, on: bool) -> bool:
	if on == s.staff.tap_teleport: return false
	if on and not s._staff_allow("teleport", "Tipp-Teleport", "an"): return false
	s.staff.tap_teleport = on
	if not on: s.staff.record("Tipp-Teleport", "aus")
	s.message = "Tipp-Teleport %s" % ("an · Wasser antippen, um dorthin zu springen" if on else "aus")
	return true

static func _calm_all(s) -> void:
	for npc in s.npcs:
		npc.aggressive = false
		if npc.kind != "tower": npc.path = []
	s.shots = s.shots.filter(func(shot: Dictionary) -> bool: return int(shot.target) != 0)

static func staff_ship(s, action: String) -> bool:
	if not action in ["repair","cleanse","cooldowns"]: return false
	var names = {"repair":"Rumpf und Schild voll", "cleanse":"Effekte und Treffersperre gelöscht", "cooldowns":"Abklingzeiten zurückgesetzt"}
	if not s._staff_allow("ship", "Schiff", names[action]): return false
	match action:
		"repair":
			if int(s.player.hp) <= 0: s.player.respawn = 0.0
			s.player.hp = s.player.max_hp
			s.player.shield = s.player.max_shield
			s.repairing = false
		"cleanse":
			s.player.slow = 0.0
			s.player.last_hit = -100.0
		"cooldowns":
			for key in s.cooldowns.keys(): s.cooldowns[key] = 0.0
			s.player.reload = 0.0
	s.staff.touched = true
	s.message = "Staff · %s" % names[action]
	return true

static func staff_place_point(s, place: String) -> Vector2:
	match place:
		"harbor": return s.harbor + Vector2(70, 50)
		"portal_east": return s.edge_point("east",s.WORLD*.5) - Vector2(170,0)
		"portal_west": return s.edge_point("west",s.WORLD*.5) + Vector2(170,0)
		"fortress":
			var island = s.fortress_island()
			if island.is_empty(): return Vector2(-1, -1)
			return Vector2(island.bounds.get_center().x, island.bounds.end.y + 150.0)
	return s.START

## Staff teleport ignores level gates and the 6-second rule. Other maps need the "map" right.
static func staff_teleport(s, destination: int, place: String = "start", point: Vector2 = Vector2(-1, -1)) -> bool:
	if destination < 0 or destination >= CONTENT.MAPS.size(): return false
	if point.x < 0 and not place in s.STAFF_PLACES: return false
	var to_bonus = bool(CONTENT.MAPS[destination].get("bonus", false))
	var tier = destination - CONTENT.REGION_COUNT
	if to_bonus and not s.bonus.is_empty() and not bool(s.bonus.get("staff", false)) and not (s.in_bonus_map() and destination == s.map_id):
		s.message = "Laufende %s-Bonuskarte zuerst beenden" % CONTENT.BONUS_TIERS[int(s.bonus.tier)].name
		return false
	if place == "fortress" and point.x < 0 and not CONTENT.has_guild_island(destination):
		s.message = "Die Korsarenfestung liegt in den Schattengewässern"
		return false
	if place == "harbor" and point.x < 0 and to_bonus:
		s.message = "Bonuskarten haben keinen Hafen"
		return false
	var label = "%s %s" % [CONTENT.MAPS[destination].code, CONTENT.MAPS[destination].name]
	var detail = label + (" · %d/%d" % [roundi(point.x), roundi(point.y)] if point.x >= 0 else " · " + place)
	if not s._staff_allow("map" if destination != s.map_id else "teleport", "Teleport", detail): return false
	s.docked = false
	if int(s.player.hp) <= 0:
		s.player.hp = s.player.max_hp
		s.player.shield = s.player.max_shield
		s.player.respawn = 0.0
	if destination != s.map_id:
		var origin = s.map_id
		var origin_pos: Vector2 = s.player.pos
		if s.in_bonus_map():
			if bool(s.bonus.get("staff", false)):
				origin = int(s.bonus.origin)
				origin_pos = Vector2(float(s.bonus.origin_pos[0]), float(s.bonus.origin_pos[1]))
				s.bonus = {}
			elif not s.bonus.is_empty():
				if str(s.bonus.state) == "done": s.bonus = {}
				else:
					s.bonus.state = "break"
					s.bonus.timer = 3.0
		else:
			s.map_states[s.map_id] = {"npcs":s.npcs.duplicate(true),"drops":s.drops.duplicate(true)}
		if to_bonus and s.bonus.is_empty():
			s.bonus = {"tier": tier, "wave": 0, "state": "break", "timer": 3.0, "origin": origin, "origin_pos": [origin_pos.x, origin_pos.y], "staff": true}
		elif to_bonus:
			s.bonus.state = "break"
			s.bonus.timer = 3.0
		s.configure_map(destination)
	var goal = point if point.x >= 0 else s.staff_place_point(place)
	s._arrive(s._free_water(goal))
	s.staff.touched = true
	s._event("teleport", s.player.pos, 0, 0)
	s.message = "Teleport · %s" % detail
	return true

static func staff_teleport_target(s) -> bool:
	var victim = s.actor(s.target)
	if victim.is_empty() or int(victim.get("id", 0)) == 0: return false
	if not s._staff_allow("teleport", "Zum Ziel springen", str(victim.name)): return false
	var keep = s.target
	s._arrive(s._free_water(victim.pos + Vector2(-180, 90)))
	s.target = keep
	s.staff.touched = true
	s._event("teleport", s.player.pos, 0, 0)
	s.message = "Neben %s gesprungen" % victim.name
	return true

static func staff_summon_target(s) -> bool:
	var victim = s.actor(s.target)
	if victim.is_empty() or int(victim.get("id", 0)) == 0: return false
	if victim.kind == "tower":
		s.message = "Türme stehen fest auf der Insel"
		return false
	if not s._staff_allow("summon", "Herbeirufen", str(victim.name)): return false
	var spot = s._free_water(s.player.pos + s.player.heading * 220.0)
	victim.pos = spot
	victim.home = spot
	victim.path = []
	s.staff.touched = true
	s._event("teleport", spot, 0, int(victim.id))
	s.message = "%s herbeigerufen" % victim.name
	return true

static func staff_spawn_count(s) -> int:
	var alive = 0
	for npc in s.npcs:
		if bool(npc.get("staff_spawn", false)) and int(npc.hp) > 0: alive += 1
	return alive

static func staff_spawn(s, kind: String) -> bool:
	if not CONTENT.STAFF_SPAWNS.has(kind): return false
	s.npcs = s.npcs.filter(func(npc: Dictionary) -> bool: return not bool(npc.get("staff_spawn", false)) or int(npc.hp) > 0)
	if s.staff_spawn_count() >= s.STAFF_SPAWN_CAP:
		s.message = "Höchstens %d Staff-Ziele gleichzeitig" % s.STAFF_SPAWN_CAP
		return false
	var config: Dictionary = CONTENT.STAFF_SPAWNS[kind]
	if not s._staff_allow("spawn", "Erzeugen", str(config.name)): return false
	var body: Dictionary = (s.base_npcs[s.base_npcs.size() - 1] if kind == "monster" else s.base_npcs[{"dummy":0,"ship":1,"elite":4,"admiral":7}[kind]]).duplicate(true)
	var elite = kind in ["elite","admiral","monster"]
	var scale = float(CONTENT.MAPS[s.map_id].enemy_scale)
	s.next_id += 1
	body.id = s.next_id
	body.name = "%s · Staff" % config.name
	body.max_hp = roundi(float(config.hp) * (1.0 if kind == "dummy" else scale))
	body.hp = body.max_hp
	body.max_shield = roundi(float(body.max_hp) * 0.25) if elite and kind != "monster" else 0
	body.shield = body.max_shield
	body.elite = elite
	body.reward = 0
	body.power = 48.0 if kind == "admiral" else (36.0 if elite else 23.0)
	if kind == "admiral": body.art = 7
	var spot = s._free_water(s.player.pos + s.player.heading * 300.0)
	body.pos = spot
	body.home = spot
	body.path = []
	body.respawn = 0.0
	body.reload = 2.0
	body.staff_spawn = true
	body.frozen = kind == "dummy"
	body.aggressive = kind != "dummy"
	body.hunter = kind != "dummy"
	s.npcs.append(body)
	s.target = int(body.id)
	s.staff.touched = true
	s._event("teleport", spot, 0, int(body.id))
	s.message = "%s erzeugt · angewählt" % config.name
	return true

static func _clear_staff_spawns(s) -> void:
	s.npcs = s.npcs.filter(func(npc: Dictionary) -> bool: return not bool(npc.get("staff_spawn", false)))
	for key in s.map_states.keys():
		var state: Dictionary = s.map_states[key]
		state.npcs = state.npcs.filter(func(npc: Dictionary) -> bool: return not bool(npc.get("staff_spawn", false)))
	if s.actor(s.target).is_empty(): s.target = -1

static func staff_clear_spawns(s) -> bool:
	if s.npcs.filter(func(npc: Dictionary) -> bool: return bool(npc.get("staff_spawn", false))).is_empty():
		s.message = "Keine Staff-Ziele auf dieser Karte"
		return false
	if not s._staff_allow("spawn", "Staff-Ziele entfernen", "%d Ziele" % s.staff_spawn_count()): return false
	s._clear_staff_spawns()
	s.message = "Staff-Ziele entfernt"
	return true

static func staff_target(s, action: String) -> bool:
	var victim = s.actor(s.target)
	if victim.is_empty() or int(victim.get("id", 0)) == 0 or not action in ["freeze","heal","sink","calm"]: return false
	if action == "sink" and int(victim.hp) <= 0: return false
	var names = {"freeze":"Einfrieren" if not bool(victim.get("frozen", false)) else "Auftauen", "heal":"Heilen", "sink":"Versenken", "calm":"Beruhigen"}
	if not s._staff_allow("world", names[action], str(victim.name)): return false
	match action:
		"freeze":
			victim.frozen = not bool(victim.get("frozen", false))
			if bool(victim.frozen): victim.path = []
		"heal":
			victim.hp = victim.max_hp
			victim.shield = victim.get("max_shield", 0)
		"sink":
			victim.hp = 0
			victim.path = []
			victim.respawn = 90.0 if victim.kind == "tower" else 48.0
			s.firing = false
			s._event("sunk", victim.pos, 0, int(victim.id))
		"calm":
			victim.aggressive = false
			victim.hunter = false
			victim.path = []
	s.staff.touched = true
	s.message = "%s · %s" % [names[action], victim.name]
	return true

static func staff_world(s, action: String) -> bool:
	if not action in ["reset_npcs","reset_fortress","skip_wave","loot"]: return false
	if action == "reset_fortress" and not CONTENT.has_guild_island(s.map_id):
		s.message = "Die Korsarenfestung liegt in den Schattengewässern"
		return false
	if action == "skip_wave" and (not s.in_bonus_map() or s.bonus.is_empty() or str(s.bonus.state) == "done"):
		s.message = "Wellen gibt es nur auf einer laufenden Bonuskarte"
		return false
	var names = {"reset_npcs":"Gegner zurückgesetzt", "reset_fortress":"Festungstürme erneuert", "skip_wave":"Welle übersprungen", "loot":"Beutekiste abgeworfen"}
	if not s._staff_allow("world", "Welt", names[action]): return false
	match action:
		"reset_npcs":
			if s.in_bonus_map():
				s.npcs.clear()
				s.bonus.state = "break"
				s.bonus.timer = 3.0
			else:
				var keep: Vector2 = s.player.pos
				s.map_states.erase(s.map_id)
				s.configure_map(s.map_id)
				s.player.pos = keep
			s.target = -1
			s.firing = false
			s.shots.clear()
		"reset_fortress":
			for npc in s.npcs:
				if npc.kind != "tower": continue
				npc.hp = npc.max_hp
				npc.shield = npc.max_shield
				npc.respawn = 0.0
				npc.aggressive = false
		"skip_wave":
			if str(s.bonus.state) == "fight":
				for npc in s.npcs:
					if bool(npc.get("wave", false)): npc.hp = 0
			else: s.bonus.timer = 0.0
		"loot":
			s._add_drop(s._free_water(s.player.pos + s.player.heading * 140.0), 250)
	s.staff.touched = true
	s.message = "Staff · %s" % names[action]
	return true

static func staff_grant(s, kind: String) -> bool:
	if not CONTENT.STAFF_GRANTS.has(kind): return false
	if kind == "level" and s.level >= 20:
		s.message = "Höchste Kapitänsstufe erreicht"
		return false
	if not s._staff_allow("grant", "Gewähren", CONTENT.STAFF_GRANTS[kind]): return false
	match kind:
		"gold": s.player.gold += 10000
		"essence": s.essence += 25
		"fragments": s.fragments += 16
		"scrolls":
			for i in s.scrolls.size(): s.scrolls[i] += 1
		"supplies":
			for key in CONTENT.SUPPLY_KEYS: s.supplies[key] += 10
		"ammo":
			for i in s.player.ammo.size(): s.player.ammo[i] += [1500, 600, 400, 80, 40, 80, 40][i]
		"decks":
			for type in CONTENT.DECK_KEYS:
				if not s.owns_deck(type, 2): s.grant_deck(type, 2)
		"blessing": s.activate_blessing()
		"tide_deck": s.add_tide_deck(1800.0)
		"flask": s.free_flask_day = ""
		"level":
			s.level += 1
			s.xp = 0
			s.apply_upgrades()
			s._event("level", s.player.pos, s.level, 0)
	s.staff.touched = true
	s.message = "Gewährt · %s" % CONTENT.STAFF_GRANTS[kind]
	return true

## Inspection is logged once per target so the panel can refresh freely.
static func staff_inspect(s) -> Dictionary:
	var victim = s.actor(s.target)
	if victim.is_empty() or int(victim.get("id", 0)) == 0 or not s.staff.can("inspect"): return {}
	if s.staff_inspected != s.target:
		s.staff_inspected = s.target
		s.staff.record("Inspizieren", str(victim.name))
	return {"id": int(victim.id), "name": str(victim.name), "kind": str(victim.kind), "hp": int(victim.hp), "max_hp": int(victim.max_hp),
		"shield": int(victim.get("shield", 0)), "max_shield": int(victim.get("max_shield", 0)), "state": str(victim.get("state", "")),
		"aggressive": bool(victim.get("aggressive", false)), "frozen": bool(victim.get("frozen", false)), "elite": bool(victim.get("elite", false)),
		"reward": int(victim.get("reward", 0)), "staff_spawn": bool(victim.get("staff_spawn", false)),
		"pos": victim.pos, "distance": roundi(s.player.pos.distance_to(victim.pos))}
