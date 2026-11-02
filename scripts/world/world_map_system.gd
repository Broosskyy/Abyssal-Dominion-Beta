class_name WorldMapSystem
extends Node3D

signal sector_changed(previous: Vector2i, current: Vector2i, direction: Vector2i)

const Factory = preload("res://scripts/core/procedural_factory.gd")
const PortFactoryScript = preload("res://scripts/world/port_factory.gd")
const SECTOR_SIZE := 360.0 # M192: full gameplay sea, ~55s straight crossing at base cruise speed; not a tiny prototype tile.
# M138: physical runtime is stable-ID/registry first. No rectangular GRID_SIZE/SECTORS source-of-truth remains.
var sector_data:Dictionary={} # compatibility coordinate mirror generated from WorldSectorRegistry only.
var player:ShipMotor
var current_sector:Vector2i=Vector2i.ZERO # legacy save/test mirror only
var current_sector_id:String="SECTOR-001"
var encounters:EncounterDirector
var bonusmap_router:BonusMapInstanceRouter
var sector_content:Node3D
var transition_cooldown:float=0.0
var transition_message_time:float=0.0
var transition_message:String=""
var consumed_poi_ids:Dictionary={} # local prototype persistence; live authority belongs to server quest/content state.


func _ready() -> void:
	add_to_group("world_map")
	var registry_data:=WorldSectorRegistry.legacy_dictionary()
	if not registry_data.is_empty():sector_data=registry_data
	current_sector_id=WorldSectorRegistry.id_for_coord(current_sector)
	encounters = EncounterDirector.new()
	encounters.name = "EncounterDirector"
	add_child(encounters)
	bonusmap_router=BonusMapInstanceRouter.new()
	bonusmap_router.name="BonusMapInstanceRouter"
	add_child(bonusmap_router)
	call_deferred("_setup_bonusmap_router")
	call_deferred("_build_sector")


func _setup_bonusmap_router()->void:
	if bonusmap_router!=null and player!=null:bonusmap_router.setup(self,player)

func enter_bonusmap_instance(kind:String)->bool:
	if bonusmap_router==null:return false
	return bonusmap_router.enter(kind)

func exit_bonusmap_instance()->void:
	if bonusmap_router!=null:bonusmap_router.exit()

func _process(delta: float) -> void:
	transition_cooldown = max(0.0, transition_cooldown - delta)
	transition_message_time = max(0.0, transition_message_time - delta)
	if player == null or transition_cooldown > 0.0:
		return
	_check_boundaries()


func current_stable_sector_id()->String:
	if current_sector_id.is_empty():current_sector_id=WorldSectorRegistry.id_for_coord(current_sector)
	return current_sector_id
func current_runtime_data()->Dictionary:
	var data:=WorldSectorRegistry.runtime_data(current_stable_sector_id())
	if data.is_empty() and sector_data.has(current_sector):data=(sector_data[current_sector] as Dictionary).duplicate(true)
	return data

func _runtime_seed()->int:
	var id:=current_stable_sector_id()
	var services:=ServiceLocator.from(get_tree())
	var content_version:=services.content.effective_version() if services!=null and services.content!=null else "local"
	return StableContentSeed.from_parts([id,content_version,"world"])

func poi_consumed(instance_id:String)->bool:
	return bool(consumed_poi_ids.get(instance_id,false))

func mark_poi_consumed(instance_id:String)->void:
	if instance_id.is_empty():return
	consumed_poi_ids[instance_id]=true

func export_poi_state()->Dictionary:
	return {"consumed_ids":consumed_poi_ids.keys()}

func import_poi_state(v:Dictionary)->void:
	consumed_poi_ids.clear()
	for id in v.get("consumed_ids",[]):
		if not str(id).is_empty():consumed_poi_ids[str(id)]=true

func current_map_name() -> String:
	var row:=WorldSectorRegistry.by_id(current_stable_sector_id())
	return str(row.get("display_name",current_runtime_data().get("name","Unknown Sea"))) if not row.is_empty() else str(current_runtime_data().get("name","Unknown Sea"))
func current_map_level() -> int:
	var row:=WorldSectorRegistry.by_id(current_stable_sector_id())
	return int(row.get("pirate_level",current_runtime_data().get("level",1))) if not row.is_empty() else int(current_runtime_data().get("level",1))

func current_progression_contract()->Dictionary:
	var level:=current_map_level()
	if level>=6 and level<=10:return Pl6To10ProgressionCatalog.level(level)
	if level>=11 and level<=15:return Pl11To15ProgressionCatalog.level(level)
	if level>=16 and level<=20:return Pl16To20ProgressionCatalog.level(level)
	if level>=21 and level<=25:return Pl21To25ProgressionCatalog.level(level)
	if level>=26 and level<=30:return Pl26To30ProgressionCatalog.level(level)
	if level>=31 and level<=35:return Pl31To35ProgressionCatalog.level(level)
	if level>=36 and level<=40:return Pl36To40ProgressionCatalog.level(level)
	if level>=41 and level<=45:return Pl41To45ProgressionCatalog.level(level)
	if level>=46 and level<=50:return Pl46To50ProgressionCatalog.level(level)
	if level>=51 and level<=60:return Pl51To60ProgressionCatalog.level(level)
	return {}

func current_region_contract()->Dictionary:
	var base:=WorldRegionRegistry.for_level(current_map_level())
	if base.is_empty():return {}
	return WorldRegionRegistry.effective(get_tree(),str(base.get("id","")))


func _apply_region_metadata(node: Node, slot_id: String, family: String) -> void:
	if node == null or slot_id.is_empty():
		return
	node.set_meta("production_slot", slot_id)
	node.set_meta("asset_family", family)
	node.set_meta("placeholder_replacement_ready", true)


func local_coordinates() -> Vector2:
	return Vector2(player.position.x, player.position.z) if player != null else Vector2.ZERO

func display_coordinates() -> Vector2:
	# M192 player-facing chart coordinates: positive X/Y from the north-west chart corner.
	# Godot remains X/Z internally; raw negative engine coordinates never leak into the HUD.
	if player == null:return Vector2.ZERO
	var half:=sector_half_size()
	return Vector2(clampf(player.position.x+half,0.0,SECTOR_SIZE),clampf(player.position.z+half,0.0,SECTOR_SIZE))

func sector_spawn_extent() -> float:
	# Keeps authored world content away from transfer edges while using the full-sized chart.
	return sector_half_size()-25.0


func sector_half_size() -> float:
	return SECTOR_SIZE * 0.5


func restore_sector(coordinate:Vector2i)->void:
	var id:=WorldSectorRegistry.id_for_coord(coordinate)
	if id.is_empty():return
	current_sector=coordinate;current_sector_id=id;_build_sector()
func restore_sector_id(sector_id:String)->bool:
	if WorldSectorRegistry.by_id(sector_id).is_empty():return false
	current_sector_id=sector_id
	var coordinate:=WorldSectorRegistry.coord_for_id(sector_id)
	if coordinate.x>-100:current_sector=coordinate
	_build_sector();return true


func _check_boundaries() -> void:
	if (player.get_node("Health") as ShipHealth).is_sunk:
		return
	var half := sector_half_size()
	var direction := Vector2i.ZERO
	if player.position.x > half:
		direction = Vector2i.RIGHT
	elif player.position.x < -half:
		direction = Vector2i.LEFT
	elif player.position.z > half:
		direction = Vector2i.DOWN
	elif player.position.z < -half:
		direction = Vector2i.UP
	if direction != Vector2i.ZERO:
		_transition(direction)


func _transition(direction: Vector2i) -> void:
	var next_id:=WorldSectorRegistry.neighbor_id(current_stable_sector_id(),direction)
	var next_sector:=WorldSectorRegistry.coord_for_id(next_id) if not next_id.is_empty() else Vector2i(-999,-999)
	var next_data:=WorldSectorRegistry.runtime_data(next_id)
	var voyage:=player.get_node_or_null("Voyage") as VoyageProgress
	if not next_data.is_empty() and voyage!=null and int(next_data.get("level",1))>voyage.map_level()+1:
		player.position.x = clampf(player.position.x, -sector_half_size() + 1, sector_half_size() - 1)
		player.position.z = clampf(player.position.z, -sector_half_size() + 1, sector_half_size() - 1)
		(player.get_node("PlayerInput") as PlayerShipInput).cancel_navigation()
		player.stop_ship()
		transition_message = "KARTENLEVEL %d GESPERRT · Anfängeraufträge im Fortschrittsmenü" % int(next_data.get("level",1))
		transition_message_time = 3.0
		return
	if next_id.is_empty() or next_data.is_empty():
		player.position.x = clamp(player.position.x, -sector_half_size(), sector_half_size())
		player.position.z = clamp(player.position.z, -sector_half_size(), sector_half_size())
		player.stop_ship()
		transition_message = "WORLD EDGE"
		transition_message_time = 1.2
		return
	var previous := current_sector
	current_sector_id=next_id
	# Legacy coordinate remains a compatibility mirror only.
	if next_sector.x>-100:current_sector=next_sector
	var half := sector_half_size()
	if direction.x != 0:
		player.position.x = -sign(direction.x) * (half - 2.5)
	else:
		player.position.z = -sign(direction.y) * (half - 2.5)
	transition_cooldown = 0.8
	transition_message = current_map_name()
	transition_message_time = 2.2
	_build_sector()
	sector_changed.emit(previous, current_sector, direction)


func _build_sector() -> void:
	var feedback := GameScope.owner_of(self).get_node_or_null("CombatFeedback") as CombatFeedback
	if feedback != null:
		feedback.clear()
	(player.get_node("Targeting") as TargetingSystem).set_target(null)
	(player.get_node("PlayerInput") as PlayerShipInput).cancel_navigation()
	(player.get_node("Progression") as PlayerProgression).shop_open = false
	player.set_meta("in_safe_zone", false)
	for key in ["nearby_port", "nearby_port_name", "safe_zone_name"]:
		if player.has_meta(key):
			player.remove_meta(key)
	for projectile in get_tree().get_nodes_in_group("sector_projectiles"):
		projectile.set_physics_process(false)
		projectile.queue_free()
	if sector_content != null and is_instance_valid(sector_content):
		remove_child(sector_content)
		sector_content.queue_free()
	sector_content = Node3D.new()
	sector_content.name="SectorContent_"+current_stable_sector_id().replace("-","_")
	add_child(sector_content)
	var data:Dictionary=current_runtime_data()
	var region := current_region_contract()
	if not region.is_empty():
		data = data.duplicate(true)
		data["region_id"] = str(region.get("id", ""))
		data["production_biome"] = str(region.get("biome", data.get("biome", "")))
		data["canonical_region_name"]=str(region.get("display_name",""))
		data["canonical_harbor"]=str(region.get("canonical_harbor",""))
	var regional_environment := get_tree().get_first_node_in_group("p1_regional_environment_controller") as P1RegionalEnvironmentController
	if regional_environment != null: regional_environment.apply_region(str(data.get("region_id", "")))
	var rng := RandomNumberGenerator.new()
	rng.seed=_runtime_seed()
	var extent:=sector_spawn_extent()
	var port_position := Vector3(-extent*0.78, 0.2, extent*0.68)
	_build_island_composition(sector_content, data, rng, port_position if not data.port.is_empty() else Vector3(INF, INF, INF))
	if int(data.level)<=BeginnerRules.LAST_BEGINNER_LEVEL or (int(data.level)>=16 and int(data.level)<=60):
		var poi_forbidden:Array[Vector3]=[]
		if not data.port.is_empty():poi_forbidden.append(port_position)
		WorldPoiComposer.populate(sector_content,int(data.level),_runtime_seed()+720,poi_forbidden,current_stable_sector_id(),str(data.get("region_id","")))
	if not data.port.is_empty():
		var harbor_slot:String=WorldVisualContentResolver.dynamic_harbor_slot(get_tree(),current_stable_sector_id(),region) if not region.is_empty() else ""
		var port:=PortFactoryScript.create_port(data.port,port_position,harbor_slot)
		if not region.is_empty():
			_apply_region_metadata(port,harbor_slot,"harbor")
			P1RegionalPresentationAdapter.apply_harbor(port,str(region.get("id","")))
		sector_content.add_child(port)
	_spawn_support_ally(sector_content, int(data.level), port_position if not data.port.is_empty() else Vector3(INF, INF, INF))
	_spawn_early_guild_island(sector_content,int(data.level),port_position if not data.port.is_empty() else Vector3(INF,INF,INF))
	var event_runtime:=get_tree().get_first_node_in_group("event_runtime") as EventRuntime
	HalloweenEventWorld.apply(sector_content,event_runtime,int(data.level))
	encounters.configure(self, sector_content, current_sector, data, player)
	if player != null and current_map_level() >= BeginnerRules.ELITE_MAP_LEVEL:
		(player.get_node("ShipRoster") as PlayerShipRoster).unlock_main_progression_for_map_level(current_map_level())




func _spawn_early_guild_island(root:Node3D,level:int,port_position:Vector3)->void:
	if not GuildIslandComposer.should_spawn(level):return
	# M89 local visual/interaction preview. Never implies live guild ownership.
	var extent:=sector_spawn_extent()
	var pos:=Vector3(extent*0.76,0.18,-extent*0.64)
	if port_position.is_finite() and Vector2(pos.x-port_position.x,pos.z-port_position.z).length()<14.0:
		pos=Vector3(extent*0.72,0.18,-extent*0.70)
	var island:=GuildIslandComposer.create(pos,level)
	root.add_child(island)

func _spawn_support_ally(root: Node3D, level: int, port_position: Vector3) -> void:
	if level < BeginnerRules.ELITE_MAP_LEVEL:
		return
	var extent:=sector_spawn_extent()
	var pos := Vector3(extent*0.60, 0.55, extent*0.48)
	if port_position.is_finite():
		pos = port_position + Vector3(13.0, 0.35, -7.0)
	var ally := Factory.create_ship("HARBOR ESCORT", pos, Color("356b78"), false) as ShipMotor
	ally.remove_from_group("enemies")
	ally.add_to_group("support_allies")
	ally.add_to_group("friendly_ships")
	ally.set_meta("encounter_kind", "support_ally")
	ally.set_meta("production_slot", "npc_support_escort")
	ally.set_meta("placeholder_replacement_ready", true)
	var health := ShipHealth.new()
	health.name = "Health"
	health.max_health = 900.0 + level * 35.0
	health.max_shield = 120.0
	health.auto_respawn = false
	ally.add_child(health)
	root.add_child(ally)
	# Intentional visible damage makes the Support Ammo path testable immediately.
	health.current_health = health.max_health * 0.64
	health.current_shield = health.max_shield * 0.35

func _build_island_composition(root: Node3D, data: Dictionary, rng: RandomNumberGenerator, port_position: Vector3) -> void:
	# M196 regional macro composition: the same eight gameplay islands exist on every platform,
	# while each named region gets its own route silhouette and spatial rhythm.
	var profiles: Array[Dictionary] = [
		{"radius": 7.0, "aspect": Vector2(1.20, 0.82), "density": 0.78, "reference": true},
		{"radius": 5.2, "aspect": Vector2(1.48, 0.68), "density": 0.68, "reference": false},
		{"radius": 4.4, "aspect": Vector2(0.82, 1.18), "density": 0.62, "reference": false},
		{"radius": 3.1, "aspect": Vector2(1.70, 0.58), "density": 0.44, "reference": false},
		{"radius": 2.5, "aspect": Vector2(0.86, 1.10), "density": 0.36, "reference": false},
		# M193/M196: navigation punctuation fills the large chart without turning it into clutter.
		{"radius": 2.2, "aspect": Vector2(1.32, 0.70), "density": 0.30, "reference": false},
		{"radius": 1.9, "aspect": Vector2(0.72, 1.38), "density": 0.24, "reference": false},
		{"radius": 1.8, "aspect": Vector2(1.85, 0.52), "density": 0.22, "reference": false},
	]
	var max_islands:=mini(profiles.size(),VisualQualityResolver.island_budget())
	profiles=profiles.slice(0,max_islands)
	var occupied:Array[Dictionary]=[]
	for index in profiles.size():
		var profile: Dictionary = profiles[index]
		var radius := float(profile.radius) * rng.randf_range(0.90, 1.08)
		var aspect: Vector2 = profile.aspect
		aspect.x *= rng.randf_range(0.94, 1.06)
		aspect.y *= rng.randf_range(0.94, 1.06)
		var clearance := radius * maxf(aspect.x, aspect.y) + 2.2
		var preferred:=ChartCompositionCatalog.island_anchor(index,_runtime_seed(),sector_spawn_extent(),str(data.get("region_id","")))
		var position := _find_island_position(rng, occupied, clearance, port_position, preferred)
		if not position.is_finite():
			continue
		occupied.append({"position": position, "clearance": clearance})
		var composition_ids:Array=WorldVisualContentResolver.island_slots(get_tree(),current_stable_sector_id(),current_region_contract(),["tropical_medium","long_shoal","tropical_small","thin_spit","rocky_islet","cliff_cove"])
		var composition_id:=""
		if str(data.biome)=="tropical" and int(data.level)<=BeginnerRules.LAST_BEGINNER_LEVEL:
			composition_id=composition_ids[index%composition_ids.size()]
		elif str(data.biome) in ["cursed","dominion"]:
			var cursed_shapes:=["cliff_cove","thin_spit","long_shoal","rocky_islet"]
			composition_id=cursed_shapes[(index+int(data.level))%cursed_shapes.size()]
		var island:=Factory.create_island(
			position,radius,str(data.biome),bool(profile.reference),aspect,
			rng.randf_range(-55.0,55.0),float(profile.density),composition_id,
		)
		island.set_meta("canonical_region_id",str(data.get("region_id","")))
		var visual_slot:=str(composition_ids[index%composition_ids.size()]) if not composition_ids.is_empty() else ""
		var silhouette_slot:=visual_slot if visual_slot.begins_with("ISLAND-BASE-") else ProceduralIslandSilhouetteAdapter.slot_for_index(abs(_runtime_seed()+index))
		ProceduralIslandSilhouetteAdapter.apply(island,silhouette_slot)
		var quality:="balanced"
		var settings:=ClientSettings.current(get_tree())
		if settings!=null:
			quality=str(settings.values.get("graphics_quality","balanced")).to_lower()
		WorldDressingComposer.decorate_island(island,str(data.biome),_runtime_seed()+index*73+730,quality)
		var region := current_region_contract()
		if not region.is_empty():
			var island_slots: Array = region.get("island_slots", [])
			if not island_slots.is_empty():
				island.set_meta("canonical_island_slot",str(island_slots[index % island_slots.size()]))
			_apply_region_metadata(island,visual_slot if not visual_slot.is_empty() else str(island.get_meta("canonical_island_slot","")),"island")
		root.add_child(island)
		P1RegionalPresentationAdapter.apply_world_asset(island,str(data.get("region_id","")),"world")


func _find_island_position(rng: RandomNumberGenerator, occupied: Array[Dictionary], clearance: float, port_position: Vector3, preferred:Vector3=Vector3(INF,INF,INF)) -> Vector3:
	# M196: try the deterministic region-aware macro anchor first. Each named region receives
	# recognizable lanes while seeded variation keeps individual charts from looking cloned.
	for attempt in 36:
		var extent:=sector_spawn_extent()
		var band:=0.58 if attempt%3==0 else 0.94
		var candidate := preferred if attempt==0 and preferred.is_finite() else Vector3(rng.randf_range(-extent*band, extent*band), 0.2, rng.randf_range(-extent*band, extent*band))
		if Vector2(candidate.x, candidate.z).length() < 24.0 + clearance * 0.35:
			continue
		if port_position.is_finite() and Vector2(candidate.x - port_position.x, candidate.z - port_position.z).length() < 16.0 + clearance * 0.55:
			continue
		var blocked := false
		for entry in occupied:
			var other: Vector3 = entry.position
			var needed := clearance + float(entry.clearance)
			if Vector2(candidate.x - other.x, candidate.z - other.z).length() < needed:
				blocked = true
				break
		if not blocked:
			return candidate
	return Vector3(INF, INF, INF)
