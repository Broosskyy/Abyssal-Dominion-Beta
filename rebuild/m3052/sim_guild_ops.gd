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

# One authoritative local ownership view. The current sea's live countdown
# takes precedence over its saved snapshot (which might still be stale).
# A remote MMO owner is NOT inferred: this is strictly a local beta preview.
static func holding_remaining(s, sea_id: int) -> float:
	if s.guild.is_empty() or not CONTENT.has_guild_island(sea_id):return 0.0
	if sea_id==s.map_id:return maxf(0.0,float(s.fortress_hold))
	var entry: Dictionary=s.guild_holdings.get(str(sea_id),{})
	return maxf(0.0,float(entry.get("remaining",0.0)))

static func owner_tag(s,sea_id: int) -> String:
	if holding_remaining(s,sea_id)<=0.0:return CONTENT.FORTRESS_TAG
	return str(s.guild.get("tag",CONTENT.FORTRESS_TAG))

static func guild_island_held(s) -> bool:
	if s.guild.is_empty():return false
	if holding_remaining(s,s.map_id)>0.0:return true
	for key: String in s.guild_holdings:
		if holding_remaining(s,int(key))>0.0:return true
	return false

static func tower_friendly(s) -> bool:
	return holding_remaining(s,s.map_id)>0.0

static func tower_tag(s) -> String:
	return owner_tag(s,s.map_id)

# Ordered live siege data, one record per independently destroyable turret.
static func tower_status(s) -> Array[Dictionary]:
	var status: Array[Dictionary]=[]
	if not CONTENT.has_guild_island(s.map_id):return status
	for i in CONTENT.TOWERS.size():
		var spec: Dictionary=CONTENT.TOWERS[i]
		var actor: Dictionary={}
		for candidate: Dictionary in s.npcs:
			if str(candidate.get("kind",""))=="tower" and int(candidate.get("id",-1))==400+i:
				actor=candidate
				break
		status.append({
			"index":i,"name":str(spec.name),
			"level":int(s.tower_levels[i]),
			"hp":maxi(0,int(actor.get("hp",0))),
			"max_hp":maxi(1,int(actor.get("max_hp",spec.hp))),
			"shield":maxi(0,int(actor.get("shield",0))),
			"alive":not actor.is_empty() and int(actor.get("hp",0))>0,
			"siege_locked":not actor.is_empty() and int(actor.get("hp",0))<=0 and not s.guild.is_empty() and not s.tower_friendly(),
			"respawn":maxf(0.0,float(actor.get("respawn",0.0)))
		})
	return status

static func fortress_island(s) -> Dictionary:
	if not CONTENT.has_guild_island(s.map_id): return {}
	return s.islands[CONTENT.FORTRESS_ISLAND]

static func _add_fortress(s) -> void:
	var island: Dictionary = s.islands[CONTENT.FORTRESS_ISLAND]
	island.name = "Korsarenfestung"
	var center: Vector2 = island.bounds.get_center()
	for i in CONTENT.TOWERS.size():
		var config: Dictionary = CONTENT.TOWERS[i]
		var point: Vector2 = _tower_point(s,island,center + config.offset * island.bounds.size)
		var tier: int=int(s.tower_levels[i])
		var hp: int=roundi(float(config.hp)*(1.0+.35*(tier-1)))
		var shield = roundi(float(hp) * 0.3)
		s.npcs.append({"id": 400 + i, "name": config.name, "kind": "tower", "tower": config.kind, "pos": point,
			"home": point, "heading": Vector2.LEFT, "path": [], "hp": hp, "max_hp": hp, "tower_level":tier,
			"shield": shield, "max_shield": shield, "speed": 0.0, "reload": float(i) * 0.7, "repath": 0.0,
			"state": "guard", "patrol": 0, "aggressive": false, "slow": 0.0, "respawn": 0.0, "reward": 0,
			"art": i, "elite": true, "range": config.range, "damage": roundi(float(config.damage)*(1.0+.2*(tier-1))), "shots": config.shots,
			"rate": config.reload, "last_hit": -100.0})

static func _tower_point(s,island: Dictionary,desired: Vector2) -> Vector2:
	# Regional coast silhouettes differ. Choose separated land sites instead of
	# pulling every off-coast emplacement toward the same island center.
	var best: Vector2=island.bounds.get_center()
	var score: float=INF
	for row in range(1,20):
		for column in range(1,20):
			var point: Vector2=island.bounds.position+island.bounds.size*Vector2(column/20.0,row/20.0)
			if not Geometry2D.is_point_in_polygon(point,island.outline):continue
			var separated:=true
			for npc: Dictionary in s.npcs:
				if str(npc.kind)=="tower" and point.distance_to(npc.pos)<100.0:separated=false;break
			if not separated:continue
			var distance: float=point.distance_squared_to(desired)
			if distance<score:score=distance;best=point
	return best

static func towers_alive(s) -> int:
	var alive = 0
	for npc in s.npcs:
		if npc.kind == "tower" and int(npc.hp) > 0: alive += 1
	return alive

static func _step_tower(s, npc: Dictionary, delta: float) -> void:
	if int(npc.hp) <= 0:
		# A founded guild can capture the fortress by destroying all twelve
		# towers one after another. Their ruins stay down for the duration of
		# the siege; a 90-second auto-rebuild must not undo prior progress.
		# After conquest, friendly towers use their short rebuild countdown.
		# Without a founded guild, the fortress is only a neutral practice fight.
		if not s.guild.is_empty() and not s.tower_friendly():
			npc.respawn=0.0
			return
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
