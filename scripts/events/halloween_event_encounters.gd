class_name HalloweenEventEncounters
extends RefCounted
## Local seasonal combat wrappers. Uses canonical ShipHealth/ShipWeapons/EnemyShipAI contracts.

const DEFINITIONS:={
	"event_halloween_npc_sloop_01":{"title":"Drowned Deckhand","kind":"ship","archetype":"scout","hull":520.0,"damage":30.0,"speed":8.4,"range":23.0,"armor":0.05,"rank":"event"},
	"event_halloween_npc_raider_01":{"title":"Gravewake Raider","kind":"ship","archetype":"raider","hull":760.0,"damage":43.0,"speed":7.4,"range":22.0,"armor":0.10,"rank":"event"},
	"event_halloween_admiral_01":{"title":"Admiral Hollow-Eye","kind":"admiral","archetype":"tank","hull":2300.0,"damage":62.0,"speed":6.0,"range":25.0,"armor":0.18,"rank":"boss"},
	"event_halloween_monster_01":{"title":"Lantern Maw","kind":"monster","archetype":"leviathan","hull":1800.0,"damage":55.0,"speed":6.2,"range":19.0,"armor":0.14,"rank":"elite"},
	"event_halloween_boss_01":{"title":"The Drowned Sovereign","kind":"monster","archetype":"leviathan","hull":3900.0,"damage":76.0,"speed":5.8,"range":21.0,"armor":0.22,"rank":"boss"}
}

static func spawn(root:Node3D,slot:String,pos:Vector3,runtime:EventRuntime)->ShipMotor:
	var d:Dictionary=DEFINITIONS.get(slot,{})
	if root==null or d.is_empty():return null
	var monster:=str(d.kind)=="monster"
	var ship:=ProceduralFactory.create_ship(str(d.title),pos,Color("254f59") if monster else Color("53643c"),false) as ShipMotor
	ship.set_meta("event_participant",true);ship.set_meta("event_id","halloween_abyss_01");ship.set_meta("production_slot",slot)
	ship.set_meta("placeholder_replacement_ready",true);ship.set_meta("encounter_kind",str(d.kind));ship.set_meta("rarity",str(d.rank))
	ship.set_meta("encounter_rank",str(d.rank));ship.set_meta("passive_until_attacked",false);ship.set_meta("provoked",true)
	ship.set_meta("event_balance_local",true)
	ship.set_meta("event_combat_authority","LOCAL_PREVIEW_ONLY")
	ship.set_meta("event_npc_combat_identity","HALLOWEEN_DROWNED_FLEET")
	if slot=="event_halloween_boss_01":
		ship.add_to_group("world_poi_markers")
		ship.set_meta("poi_kind","event_boss");ship.set_meta("poi_label","DROWNED SOVEREIGN")
		ship.set_meta("marker_slot","m95_event_target");ship.set_meta("marker_priority",96)
	var world:=root.get_tree().get_first_node_in_group("world_map") as WorldMapSystem
	var map_level:=world.current_map_level() if world!=null else 2
	var early_scale:=clampf(0.76+0.08*float(maxi(0,map_level-2)),0.76,1.08)
	var health:=ShipHealth.new();health.name="Health";health.max_health=float(d.hull)*early_scale;health.armor=float(d.armor);health.auto_respawn=false;ship.add_child(health)
	var weapons:=ShipWeapons.new();weapons.name="Weapons";weapons.damage=float(d.damage)*early_scale;ship.add_child(weapons)
	var ai:=EnemyShipAI.new();ai.name="EnemyAI";ai.archetype=str(d.archetype);ai.desired_range=float(d.range);ai.leash_range=50.0 if str(d.rank)=="boss" else 42.0;ship.add_child(ai)
	ship.cruise_speed=float(d.speed)
	root.add_child(ship)
	_add_event_identity(ship,str(d.rank))
	var replacement_visual:=AssetVisualLibrary.install(ship,slot)
	if replacement_visual!=null:
		for child in ship.get_children():
			if child is MeshInstance3D and child!=replacement_visual:
				(child as MeshInstance3D).hide()
	if monster:
		ship.add_to_group("monsters")
		if replacement_visual==null:ProceduralFactory.apply_sea_monster_visual(ship,Color("315f52"))
	MobileLodController.apply_ship(ship,root.get_tree())
	health.ship_sunk.connect(_sunk.bind(runtime))
	health.damage_applied.connect(_hit.bind(runtime))
	return ship

static func _add_event_identity(ship:ShipMotor,rank:String)->void:
	# External light cue, never a modular hull piece or combat target collider.
	var cue:=Node3D.new()
	cue.name="M301DrownedFleetIdentity"
	cue.position=Vector3(0,2.45,0)
	cue.set_meta("production_slot","event_halloween_fleet_identity_01")
	cue.set_meta("presentation_only",true)
	ship.add_child(cue)
	if AssetVisualLibrary.install(cue,"event_halloween_fleet_identity_01")!=null:return
	var lamp:=MeshInstance3D.new()
	lamp.mesh=FallbackPrimitiveLibrary.sphere(0.23 if rank!="boss" else 0.39,0.40)
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("e58c35")
	mat.emission_enabled=true;mat.emission=Color("c86c1e");mat.emission_energy_multiplier=0.9
	lamp.material_override=mat;lamp.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cue.add_child(lamp)

static func _sunk(ship:ShipMotor,attacker:Node3D,runtime:EventRuntime)->void:
	if runtime!=null and is_instance_valid(attacker) and attacker.is_in_group("player"):
		runtime.record_event_sink(ship)
		runtime.admin_add_score(8 if str(ship.get_meta("rarity",""))=="boss" else 3)
		var inv:=attacker.get_node_or_null("Inventory") as PlayerInventory
		if inv!=null:
			inv.set_count("gravefire",inv.count("gravefire")+(24 if str(ship.get_meta("rarity",""))=="boss" else 8))
	CombatVfx.action(ship.get_tree(),"monster_arrival" if ship.is_in_group("monsters") else "admiral_arrival",ship.global_position)

static func _hit(target:Node3D,attacker:Node3D,_actual:float,_slowed:bool,_critical:bool,runtime:EventRuntime)->void:
	if runtime==null or not is_instance_valid(attacker) or not attacker.is_in_group("player"):return
	var weapons:=attacker.get_node_or_null("Weapons") as ShipWeapons
	if weapons!=null and weapons.weapon_mode=="harpoon":runtime.record_event_monster_hit(target)
