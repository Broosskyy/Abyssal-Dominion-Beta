extends RefCounted
## Guild membership, guild islands, fortress towers and conquest.
## Static helpers operating on the sea simulation passed as `s`.
const CONTENT = preload("res://content.gd")

static func leave_guild(s) -> bool:
	if s.guild.is_empty(): return false
	s.message = "Gilde [%s] aufgelöst" % s.guild.tag
	s.guild = {}
	s.guild_holdings.clear()
	s.fortress_hold = 0.0
	return true

static func guild_island_held(s) -> bool:
	return not s.guild.is_empty() and (s.fortress_hold > 0 or s.guild_holdings.values().any(func(holding):return float(holding.get("remaining",0))>0))

static func tower_friendly(s) -> bool:
	return not s.guild.is_empty() and s.fortress_hold>0 and CONTENT.has_guild_island(s.map_id)

static func tower_tag(s) -> String:
	return str(s.guild.tag) if s.tower_friendly() else CONTENT.FORTRESS_TAG

static func fortress_island(s) -> Dictionary:
	if not CONTENT.has_guild_island(s.map_id): return {}
	return s.islands[CONTENT.FORTRESS_ISLAND]

static func _add_fortress(s) -> void:
	var island: Dictionary = s.islands[CONTENT.FORTRESS_ISLAND]
	island.name = "Korsarenfestung"
	var center: Vector2 = island.bounds.get_center()
	for i in CONTENT.TOWERS.size():
		var config: Dictionary = CONTENT.TOWERS[i]
		var point: Vector2 = center + config.offset * island.bounds.size
		while not s.on_land(point) and point.distance_to(center) > 8: point = point.move_toward(center, 8.0)
		var tier: int=int(s.tower_levels[i])
		var hp: int=roundi(float(config.hp)*(1.0+.35*(tier-1)))
		var shield = roundi(float(hp) * 0.3)
		s.npcs.append({"id": 400 + i, "name": config.name, "kind": "tower", "tower": config.kind, "pos": point,
			"home": point, "heading": Vector2.LEFT, "path": [], "hp": hp, "max_hp": hp, "tower_level":tier,
			"shield": shield, "max_shield": shield, "speed": 0.0, "reload": float(i) * 0.7, "repath": 0.0,
			"state": "guard", "patrol": 0, "aggressive": false, "slow": 0.0, "respawn": 0.0, "reward": 0,
			"art": i, "elite": true, "range": config.range, "damage": roundi(float(config.damage)*(1.0+.2*(tier-1))), "shots": config.shots,
			"rate": config.reload, "last_hit": -100.0})

static func towers_alive(s) -> int:
	var alive = 0
	for npc in s.npcs:
		if npc.kind == "tower" and int(npc.hp) > 0: alive += 1
	return alive

static func _step_tower(s, npc: Dictionary, delta: float) -> void:
	if int(npc.hp) <= 0:
		npc.respawn = float(npc.respawn) - delta
		if float(npc.respawn) <= 0:
			npc.hp = npc.max_hp
			npc.shield = npc.max_shield
			npc.aggressive = false
		return
	npc.reload = maxf(0, float(npc.reload) - delta)
	if str(npc.tower) != "guardian" and s._guardian_alive():
		npc.shield = minf(float(npc.max_shield), float(npc.shield) + 40.0 * delta)
	if not s.npc_engages(npc):
		npc.state = "guard"
		return
	npc.state = "attack"
	if float(npc.reload) > 0: return
	var weapon = "chain" if str(npc.tower) == "chain" else ("mortar" if str(npc.tower) == "mortar" else "cannon")
	s._launch(int(npc.id), 0, weapon, int(npc.damage), int(npc.shots))
	npc.reload = float(npc.rate)

static func _guardian_alive(s) -> bool:
	for npc in s.npcs:
		if npc.kind == "tower" and str(npc.tower) == "guardian" and int(npc.hp) > 0: return true
	return false

static func _check_fortress(s) -> void:
	if s.towers_alive() > 0: return
	s.fortress_conquests += 1
	s.player.gold += 900
	s.essence += 3
	s.fragments += 2
	s.award_xp(300)
	var island = s.fortress_island()
	s._event("conquest", island.bounds.get_center() if not island.is_empty() else s.player.pos, 900, 0)
	if s.guild.is_empty():
		for npc in s.npcs:
			if npc.kind == "tower": npc.respawn = 180.0
		s.message = "Korsarenfestung erobert · +900 Gold · gründe eine Gilde, um sie zu halten"
	else:
		s.fortress_hold = CONTENT.FORTRESS_HOLD
		for npc in s.npcs:
			if npc.kind == "tower": npc.respawn = 6.0
		s.message = "Korsarenfestung erobert · [%s] hält die Gildeninsel 30 Minuten" % s.guild.tag
