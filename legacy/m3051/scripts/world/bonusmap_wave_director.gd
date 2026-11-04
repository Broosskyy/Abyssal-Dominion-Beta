class_name BonusMapWaveDirector
extends Node
signal wave_spawned(wave:int,kind:String,count:int)
signal wave_cleared(wave:int)
const Factory=preload("res://scripts/core/procedural_factory.gd")
const PATH:="res://data/m118_bonusmap_waves.json"
var kind:=""
var root:Node3D
var player:ShipMotor
var active_wave:=0
var living:Array[ShipMotor]=[]
var base_level:=18
var player_sank_during_run:=false
func setup(instance_kind:String,owner_root:Node3D,captain:ShipMotor)->void:
	kind=instance_kind;root=owner_root;player=captain;base_level=36 if kind=="legendary" else (26 if kind=="abyss" else (12 if kind=="silver" else 18))
	var player_health:=player.get_node_or_null("Health") as ShipHealth
	if player_health!=null and not player_health.ship_sunk.is_connected(_on_player_sunk):player_health.ship_sunk.connect(_on_player_sunk)
	var dynamic:=DynamicContentResolver.by_id(get_tree(),"encounter",kind)
	if not dynamic.is_empty():base_level=int(dynamic.get("base_level",base_level))
func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));return v if v is Dictionary else {}
func wave_def(w:int)->Dictionary:
	var tree:=get_tree()
	var dynamic:=DynamicContentResolver.by_id(tree,"encounter",kind)
	var rows:Array=dynamic.get("waves",[]) if not dynamic.is_empty() else data().get(kind,[])
	for row in rows:
		if int(row.get("wave",0))==w:return (row as Dictionary).duplicate(true)
	return {}
func start_wave(w:int)->bool:
	if root==null or player==null or not living.is_empty():return false
	var d:=wave_def(w);if d.is_empty():return false
	active_wave=w
	var count:=int(d.get("count",1))
	for i in count:_spawn_one(d,i,count)
	wave_spawned.emit(w,str(d.get("kind","ship")),count)
	_present("bonus_wave_start","%s · WELLE %d STARTET"%[kind.to_upper(),w],{"map":kind.to_upper(),"wave":w,"count":count,"kind":str(d.get("kind","ship")).to_upper()})
	return true

func _is_final_runtime_wave(w:int)->bool:
	return not wave_def(w).is_empty() and wave_def(w+1).is_empty()
func _spawn_one(d:Dictionary,index:int,total:int)->void:
	var angle:=TAU*float(index)/maxf(1.0,float(total))
	var pos:=Vector3(cos(angle)*18.0,0.55,sin(angle)*18.0)
	var enemy:=Factory.create_ship(str(d.get("slot","BONUS TARGET")).to_upper(),pos,Color("493f50") if kind=="abyss" else Color("78542c"),false) as ShipMotor
	enemy.set_meta("production_slot",str(d.get("slot","")))
	enemy.set_meta("placeholder_replacement_ready",true)
	enemy.set_meta("bonusmap_instance_owned",true)
	enemy.set_meta("bonusmap_instance_kind",kind)
	var encounter_kind:=str(d.get("kind","ship"))
	enemy.set_meta("encounter_kind","monster" if encounter_kind in ["monster","guardian"] else ("admiral" if encounter_kind=="admiral" else "ship"))
	enemy.set_meta("is_admiral",encounter_kind in ["admiral","guardian"])
	enemy.set_meta("abyss_guardian",encounter_kind=="guardian")
	enemy.set_meta("rarity","boss" if encounter_kind in ["admiral","guardian"] else ("elite" if encounter_kind=="elite" else "common"))
	var boss_contract:=M158BonusMapBossCatalog.row(kind)
	if encounter_kind in ["admiral","guardian"] and _is_final_runtime_wave(active_wave):
		enemy.name=str(boss_contract.get("boss",enemy.name))
		enemy.set_meta("m158_bonusmap_boss",true)
		enemy.set_meta("m158_bonusmap_mechanics",boss_contract.get("mechanics",[]))
		enemy.set_meta("m158_phase_profile",M158LegacyEncounterCatalog.phase_profile_by_id(str(boss_contract.get("phase_profile",""))))
		enemy.set_meta("m158_loot_visual",str(boss_contract.get("loot_visual","tier_chest")))
		var runtime_profile:=M177BonusMapBossRuntimeCatalog.map_profile(kind)
		var runtime_mechanics:=BonusMapBossMechanics.new()
		runtime_mechanics.name="BonusMapBossMechanics"
		enemy.add_child(runtime_mechanics)
		runtime_mechanics.setup(enemy,player,kind,runtime_profile.get("mechanics",boss_contract.get("mechanics",[])))
		_present("bonus_boss","%s · ENDBOSS · %s"%[kind.to_upper(),enemy.name],{"map":kind.to_upper(),"boss":enemy.name.to_upper()})
		CombatVfx.action(get_tree(),"boss_phase",enemy.global_position)
	var health:=ShipHealth.new();health.name="Health";health.max_health=850.0+(base_level+int(d.get("level_offset",0)))*90.0;health.auto_respawn=false;enemy.add_child(health)
	var weapons:=ShipWeapons.new();weapons.name="Weapons";weapons.damage=48.0+(base_level*3.2);enemy.add_child(weapons)
	var ai:=EnemyShipAI.new();ai.name="EnemyAI";ai.archetype=str(d.get("archetype","brawler"));enemy.add_child(ai)
	root.add_child(enemy)
	if encounter_kind in ["monster","guardian"]:
		enemy.add_to_group("monsters")
		ProceduralFactory.apply_sea_monster_visual(enemy,Color("183d49") if kind=="abyss" else Color("665129"))
	health.ship_sunk.connect(_on_sunk.bind(enemy,encounter_kind))
	living.append(enemy)
func _on_sunk(_ship:ShipMotor,attacker:Node3D,enemy:ShipMotor,encounter_kind:String)->void:
	living.erase(enemy)
	var progress_result:Dictionary={}
	if is_instance_valid(attacker) and attacker==player:
		if kind=="gold":
			var progress:=player.get_node_or_null("GoldBonusMapProgress") as GoldBonusMapProgress
			if progress!=null:progress_result=progress.record_qualified_sink(player,encounter_kind=="admiral")
		elif kind=="abyss":
			var progress:=player.get_node_or_null("AbyssBonusMapProgress") as AbyssBonusMapProgress
			if progress!=null:progress_result=progress.record_sink(player,"monster" if encounter_kind in ["monster","guardian"] else "ship",encounter_kind=="guardian")
		else:
			var progress:=player.get_node_or_null("SilverBonusMapProgress" if kind=="silver" else "LegendaryBonusMapProgress") as ExtendedBonusMapProgress
			if progress!=null:progress_result=progress.record_sink(player,encounter_kind)
	if bool(progress_result.get("completed",false)):
		_present("bonus_complete","%s · BONUSMAP ABGESCHLOSSEN"%kind.to_upper(),{"map":kind.to_upper()})
		var rarity:=M177BonusMapBossRuntimeCatalog.reward_rarity(kind)
		var presentation_catalog:=M175FeedbackPresentationCatalog.current(get_tree())
		var presentation:=presentation_catalog.reward_presentation(rarity) if presentation_catalog!=null else {}
		CombatVfx.action(get_tree(),str(presentation.get("vfx_action","loot_"+rarity)),player.global_position)
		if not player_sank_during_run:
			player.set_meta("last_bonusmap_no_death_preview",{"map":kind,"reward_authority":"server_pending"})
			_present("bonus_no_death","%s · NO-DEATH-BONUS ERREICHT"%kind.to_upper(),{"map":kind.to_upper()})
	if living.is_empty():
		wave_cleared.emit(active_wave)
		if not bool(progress_result.get("completed",false)):
			_present("bonus_wave_clear","%s · WELLE %d ABGESCHLOSSEN"%[kind.to_upper(),active_wave],{"map":kind.to_upper(),"wave":active_wave})
		call_deferred("_advance")

func _present(id:String,fallback:String,values:Dictionary={})->void:
	var hud:=get_tree().get_first_node_in_group("hud") as GameHud
	if hud!=null:hud.present_event(id,fallback,values)
func _on_player_sunk(_ship:ShipMotor,_attacker:Node3D)->void:player_sank_during_run=true
func _advance()->void:
	var progress_name:="AbyssBonusMapProgress" if kind=="abyss" else ("GoldBonusMapProgress" if kind=="gold" else ("SilverBonusMapProgress" if kind=="silver" else "LegendaryBonusMapProgress"))
	var progress:Node=player.get_node_or_null(progress_name)
	if progress==null:return
	if bool(progress.get("active")):start_wave(int(progress.get("wave")))
func clear()->void:
	for e in living:
		if is_instance_valid(e):e.queue_free()
	living.clear()
