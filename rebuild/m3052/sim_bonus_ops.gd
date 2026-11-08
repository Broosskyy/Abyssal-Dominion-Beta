extends RefCounted
## Bonus maps: scroll crafting, entering/leaving instances and enemy waves.
## Static helpers operating on the sea simulation passed as `s`.
const CONTENT = preload("res://content.gd")

static func craft_scroll(s, tier: int) -> bool:
	if tier < 0 or tier >= CONTENT.BONUS_TIERS.size(): return false
	var cost = int(CONTENT.BONUS_TIERS[tier].fragments)
	if s.fragments < cost:
		s.message = "%d Fragmente für eine %s-Schriftrolle nötig" % [cost, CONTENT.BONUS_TIERS[tier].name]
		return false
	s.fragments -= cost
	s.scrolls[tier] += 1
	s.message = "%s-Schriftrolle zusammengesetzt" % CONTENT.BONUS_TIERS[tier].name
	return true

static func start_bonus(s, tier: int) -> bool:
	if tier < 0 or tier >= CONTENT.BONUS_TIERS.size() or s.in_bonus_map(): return false
	var config: Dictionary = CONTENT.BONUS_TIERS[tier]
	var resume = not s.bonus.is_empty() and int(s.bonus.tier) == tier
	if not s.bonus.is_empty() and not resume:
		s.message = "Erst die laufende %s-Bonuskarte beenden" % CONTENT.BONUS_TIERS[int(s.bonus.tier)].name
		return false
	if s.docked:
		s.message = "Vor der Bonuskarte zuerst ablegen"
		return false
	if int(s.player.hp) <= 0: return false
	if s.level < int(config.level):
		s.message = "%s-Bonuskarte: Kapitänsstufe %d benötigt" % [config.name, config.level]
		return false
	if s.clock - float(s.player.last_hit) < 6.0:
		s.message = "Bonuskarte erst 6 Sekunden ohne Treffer"
		return false
	if not resume:
		if int(s.scrolls[tier]) <= 0:
			s.message = "Keine %s-Schriftrolle · Fragmente sammeln" % config.name
			return false
		s.scrolls[tier] -= 1
		s.bonus = {"tier": tier, "wave": 0, "state": "break", "timer": 3.0, "origin": s.map_id, "origin_pos": [s.player.pos.x, s.player.pos.y]}
	else:
		s.bonus.origin = s.map_id
		s.bonus.origin_pos = [s.player.pos.x, s.player.pos.y]
	s.map_states[s.map_id] = {"npcs":s.npcs.duplicate(true),"drops":s.drops.duplicate(true)}
	s.configure_map(int(config.map))
	# A resumed run restarts its current wave from the checkpoint.
	s.bonus.state = "break"
	s.bonus.timer = 3.0
	s._arrive(s.START)
	s.message = "%s-Bonuskarte · %s" % [config.name, "Welle %d fortgesetzt" % (int(s.bonus.wave) + 1) if resume else "erste Welle formiert sich"]
	return true

static func leave_bonus(s) -> bool:
	if not s.in_bonus_map() or s.bonus.is_empty(): return false
	if str(s.bonus.state) == "fight" and s.clock - float(s.player.last_hit) < 6.0:
		s.message = "Ausgang erst 6 Sekunden ohne Treffer"
		return false
	var origin = int(s.bonus.origin) if int(s.bonus.origin) in CONTENT.SEA_MAP_IDS else 0
	var saved: Array = s.bonus.origin_pos
	var finished = str(s.bonus.state) == "done"
	if finished:
		if not s.staff.active() and not bool(s.bonus.get("staff", false)): s.bonus_runs += 1
		s.bonus = {}
	else:
		s.bonus.state = "break"
		s.bonus.timer = 3.0
	s.configure_map(origin)
	var point = Vector2(float(saved[0]), float(saved[1])) if saved.size() == 2 else s.START
	s._arrive(point if point.is_finite() and not s.blocked(point) else s.START)
	s.message = "Bonuskarte abgeschlossen · zurück auf %s" % CONTENT.MAPS[s.map_id].name if finished else "Bonuskarte verlassen · Welle %d bleibt gespeichert" % (int(s.bonus.wave) + 1)
	return true

static func _arrive(s, point: Vector2) -> void:
	s.pending_portal = -1
	s.player.pos = point
	s.player.path = []
	s.firing = false
	s.repairing = false
	s.target = -1
	s.shots.clear()
	s.events.clear()

static func bonus_wave_alive(s) -> int:
	var alive = 0
	for npc in s.npcs:
		if bool(npc.get("wave",false)) and int(npc.hp) > 0: alive += 1
	return alive

static func _step_bonus(s, delta: float) -> void:
	if s.bonus.is_empty() or not s.in_bonus_map(): return
	match str(s.bonus.state):
		"break":
			s.bonus.timer = float(s.bonus.timer) - delta
			if float(s.bonus.timer) <= 0:
				s._spawn_wave()
				s.bonus.state = "fight"
		"fight":
			if s.bonus_wave_alive() == 0: s._finish_wave()

static func _spawn_wave(s) -> void:
	var alive: Array[Dictionary] = []
	for npc in s.npcs:
		if not bool(npc.get("wave",false)) or int(npc.hp) > 0: alive.append(npc)
	s.npcs = alive
	if s.bonus_wave_alive() > 0: return
	var wave: Dictionary = CONTENT.BONUS_WAVES[int(s.bonus.wave)]
	var tier: Dictionary = CONTENT.BONUS_TIERS[int(s.bonus.tier)]
	var scale = float(CONTENT.MAPS[s.map_id].enemy_scale)
	var roster: Array[String] = []
	for i in int(wave.ships): roster.append("ship")
	for i in int(wave.elites): roster.append("elite")
	if not str(wave.boss).is_empty(): roster.append(str(wave.boss))
	for i in roster.size():
		var role = roster[i]
		var angle = TAU * float(i) / float(roster.size()) + float(s.bonus.wave) * 0.7
		var point = s._spawn_point(angle)
		var body: Dictionary
		if role == "monster":
			body = s.base_npcs[s.base_npcs.size() - 1].duplicate(true)
			body.name = "Leviathan · %stiefe" % tier.name
			body.max_hp = roundi(1650.0 * scale * 1.4)
			body.reward = roundi(240.0 * scale)
		else:
			body = s.base_npcs[(i * 3 + int(s.bonus.wave) * 2) % (s.base_npcs.size() - 1)].duplicate(true)
			var elite = role != "ship"
			body.elite = elite
			body.max_hp = roundi((760.0 if elite else 420.0) * scale * (3.5 if role == "admiral" else 1.0))
			body.max_shield = roundi(float(body.max_hp) * (0.4 if role == "admiral" else 0.25)) if elite else 0
			body.reward = roundi((110.0 if elite else 55.0) * scale * (3.0 if role == "admiral" else 1.0))
			body.power = 36.0 if elite else 23.0
			if role == "admiral":
				body.art = 7
				body.name = "Admiral · %sflotte" % tier.name
				body.power = 48.0
			else:
				body.name = "%s · %s" % [tier.name, body.name]
		s.next_id += 1
		body.id = s.next_id
		body.hp = body.max_hp
		body.shield = body.get("max_shield", 0)
		body.pos = point
		body.home = point
		body.path = []
		body.aggressive = true
		body.hunter = true
		body.wave = true
		body.boss = role in ["admiral","monster"]
		body.respawn = 0.0
		body.reload = 1.5 + float(i) * 0.4
		s.npcs.append(body)
	s.message = "Welle %d/%d · %s" % [int(s.bonus.wave) + 1, CONTENT.BONUS_WAVES.size(), wave.label]

static func _spawn_point(s, angle: float) -> Vector2:
	for radius in [720.0, 600.0, 860.0, 480.0]:
		for turn in 8:
			var point: Vector2 = s.player.pos + Vector2.from_angle(angle + float(turn) * 0.35) * radius
			if not s.blocked(point, 60.0): return point
	return s.START + Vector2.from_angle(angle) * 400.0

static func _finish_wave(s) -> void:
	var tier = int(s.bonus.tier)
	var scale = float(CONTENT.MAPS[s.map_id].enemy_scale)
	var wave = int(s.bonus.wave)
	var gold = roundi(80.0 * float(wave + 1) * scale)
	var scored = not s.staff.active() and not bool(s.bonus.get("staff", false))
	if scored:
		s.player.gold += gold
		s.essence += 1
		s.award_xp(40 * (wave + 1))
		s._event("essence", s.player.pos, 1, 0)
	s.bonus.wave = wave + 1
	if not scored:
		if int(s.bonus.wave) >= CONTENT.BONUS_WAVES.size():
			s.bonus.state = "done"
			s.bonus.chest = "Staff-Testlauf · keine Truhe"
		else:
			s.bonus.state = "break"
			s.bonus.timer = 4.0
		s.message = "Welle %d geschafft · Staff-Test ohne Belohnung" % (wave + 1)
		return
	if int(s.bonus.wave) >= CONTENT.BONUS_WAVES.size():
		s.bonus.state = "done"
		var chest = roundi(500.0 * scale)
		s.player.gold += chest
		s.supplies.powder += 5
		s.supplies.plates += 5
		s.supplies.repair_kit += 1
		s.activate_blessing()
		var type: String = CONTENT.DECK_KEYS[s.rng.randi_range(0, CONTENT.DECK_KEYS.size() - 1)]
		var deck_note: String = s._grant("deck_%s_%d" % [type, tier], 1, "", 3).text
		s.bonus.chest = "%d Gold · 5 Pulver · 5 Platten · 1 Notreparatur · %s" % [chest, deck_note]
		s.message = "Bonuskarte geschafft · Kristallsegen aktiv · Truhe: %d Gold" % chest
	else:
		s.bonus.state = "break"
		s.bonus.timer = 4.0
		s.message = "Welle %d geschafft · +%d Gold · +1 Essenz" % [wave + 1, gold]
