class_name AdminModeRuntime
extends Node
## M144 persistent local developer/admin preview. Never production/live authority.

signal changed
const PATH:="res://data/m94_admin_mode.json"
var enabled:=true
var overlay_open:=false
var guild_relation_index:=0
const RELATIONS:=["neutral_preview","owned","ally","enemy","war"]

func _ready()->void:
	add_to_group("admin_runtime")
	var d:=read();enabled=bool(d.get("local_default_enabled",true))
	get_tree().root.set_meta("admin_mode_local",enabled)
	get_tree().root.set_meta("staff_identity_verified",false)
	get_tree().root.set_meta("admin_mode_authority","LOCAL_DEVELOPMENT_TOOL_ONLY")

func read()->Dictionary:
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

func toggle_overlay()->void:
	if not enabled:return
	overlay_open=not overlay_open;changed.emit()

func player()->ShipMotor:return get_tree().get_first_node_in_group("player") as ShipMotor
func world()->WorldMapSystem:return get_tree().get_first_node_in_group("world_map") as WorldMapSystem
func event()->EventRuntime:return get_tree().get_first_node_in_group("event_runtime") as EventRuntime

func teleport_level(level:int)->bool:
	var w:=world()
	if w==null:return false
	for coordinate in w.sector_data:
		if int(w.sector_data[coordinate].level)==level:
			w.current_sector=coordinate
			var p:=player()
			if p!=null:p.position=Vector3.ZERO
			w._build_sector();_apply_guild_preview_relation();changed.emit();return true
	return false

func rebuild_sector()->void:
	var w:=world()
	if w!=null:
		w._build_sector()
		_apply_guild_preview_relation()
	changed.emit()

func grant_test_kit()->void:
	var p:=player()
	if p==null:return
	var inventory:=p.get_node("Inventory") as PlayerInventory
	var progression:=p.get_node("Progression") as PlayerProgression
	var kit_ids:Array[String] = CombatCatalog.ammo_ids()
	for id in ["harpoon","hunter_standard","repair","boost","veil","powder","plates","gravewake_lantern"]:
		if not kit_ids.has(id):kit_ids.append(id)
	for id in kit_ids:
		if PlayerInventory.START_STOCK.has(id):inventory.set_count(id,maxi(inventory.count(id),250 if CombatCatalog.ammo_index_by_id(id)>=0 else 20))
	progression.add_coins(25000)
	var ev:=event()
	if ev!=null:ev.admin_add_currency(250);ev.admin_add_score(40)
	changed.emit()

func heal_full()->void:
	var p:=player()
	if p==null:return
	var h:=p.get_node("Health") as ShipHealth
	h.repair(h.max_health);h.restore_shield(h.max_shield);changed.emit()

func toggle_invulnerability()->bool:
	var p:=player()
	if p==null:return false
	var value:=not bool(p.get_meta("admin_invulnerable",false))
	p.set_meta("admin_invulnerable",value);changed.emit();return value

func toggle_halloween()->void:
	var ev:=event()
	if ev!=null:ev.admin_toggle_halloween();rebuild_sector()

func cycle_event_phase()->void:
	var ev:=event()
	if ev!=null:ev.cycle_phase();rebuild_sector()

func add_event_currency()->void:
	var ev:=event()
	if ev!=null:ev.admin_add_currency(100)
	changed.emit()

func cycle_guild_relation()->String:
	guild_relation_index=posmod(guild_relation_index+1,RELATIONS.size())
	var relation:String=str(RELATIONS[guild_relation_index])
	_apply_guild_preview_relation()
	changed.emit();return relation

func _apply_guild_preview_relation()->void:
	if not enabled:return
	var relation:String=str(RELATIONS[guild_relation_index])
	for island in get_tree().get_nodes_in_group("guild_islands"):
		if not island is Node3D or island.is_queued_for_deletion():continue
		island.set_meta("relation",relation);island.set_meta("relation_authoritative",false);GuildIslandVisualState.apply(island)


func cycle_guild_tower_state()->String:
	var states:Array[String]=["intact","damaged","disabled"]
	var current:=str(get_tree().root.get_meta("admin_guild_tower_state","intact"))
	var next:String=states[(states.find(current)+1)%states.size()]
	get_tree().root.set_meta("admin_guild_tower_state",next)
	for island in get_tree().get_nodes_in_group("guild_islands"):
		GuildIslandVisualState.set_tower_damage_state(island,"cannon",next)
		GuildIslandVisualState.set_tower_damage_state(island,"chain",next)
	changed.emit()
	return next

func toggle_guild_range_preview()->bool:
	var any_visible:=false
	for island in get_tree().get_nodes_in_group("guild_islands"):
		var next:=not bool(island.get_meta("range_preview_visible",false))
		GuildIslandVisualState.set_range_preview(island,next);any_visible=next
	changed.emit()
	return any_visible

func spawn_event_preview(slot:String)->bool:
	var w:=world()
	if w==null or w.sector_content==null:return false
	var p:=player()
	var pos:=Vector3(8,0.55,8) if p==null else p.position+Vector3(7,0,5)
	var spawned:=HalloweenEventEncounters.spawn(w.sector_content,slot,pos,event())
	if spawned!=null:
		spawned.set_meta("admin_spawn",true)
		spawned.add_to_group("admin_spawned_preview")
		changed.emit()
		return true
	var holder:=Node3D.new()
	holder.name="AdminAsset_"+slot;holder.position=pos
	holder.set_meta("admin_spawn",true);holder.set_meta("visual_only",true);holder.set_meta("production_slot",slot)
	holder.add_to_group("admin_spawned_preview")
	w.sector_content.add_child(holder)
	if AssetVisualLibrary.install(holder,slot)==null:
		holder.queue_free()
		return false
	changed.emit()
	return true


func clear_admin_spawns()->int:
	var cleared:=0
	for node in get_tree().get_nodes_in_group("admin_spawned_preview"):
		if is_instance_valid(node):
			node.queue_free();cleared+=1
	changed.emit()
	return cleared


func content_registry()->AdminContentRegistry:return get_tree().get_first_node_in_group("admin_content_registry") as AdminContentRegistry
func create_content_draft(type_id:String,id:String,name:String)->Dictionary:
	var registry:=content_registry()
	if registry==null:return {}
	var row:=registry.create_draft(type_id,id,name);changed.emit();return row
func validate_content_draft(id:String)->PackedStringArray:
	var registry:=content_registry()
	if registry==null:return PackedStringArray(["registry_missing"])
	for row in registry.records():
		if str(row.get("id",""))==id:return registry.validate_record(row)
	return PackedStringArray(["draft_not_found"])
func production_publish_available()->bool:
	# Must become true only through verified staff identity + server ContentAdminService.
	return false

func admin_modules()->AdminModuleRegistry:return get_tree().get_first_node_in_group("admin_module_registry") as AdminModuleRegistry
func content_snapshots()->ContentSnapshotService:return get_tree().get_first_node_in_group("content_snapshot_service") as ContentSnapshotService

func authorization()->AdminAuthorization:return get_tree().get_first_node_in_group("admin_authorization") as AdminAuthorization
func verified_admin_summary()->String:
	var auth:=authorization()
	if auth==null or not auth.verified:return "STAFF: nicht server-verifiziert · nur lokaler Dev-Modus"
	return "STAFF: %s · Rollen: %s · Rechte: %d"%[auth.staff_id,", ".join(auth.roles),auth.permissions.size()]
func may(permission:String)->bool:
	var auth:=authorization();return auth!=null and auth.can(permission)

func spawn_dynamic_content(content_type:String,content_id:String,position:Vector3)->ShipMotor:
	if content_type not in ["npc","monster"]:return null
	var row:=DynamicContentResolver.by_id(get_tree(),content_type,content_id)
	if row.is_empty():return null
	var ship:=ProceduralFactory.create_ship(str(row.get("name",content_id)),position,Color("7a6652"),false) as ShipMotor
	if ship==null:return null
	get_tree().current_scene.add_child(ship)
	var health:=ShipHealth.new();health.name="Health";ship.add_child(health)
	var weapons:=ShipWeapons.new();weapons.name="Weapons";ship.add_child(weapons)
	var ai:=EnemyShipAI.new();ai.name="EnemyAI";ship.add_child(ai)
	DynamicEncounterContent.apply_definition(ship,row)
	ship.set_meta("admin_spawned",true);ship.add_to_group("admin_spawned")
	return ship
