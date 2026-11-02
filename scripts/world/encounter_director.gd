class_name EncounterDirector
extends Node
const M216ShipCombatFxScript = preload("res://scripts/visual/m216_ship_combat_fx.gd")

signal encounter_changed

var catalog := EncounterCatalog.new()
var world: Node3D
var content: Node3D
var player: ShipMotor
var sector_key := "0,0"
var biome: Dictionary = {}
var level := 1
var sector_states: Dictionary = {}
var active_slots: Dictionary = {}
var pending_slots: Dictionary = {}
var admiral_ship: ShipMotor
var admiral_retry := 0.0
var rng := RandomNumberGenerator.new()
var notice := ""
var notice_time := 0.0
var resolved_spawn_pool:Dictionary={}
var resolved_spawn_table:Dictionary={}
var formation_offsets:Array[Vector3]=[]
var encounter_region_id:String=""

const NPC_TITLES := {
	"raider": ["Blackwake Corsair", "Crimson Marauder", "Reef Reaver"],
	"scout": ["Sea Wasp", "Swift Jackal", "Tide Runner"],
	"tank": ["Iron Galleon", "Bulwark", "Dread Hulk"],
	"sniper": ["Longshot Clipper", "Storm Hunter", "Deadeye"],
	"leviathan": ["Tide Leviathan"],
}


func configure(map: Node3D, root: Node3D, coordinate: Vector2i, map_data: Dictionary, captain: ShipMotor) -> void:
	world = map
	content = root
	player = captain
	sector_key=map.current_stable_sector_id() if map!=null else "%d,%d"%[coordinate.x,coordinate.y]
	biome = catalog.biome_profile(str(map_data.biome))
	level = int(map_data.level)
	var region:Dictionary=map.current_region_contract() if map!=null else {}
	var stable_sector:Dictionary=WorldSectorRegistry.by_id(map.current_stable_sector_id()) if map!=null else {}
	resolved_spawn_pool=DynamicSpawnPoolResolver.resolve(get_tree(),stable_sector,region,biome.get("slots",[]))
	resolved_spawn_table=DynamicSpawnTable.effective(get_tree(),map.current_stable_sector_id(),str(region.get("id",stable_sector.get("region_id",""))),resolved_spawn_pool,biome)
	formation_offsets=DynamicSpawnTable.formation_offsets(get_tree(),str(resolved_spawn_table.get("formation_id","")),int(resolved_spawn_table.get("slot_count",biome.get("slots",[]).size())))
	encounter_region_id=str(region.get("id",stable_sector.get("region_id","")))
	rng.seed = coordinate.x * 9176 + coordinate.y * 6323 + 173
	active_slots.clear()
	pending_slots.clear()
	admiral_ship = null
	admiral_retry = 0.0
	notice_time = 0.0
	if not sector_states.has(sector_key):
		sector_states[sector_key] = {"kills": 0, "cooldown": 0.0}
	for slot in int(resolved_spawn_table.get("slot_count",biome.get("slots",[]).size())):
		pending_slots[slot]=0.1+float(slot)*0.08
	encounter_changed.emit()


func _process(delta: float) -> void:
	notice_time = maxf(0.0, notice_time - delta)
	if not is_instance_valid(content) or biome.is_empty():
		return
	var state: Dictionary = sector_states[sector_key]
	state.cooldown = maxf(0.0, float(state.cooldown) - delta)
	for slot in pending_slots.keys():
		pending_slots[slot] = float(pending_slots[slot]) - delta
		if float(pending_slots[slot]) <= 0.0:
			if _spawn(int(slot), false):
				pending_slots.erase(slot)
			else:
				pending_slots[slot]=maxf(0.25,float(resolved_spawn_table.get("respawn_seconds",2.0)))
	admiral_retry = maxf(0.0, admiral_retry - delta)
	if _boss_available_for_level() and int(state.kills)>=int(resolved_spawn_table.get("admiral_kills_required",biome.get("required_kills",3))) and float(state.cooldown) <= 0.0:
		if not is_instance_valid(admiral_ship) and admiral_retry <= 0.0:
			admiral_retry = 2.0
			_spawn(-1, true)


func status_text() -> String:
	if biome.is_empty():
		return ""
	if is_instance_valid(admiral_ship):
		var phase := int(admiral_ship.get_meta("boss_phase", 1))
		var kind := str(admiral_ship.get_meta("encounter_kind", "admiral"))
		return "%s — %s PHASE %d" % [admiral_ship.name.to_upper(), "HUNT" if kind == "monster" else "ACTIVE", phase]
	var state: Dictionary = sector_states[sector_key]
	if not _boss_available_for_level():
		return "Küstenpatrouille · neutrale NPCs reagieren erst auf Angriff"
	if float(state.cooldown) > 0.0:
		return "Admiral restocking: %ds" % ceili(float(state.cooldown))
	return "Boss Hunt: %d/%d NPC kills"%[int(state.kills),int(resolved_spawn_table.get("admiral_kills_required",biome.get("required_kills",3)))]


func export_state() -> Dictionary:
	return sector_states.duplicate(true)


func import_state(saved:Dictionary)->void:
	sector_states.clear()
	for row in WorldSectorRegistry.effective_all():
		var stable_id:=str(row.get("id",""))
		var entry:Variant=saved.get(stable_id,{})
		if not entry is Dictionary:
			var c:Array=row.get("legacy_coord",[])
			if c.size()>=2:entry=saved.get("%d,%d"%[int(c[0]),int(c[1])],{})
		if entry is Dictionary and not (entry as Dictionary).is_empty():
			sector_states[stable_id]={"kills":clampi(int(entry.get("kills",0)),0,999),"cooldown":clampf(float(entry.get("cooldown",0.0)),0.0,3600.0)}
	if not sector_key.is_empty() and not sector_states.has(sector_key):
		sector_states[sector_key]={"kills":0,"cooldown":0.0}


func _regional_npc_slot(slot:int,admiral:bool)->String:
	if admiral:
		var capstone:=CapstoneEncounterRoles.boss_slot(level,"")
		if not capstone.is_empty():return capstone
		return DynamicSpawnPoolResolver.select_id(resolved_spawn_pool,"admiral",0)
	return DynamicSpawnPoolResolver.select_id(resolved_spawn_pool,"npc",slot)

func _boss_available_for_level()->bool:
	return level>=3

func _elite_available_for_level()->bool:
	return level>=4

func _boss_is_monster_for_level()->bool:
	var fallback:=(level==3 and str(biome.get("boss_kind","admiral"))=="monster") or level==17 or level==19 or level==32 or level==34 or level==38 or level==48
	return CapstoneEncounterRoles.boss_kind(level,"monster" if fallback else "admiral")=="monster"

func _special_hunter_spawn(slot:int,admiral:bool)->bool:
	return not admiral and CapstoneEncounterRoles.has(level) and slot>=0 and slot==int(resolved_spawn_table.get("slot_count",biome.get("slots",[]).size()))-1
func _special_hunter_slot()->String:
	var configured:=CapstoneEncounterRoles.hunter_slot(level)
	if not configured.is_empty():return configured
	return DynamicSpawnPoolResolver.select_id(resolved_spawn_pool,"monster",0)

func _cursed_monster_variant()->String:
	if level==17:return "cursed_serpent"
	if level==19:return "ghost_whale"
	if level==32:return "ancient_guardian"
	if level==34:return "titan_spawn"
	if level==38:return "void_serpent"
	if level==40:return "void_leviathan"
	if level==45:return "sovereign_leviathan"
	if level==48:return "dominion_rift_guardian"
	if level==50:return "dominion_crown_guardian"
	return ""

func _boss_archetype_for_level()->String:
	if _boss_is_monster_for_level():
		return str(biome.get("boss_archetype","leviathan"))
	return "tank"

func _boss_title_for_level()->String:
	if level==17:return "Mirecoil Serpent"
	if level==19:return "Lantern Ghost Whale"
	if level==32:return "Ancient Guardian"
	if level==34:return "Titan Spawn"
	if level==38:return "Blackglass Serpent"
	if level==40:return CapstoneEncounterRoles.boss_title(level,"Void Admiral")
	if level==45:return CapstoneEncounterRoles.boss_title(level,"Sovereign Admiral")
	if level==48:return "Dominion Rift Guardian"
	if level==49:return "Abyssal High Admiral"
	if level==50:return CapstoneEncounterRoles.boss_title(level,"Legendary Dominion Admiral")
	if level>=51 and level<=60:return M157EncounterProfileCatalog.admiral_title(level,str(biome.get("admiral","Tide Admiral")))
	if level==44:return "Sovereign High Admiral"
	if _boss_is_monster_for_level():return str(biome.get("boss_title","Tide Leviathan"))
	if level>=6 and level<=50:return M158LegacyEncounterCatalog.boss_title(level,str(biome.get("admiral","Tide Admiral")))
	return str(biome.get("admiral","Tide Admiral"))

func _spawn(slot: int, admiral: bool) -> bool:
	var active_enemy_count:=get_tree().get_nodes_in_group("enemy").size()
	if not EncounterRuntimeBudget.can_spawn(active_enemy_count,admiral):return false
	var spawn_kind:="admiral" if admiral else "patrol"
	var position:=_find_spawn_position(spawn_kind,slot)
	if not position.is_finite():return false
	if not admiral and slot>=0 and slot<formation_offsets.size():position+=formation_offsets[slot]
	var special_hunter:=_special_hunter_spawn(slot,admiral)
	var weighted:=DynamicSpawnTable.weighted_pick(resolved_spawn_table,rng,"admiral") if admiral else DynamicSpawnTable.weighted_pick_any(resolved_spawn_table,rng,["npc","monster"])
	var weighted_id:=str(weighted.get("content_id",""))
	var weighted_kind:=str(weighted.get("kind","admiral" if admiral else "npc"))
	var ordinary_monster:=not admiral and weighted_kind=="monster"
	if ordinary_monster:
		var monster_position:=_find_spawn_position("monster",slot)
		if monster_position.is_finite():position=monster_position
	var archetype:String="leviathan" if special_hunter or ordinary_monster else (_boss_archetype_for_level() if admiral else str(weighted.get("archetype",biome.slots[posmod(slot,biome.slots.size())])))
	var elite:bool=not admiral and not ordinary_monster and bool(weighted.get("elite",_elite_available_for_level() and slot==int(resolved_spawn_table.get("slot_count",biome.slots.size()))-1))
	var profile := catalog.npc_profile(archetype, level, admiral, elite)
	if profile.is_empty():
		return false
	var names: Array = NPC_TITLES.get(archetype, [archetype.capitalize()])
	var title:String=CapstoneEncounterRoles.hunter_title(level) if special_hunter else (_boss_title_for_level() if admiral else "%s"%str(names[slot%names.size()]))
	var monster:bool=(admiral and _boss_is_monster_for_level()) or special_hunter or ordinary_monster
	var hull_color := Color("254f59") if monster else Color("6b2420")
	var ship := ProceduralFactory.create_ship(title, position, hull_color, false) as ShipMotor
	var regional_slot:=_special_hunter_slot() if special_hunter else (weighted_id if not weighted_id.is_empty() else _regional_npc_slot(slot,admiral))
	var dynamic_definition:=DynamicEncounterContent.definition(get_tree(),regional_slot) if not regional_slot.is_empty() else {}
	if not dynamic_definition.is_empty():
		title=str(dynamic_definition.get("name",title))
	if level>=41 and level<=45 and not admiral and regional_slot=="NPC-SHIP-SOV-004":
		var escort:=SovereignEscortMechanics.new()
		escort.name="SovereignEscortMechanics"
		ship.add_child(escort)
		escort.setup(ship,player)
	ship.set_meta("visual_profile", "procedural_monster" if monster else (regional_slot if not regional_slot.is_empty() else str(profile.visual)))
	var monster_variant:=_cursed_monster_variant()
	var production_slot:=regional_slot if special_hunter or ordinary_monster else ("monster_early_01" if monster else regional_slot)
	if monster_variant=="cursed_serpent":production_slot="monster_cursed_serpent_01"
	elif monster_variant=="ghost_whale":production_slot="monster_ghost_whale_01"
	elif monster_variant=="ancient_guardian":production_slot="monster_ancient_guardian_01"
	elif monster_variant=="titan_spawn":production_slot="monster_titan_spawn_01"
	elif monster_variant=="void_serpent":production_slot="MON-VOID-001"
	elif monster_variant=="void_leviathan":production_slot="MON-VOID-002"
	elif monster_variant=="sovereign_leviathan":production_slot="MON-SOV-001"
	elif monster_variant=="dominion_rift_guardian":production_slot="MON-DOM-001"
	elif monster_variant=="dominion_crown_guardian":production_slot="MON-DOM-002"
	ship.set_meta("production_slot",production_slot)
	ship.set_meta("placeholder_replacement_ready",not production_slot.is_empty())
	if production_slot.begins_with("SHIP-PROG-"):
		ProceduralShipSilhouetteAdapter.apply(ship,production_slot)
	elif not monster:
		if level<=BeginnerRules.LAST_BEGINNER_LEVEL:
			var p0_index:=posmod(slot if slot>=0 else level,5)+1
			var p0_slot:="NPC-SHIP-EARLY-%03d"%p0_index
			ship.set_meta("visual_production_slot",p0_slot)
			ProceduralShipSilhouetteAdapter.apply(ship,p0_slot)
		else:
			var family_index:int=abs(production_slot.hash())%10 if not production_slot.is_empty() else posmod(slot,10)
			ProceduralShipSilhouetteAdapter.apply(ship,"SHIP-PROG-%03d"%(family_index+1))
	if production_slot in ["MON-VOID-001","MON-VOID-002"]:
		var void_mechanic:=VoidMonsterMechanics.new()
		void_mechanic.name="VoidMonsterMechanics"
		ship.add_child(void_mechanic)
		void_mechanic.setup(ship,player)
	if production_slot in ["monster_ancient_guardian_01","monster_titan_spawn_01"]:
		var ancient_mechanic:=AncientGuardianMechanics.new()
		ancient_mechanic.name="AncientGuardianMechanics";ship.add_child(ancient_mechanic)
		ancient_mechanic.setup(ship,player,"relic_barrier" if production_slot=="monster_ancient_guardian_01" else "pressure_pulse")
		var prep:=player.get_node_or_null("WorldBossPrep") as WorldBossPrep
		if prep!=null:ancient_mechanic.mechanic_fired.connect(prep.record_mechanic)
	var region_contract:Dictionary = world.current_region_contract() if world != null else {}
	if not region_contract.is_empty():
		var region_id := str(region_contract.get("id", ""))
		var regional_roles := {
			"crimson_sea": ["crimson_skirmisher", "crimson_guard", "crimson_hunter"],
			"drowned_reach": ["drowned_raider", "drowned_bulwark", "wraith_scout"],
			"stormreach": ["storm_skirmisher", "storm_guard", "storm_hunter"],
			"ember_shoals": ["ember_brawler", "ember_bulwark", "ember_artillery"],
			"veil_sea": ["veil_stalker", "veil_marksman", "veil_warden"],
			 "cursed_dominion": ["cursed_raider","cursed_marksman","cursed_bulwark","cursed_hunter"],
						"abyssal_frontier":["frontier_raider","frontier_status","frontier_bulwark","frontier_hunter"],
			"ancient_guardian_seas":["ancient_raider","relic_guard","titan_piercer","guardian_hunter"],
			"void_sea":["void_raider","void_guard","void_hunter"],
			"sovereign_waters":["sovereign_raider","sovereign_guard","banner_hunter","hero_escort"],
			"abyssal_dominion":["dominion_raider","legendary_guard","rift_hunter"],
			"dreadwater_march":["dreadwater_vanguard","dreadwater_marksman","dreadwater_chain_hunter"],
			"iron_maw_reach":["ironmaw_siege_guard","ironmaw_mortar_line","ironmaw_hunter"],
		}
		var role_rows: Array = regional_roles.get(region_id, [])
		if admiral:
			ship.set_meta("regional_combat_role", "%s_admiral" % region_id)
		elif not role_rows.is_empty():
			ship.set_meta("regional_combat_role", str(role_rows[posmod(slot, role_rows.size())]))
	var visual_region:=str(region_contract.get("id","")) if not region_contract.is_empty() else ""
	RegionalNpcVisualAdapter.apply(ship,visual_region,str(ship.get_meta("regional_combat_role","")))
	ship.set_meta("is_admiral",admiral)
	ship.set_meta("boss_phase", 1)
	if admiral and level>=6 and level<=50:
		ship.set_meta("m158_phase_profile",M158LegacyEncounterCatalog.phase_profile(level))
		ship.set_meta("m158_encounter_identity",M158LegacyEncounterCatalog.identity(level))
		ship.set_meta("m158_loot_profile",M158LegacyEncounterCatalog.loot_profile(level))
	var regional_hunter:=regional_slot.ends_with("_hunter")
	ship.set_meta("encounter_kind","monster" if monster else ("admiral" if admiral else ("hunter_target" if regional_hunter else "ship")))
	ship.set_meta("capstone_hunter",special_hunter)
	ship.set_meta("content_id",regional_slot)
	ship.set_meta("content_tags",weighted.get("tags",[]))
	ship.set_meta("spawn_table_entry",weighted.duplicate(true))
	ship.set_meta("hunter_objective_target",regional_hunter or monster or ordinary_monster)
	ship.set_meta("combat_level", level + (2 if admiral else (1 if elite else 0)))
	ship.set_meta("archetype", archetype)
	ship.set_meta("rarity", "boss" if admiral else ("elite" if elite else "common"))
	ship.set_meta("encounter_rank", "boss" if admiral else ("elite" if elite else "normal"))
	ship.set_meta("encounter_profile", profile)
	ship.set_meta("encounter_zone_region",encounter_region_id)
	ship.set_meta("encounter_zone_kind","admiral" if admiral else ("monster" if monster else "patrol"))
	if level>=51 and level<=60:
		var m157_profile:=M157EncounterProfileCatalog.level(level)
		ship.set_meta("m157_signature_mechanic",str(m157_profile.get("signature_mechanic","")))
		ship.set_meta("m157_loot_profile",str(m157_profile.get("loot_profile","")))
	# Beginner seas are neutral: NPCs patrol and only retaliate after the player attacks.
	ship.set_meta("passive_until_attacked", level <= BeginnerRules.LAST_BEGINNER_LEVEL and not admiral)
	ship.set_meta("provoked", false)
	# M228: living-sea identity rides on the existing spawn/zone authority; no additional population is created.
	M228LivingSeaEncounterCatalog.apply(ship, encounter_region_id, "monster" if monster else ("admiral" if admiral else "patrol"), slot, bool(ship.get_meta("passive_until_attacked", false)))
	# M229: classify existing slots into readable formation/territory roles; never spawns extra members.
	M229EncounterFormationCatalog.apply(ship, encounter_region_id, "monster" if monster else ("admiral" if admiral else "patrol"), slot, str(ship.get_meta("encounter_rank", "normal")))
	var health := ShipHealth.new()
	health.name = "Health"
	health.max_health = float(profile.hull)
	if level>=51 and level<=60:
		var hp_profile:=M157EncounterProfileCatalog.level(level)
		health.max_health*=float(hp_profile.get("admiral_hull_mult",1.0) if admiral else (hp_profile.get("elite_hull_mult",1.0) if elite else 1.0))
	health.auto_respawn = false
	ship.add_child(health)
	var weapons := ShipWeapons.new()
	weapons.name = "Weapons"
	ship.add_child(weapons)
	var ai := EnemyShipAI.new()
	ai.name = "EnemyAI"
	ai.archetype = archetype
	ship.add_child(ai)
	if not dynamic_definition.is_empty():
		DynamicEncounterContent.apply_definition(ship,dynamic_definition)
	content.add_child(ship)
	P1RegionalPresentationAdapter.apply_entity.call_deferred(ship,visual_region,str(ship.get_meta("regional_combat_role","")),admiral or monster)
	# Apply after AI ready, which installs archetype defaults.
	health.armor = float(profile.armor)
	weapons.damage = float(profile.damage)
	if level>=51 and level<=60:weapons.damage*=float(M157EncounterProfileCatalog.level(level).get("damage_mult",1.0))
	weapons.cannon_index = int(profile.cannon)
	weapons.ammo_index = int(profile.ammo)
	ship.cruise_speed = float(profile.speed)
	ai.desired_range = float(profile.range)
	ai.leash_range = 55.0 if admiral else (46.0 if elite else 40.0)
	if monster:
		ship.add_to_group("monsters")
		if level==3:
			ship.set_meta("production_slot","MON-KRAKEN-001")
			ship.set_meta("visual_production_slot","MON-KRAKEN-001")
			ship.set_meta("first_monster_teaching",true)
			ship.set_meta("teaching_icon","m76_first_monster")
			ship.set_meta("teaching_hint","MONSTER · HARPUNE EMPFOHLEN")
		if monster_variant.is_empty():ProceduralFactory.apply_sea_monster_visual(ship,Color("275e68"))
		else:ProceduralFactory.apply_cursed_monster_visual(ship,monster_variant)
		if level==3:P0MonsterFallbackAdapter.apply_first_monster(ship)
		var monster_visual:=ship.get_node_or_null("AssetVisual") as Node3D
		if monster_visual != null:
			MonsterAnimationAdapter.play_if_present(monster_visual, ["Idle","idle"])
	health.ship_sunk.connect(_on_npc_sunk.bind(slot, admiral))
	if admiral:
		admiral_ship = ship
		ship.get_node("Visual/SelectionRing").visible = true
		notice = "%s EMERGED" % title.to_upper() if monster else "%s ARRIVED" % title.to_upper()
		notice_time = 5.0
		CombatVfx.action(get_tree(), "monster_arrival" if monster else "admiral_arrival", ship.global_position)
	else:
		active_slots[slot] = ship
	encounter_changed.emit()
	return true


func _on_npc_sunk(ship: ShipMotor, attacker: Node3D, slot: int, admiral: bool) -> void:
	var state: Dictionary = sector_states[sector_key]
	if admiral:
		admiral_ship = null
		state.kills = 0
		state.cooldown = float(catalog.data.admiral.cooldown_seconds)
		notice = "BOSS DEFEATED — LEGENDARY SALVAGE IN THE WATER"
		notice_time = 5.0
	else:
		active_slots.erase(slot)
		pending_slots[slot] = float(biome.respawn_seconds)
	var credited: bool = is_instance_valid(attacker) and attacker.is_in_group("player")
	if credited:
		var sunk_slot:=str(ship.get_meta("production_slot",""))
		if level>=31:
			var prep:=attacker.get_node_or_null("WorldBossPrep") as WorldBossPrep
			if prep!=null:
				prep.record_clear(sunk_slot);prep.refresh_inventory(attacker.get_node_or_null("Inventory") as PlayerInventory)
		if not admiral and not is_instance_valid(admiral_ship) and float(state.cooldown) <= 0.0:
			state.kills = mini(int(state.kills) + 1, int(biome.required_kills))
		var profile: Dictionary = ship.get_meta("encounter_profile")
		var progression := attacker.get_node("Progression") as PlayerProgression
		var post:=attacker.get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
		var services:=ServiceLocator.from(get_tree())
		if services!=null and services.progression!=null:
			services.progression.add_xp(int(profile.xp),"encounter_sink")
		else:
			progression.add_xp(int(profile.xp))
		(attacker.get_node("Missions") as MissionSystem).record_sink()
		var quest_tags:=QuestActivityBus.combat_tags(ship)
		for tag in ship.get_meta("content_tags",[]):
			if str(tag) not in quest_tags:quest_tags.append(str(tag))
		QuestActivityBus.emit(get_tree(),"sink",{"content_id":str(ship.get_meta("content_id","")),"tags":quest_tags,"amount":1})
		var trial_runtime:=attacker.get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
		if trial_runtime!=null:
			if admiral:trial_runtime.record("boss_sink")
			elif bool(ship.get_meta("capstone_hunter",false)):trial_runtime.record("guardian_sink")
			elif bool(ship.get_meta("rarity","common")=="elite"):trial_runtime.record("elite_sinks")
			else:trial_runtime.record("qualified_sinks")
		if level>=6 and level<=60:
			var roster:=attacker.get_node("ShipRoster") as PlayerShipRoster
			var elite:=bool(ship.get_meta("rarity","common")=="elite")
			var mastery_xp:=Pl51To60ProgressionCatalog.mastery_xp(level,admiral,elite) if level>=51 else (Pl46To50ProgressionCatalog.mastery_xp(level,admiral,elite) if level>=46 else (Pl41To45ProgressionCatalog.mastery_xp(level,admiral,elite) if level>=41 else (Pl36To40ProgressionCatalog.mastery_xp(level,admiral,elite) if level>=36 else (Pl6To10ProgressionCatalog.mastery_xp(level,admiral,elite) if level<=10 else (Pl11To15ProgressionCatalog.mastery_xp(level,admiral,elite) if level<=15 else (Pl16To20ProgressionCatalog.mastery_xp(level,admiral,elite) if level<=20 else (Pl21To25ProgressionCatalog.mastery_xp(level,admiral,elite) if level<=25 else (Pl26To30ProgressionCatalog.mastery_xp(level,admiral,elite) if level<=30 else Pl31To35ProgressionCatalog.mastery_xp(level,admiral,elite)))))))))
			roster.earn_ship_xp(mastery_xp)
			if post!=null:
				post.add_map_xp(level,int(profile.xp))
				if admiral:post.record_boss_clear(level)
				elif level>=11:post.record_region_objective(level)
				if level>=36 and elite:post.record_void_elite(level)
				if level>=41 and (elite or admiral):post.record_sovereign_prestige(level,2 if admiral else 1)
				if level>=41 and trial_runtime!=null and (elite or admiral):trial_runtime.record("prestige",2 if admiral else 1)
				if level>=46 and level<=50:
					if elite or admiral:
						post.record_legendary_chain(level,2 if admiral else 1)
						if trial_runtime!=null:trial_runtime.record("legendary_chain",2 if admiral else 1)
					if elite or admiral:post.record_top_material(level,2 if admiral else 1)
					if trial_runtime!=null and admiral and bool(ship.get_meta("encounter_kind","")=="monster"):trial_runtime.record("guardian_sink")
				if level>=51 and level<=60 and (elite or admiral):
					var chain_amount:=2 if admiral else 1
					post.record_w5_elite_chain(level,chain_amount)
					if trial_runtime!=null:trial_runtime.record("w5_elite_chain",chain_amount)
				if bool(ship.get_meta("hunter_objective_target",false)) or bool(ship.get_meta("encounter_kind","")=="monster"):post.record_hunter(level)
				if level>=21:
					var weapons:=attacker.get_node_or_null("Weapons") as ShipWeapons
					if weapons!=null and weapons.ammo_index>=3:post.record_status_objective(level)
					if roster.ship_level()>=3:post.record_build_objective(level)
				if level>=26:
					var corruption:=attacker.get_node_or_null("AbyssCorruption") as AbyssCorruption
					if corruption!=null and corruption.retained and corruption.value>=25.0:post.record_corruption_objective(level)
				if level>=31:
					var ancient_amount:=2 if admiral else (1 if bool(ship.get_meta("hunter_objective_target",false)) else 0)
					if ancient_amount>0:post.record_guardian_fragment(level,ancient_amount)
		var reward_mult:=clampf(float(attacker.get_meta("corruption_reward_mult",1.0)),1.0,1.25) if level>=26 else 1.0
		_drop_loot.call_deferred(ship.position, roundi(int(profile.coins)*reward_mult), str(ship.get_meta("rarity", "common")), admiral, content)
		var reward_hud := get_tree().get_first_node_in_group("hud") as GameHud
		if reward_hud != null:
			reward_hud.note_prioritized("ZIEL VERSENKT · +%d EXP · BEUTE IM WASSER" % int(profile.xp), 6, "reward", 4400)
		if world != null:
			var region:Dictionary = world.current_region_contract()
			if not region.is_empty():
				var inventory:=attacker.get_node("Inventory") as PlayerInventory
				inventory.grant_regional_salvage(str(region.get("id","")),admiral)
				if level>=12:
					inventory.grant_silver_bonusmap_fragment(level,bool(ship.get_meta("rarity","common")=="elite"),admiral)
				if level>=18:
					inventory.grant_gold_bonusmap_fragment(level,bool(ship.get_meta("rarity","common")=="elite"),admiral)
				if level>=26:
					inventory.grant_abyss_progression_drop(level,bool(ship.get_meta("rarity","common")=="elite"),admiral)
				if level>=31:
					inventory.grant_ancient_guardian_drop(level,admiral)
				if level>=46:
					var dominion_drop:=inventory.grant_dominion_drop(level,bool(ship.get_meta("rarity","common")=="elite"),admiral)
					if level>=51 and level<=60 and (admiral or bool(ship.get_meta("rarity","common")=="elite")):
						var profile_drop: Dictionary = M157EncounterProfileCatalog.drop_profile(level).get("admiral" if admiral else "elite", {}) as Dictionary
						for item_id in profile_drop.keys():inventory.set_count(str(item_id),inventory.count(str(item_id))+int(profile_drop[item_id]))
					var shard_amount:=int(dominion_drop.get("dominion_shard",0))
					if shard_amount>0 and post!=null:
						if level<=50:post.record_top_material(level,shard_amount)
						else:post.record_dominion_shards(level,shard_amount)
						if level>=51 and trial_runtime!=null:trial_runtime.record("dominion_shards",shard_amount)
					var corruption:=attacker.get_node_or_null("AbyssCorruption") as AbyssCorruption
					if corruption!=null:
						var corruption_kind:="admiral_sink" if admiral else ("elite_sink" if bool(ship.get_meta("rarity","common")=="elite") else "normal_sink")
						corruption.gain(corruption_kind,level)
			if admiral and level >= BeginnerRules.ELITE_MAP_LEVEL:
				var voyage := attacker.get_node_or_null("Voyage") as VoyageProgress
				var may_advance:=true
				if level>=6 and level<=60:
					may_advance=post!=null and post.level_complete(level)
					if level==10 and post!=null and post.trial_ready(10):
						notice="PIRATENPRÜFUNG 10 BEREIT · IM HAFEN ABSCHLIESSEN"
						notice_time=5.0
					elif level==15 and post!=null and post.trial_ready(15):
						notice="PIRATENPRÜFUNG 15 BEREIT · SHIELD / DECK / MODULE / SUPPORT"
						notice_time=5.0
					elif level==20 and post!=null and post.trial_ready(20):
						notice="PIRATENPRÜFUNG 20 BEREIT · ADMIRAL / GOLD-CONTENT"
						notice_time=5.0
					elif level==25 and post!=null and post.trial_ready(25):
						notice="PIRATENPRÜFUNG 25 BEREIT · STATUS / BUILD-SPEZIALISIERUNG"
						notice_time=5.0
					elif level==30 and post!=null and post.trial_ready(30):
						notice="PIRATENPRÜFUNG 30 BEREIT · ABYSS / HUNTER / CORRUPTION"
						notice_time=5.0
					elif level==35 and post!=null and post.trial_ready(35):
						notice="PIRATENPRÜFUNG 35 BEREIT · WORLD BOSS PREPARATION"
						notice_time=5.0
					elif level==50 and post!=null and post.trial_ready(50):
						notice="PIRATENPRÜFUNG 50 BEREIT · DREADWATER-ZUGANG"
						notice_time=5.0
					elif level==55 and post!=null and post.trial_ready(55):
						notice="PIRATENPRÜFUNG 55 BEREIT · W5 VANGUARD"
						notice_time=5.0
					elif level==60 and post!=null and post.trial_ready(60):
						notice="PIRATENPRÜFUNG 60 BEREIT · IRON MAW FINALE"
						notice_time=5.0
				if voyage != null and may_advance:
					var awarded_design:String = voyage.record_post_beginner_boss(level)
					if not awarded_design.is_empty():
						var reward_profile := ShipCatalog.profile_by_id(awarded_design)
						notice = "DESIGN ERSPIELT · %s" % str(reward_profile.display_name).to_upper()
						notice_time = 5.0
	encounter_changed.emit()


func _drop_loot(position: Vector3, coins: int, rarity: String, admiral: bool, owner_root: Node3D) -> void:
	if not is_instance_valid(owner_root) or owner_root != content or not owner_root.is_inside_tree():
		return
	var tier := _roll_loot_tier(rarity, admiral)
	var loot_profile := catalog.loot_profile(tier)
	var loot := LootPickup.new()
	loot.loot_type = "admiral_chest" if admiral else "salvage_chest"
	loot.loot_tier = tier
	loot.display_label = str(loot_profile.get("label", "SALVAGE"))
	loot.amount = roundi(coins * float(loot_profile.get("multiplier", 1.0)))
	loot.position = Vector3(position.x, 0.65, position.z)
	loot.base_y = 0.65
	loot.set_meta("m218_pickup_priority", 3 if admiral else 2)
	loot.set_meta("m218_loot_cluster", "boss_salvage" if admiral else "salvage")
	owner_root.add_child(loot)
	# M216: make the drop moment readable at master-reference zoom; rewards remain unchanged.
	M216ShipCombatFxScript.loot_drop_read(loot.global_position, admiral, get_tree())
	if admiral:
		var repair := LootPickup.new()
		repair.loot_type = "repair"
		repair.loot_tier = "uncommon"
		repair.display_label = "BOSS REPAIR CACHE"
		repair.amount = 300
		repair.position = loot.position + Vector3(2.6, 0.0, 0.0)
		repair.base_y = 0.65
		repair.set_meta("m218_pickup_priority", 4)
		repair.set_meta("m218_loot_cluster", "boss_repair")
		owner_root.add_child(repair)


func _roll_loot_tier(rarity: String, admiral: bool) -> String:
	if admiral:
		return "legendary"
	var roll := rng.randf()
	if rarity == "elite":
		return "epic" if roll < 0.24 else "rare"
	if roll < 0.08:
		return "rare"
	if roll < 0.30:
		return "uncommon"
	return "common"


func _find_spawn_position(kind:String="patrol",slot:int=0) -> Vector3:
	# M197: authored regional combat lanes on the same canonical chart for every platform.
	var extent: float = world.sector_spawn_extent() if world != null else 155.0
	var zone_center:=RegionalEncounterZoneCatalog.anchor(encounter_region_id,kind,maxi(slot,0),extent)
	var zone_radius:=RegionalEncounterZoneCatalog.zone_radius(encounter_region_id)
	var lane:=RegionalEncounterZoneCatalog.safe_lane(encounter_region_id,extent)
	var lane_radius:=RegionalEncounterZoneCatalog.safe_lane_radius(encounter_region_id)
	for attempt in range(72):
		var angle:=rng.randf_range(0.0,TAU)
		var radius:=sqrt(rng.randf())*zone_radius
		var candidate:=zone_center+Vector3(cos(angle)*radius,0.0,sin(angle)*radius)
		candidate.x=clampf(candidate.x,-extent,extent);candidate.z=clampf(candidate.z,-extent,extent)
		if kind!="admiral" and _inside_safe_lane(candidate,lane,lane_radius):continue
		if _is_clear(candidate):return candidate
	# Deterministic chart-wide fallback: never fail solely because a regional zone is crowded.
	for attempt in range(48):
		var candidate:=Vector3(rng.randf_range(-extent,extent),0.55,rng.randf_range(-extent,extent))
		if kind!="admiral" and _inside_safe_lane(candidate,lane,lane_radius):continue
		if _is_clear(candidate):return candidate
	return Vector3(INF,INF,INF)

func _inside_safe_lane(candidate:Vector3,lane:Array[Vector3],radius:float)->bool:
	if lane.size()<2:return false
	var p:=Vector2(candidate.x,candidate.z)
	var a:=Vector2(lane[0].x,lane[0].z);var b:=Vector2(lane[1].x,lane[1].z)
	var ab:=b-a
	var denom:=maxf(ab.length_squared(),0.001)
	var t:=clampf((p-a).dot(ab)/denom,0.0,1.0)
	return p.distance_to(a+ab*t)<radius

func _is_clear(candidate: Vector3) -> bool:
	if is_instance_valid(player) and _flat_distance(candidate, player.position) < 12.0:
		return false
	for node in content.get_children():
		if node.is_in_group("islands"):
			if _flat_distance(candidate, node.position) < float(node.get_meta("island_radius", 7.0)) + 4.5:
				return false
		elif node.is_in_group("ports"):
			if _flat_distance(candidate, node.position + Vector3(0.0, 0.0, 5.0)) < 15.0:
				return false
		elif node.is_in_group("ships") and _flat_distance(candidate, node.position) < 9.0:
			return false
	return true


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
