class_name M159GuildIslandDepth
extends RefCounted
const PATH:="res://data/m159_guild_island_expansion.json"
static func data()->Dictionary:
	var p:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));return p if p is Dictionary else {}
static func enrich(root:Node3D)->void:
	if root==null:return
	root.set_meta("m159_guild_depth",true);root.set_meta("upgrade_tier_max",10);root.set_meta("guild_war_authority","SERVER_REQUIRED")
	_add(root,"guild_shipyard_01",Vector3(-3.5,0.55,3.4),"shipyard","WERFT")
	_add(root,"guild_treasury_01",Vector3(0.8,0.75,-2.5),"treasury","SCHATZKAMMER")
	_add(root,"guild_siege_workshop_01",Vector3(3.6,0.6,-2.8),"siege_workshop","BELAGERUNG")
	_add(root,"guild_ward_foundry_01",Vector3(-0.7,0.62,-4.0),"ward_foundry","WARDGIESSEREI")
	_tower(root,"guild_tower_mortar_01",Vector3(-5.0,0.72,-2.0),"mortar",24.0,6.4)
	_tower(root,"guild_tower_ward_01",Vector3(5.0,0.72,-2.0),"ward",20.0,7.0)
	_tower(root,"guild_tower_hunter_01",Vector3(0.0,0.82,-5.1),"hunter",25.0,5.6)
	root.set_meta("m163_authorable_ranks",7);root.set_meta("m163_building_profiles",6);root.set_meta("m163_tower_profiles",5);root.set_meta("m164_upgrade_curves",true);root.set_meta("m164_server_authoritative_building_levels",true)
	_add(root,"guild_watch_beacon_01",Vector3(-4.6,0.48,4.0),"watch_beacon","WACHTFEUER")
	_add(root,"guild_repair_dock_01",Vector3(4.7,0.42,3.8),"repair_dock","TROCKENDOCK")
	_add(root,"guild_resource_pier_01",Vector3(-5.3,0.34,1.1),"resource_pier","VERSORGUNGSPIER")
	_add(root,"guild_war_room_01",Vector3(2.5,0.55,-4.2),"war_room","KRIEGSKAMMER")
	_add(root,"guild_relic_vault_01",Vector3(-2.7,0.52,-4.2),"relic_vault","RELIKTGEWÖLBE")
static func _add(root:Node3D,name:String,pos:Vector3,id:String,label:String)->void:
	var n:=Node3D.new();n.name=name;n.position=pos;n.set_meta("production_slot",name);n.set_meta("facility_id",id);n.set_meta("facility_label",label);n.set_meta("server_required",true);n.set_meta("visual_only",true);root.add_child(n)
	if AssetVisualLibrary.install(n,name)==null:
		var m:=MeshInstance3D.new();m.mesh=FallbackPrimitiveLibrary.box(Vector3(1.7,1.0,1.5));m.material_override=EnvironmentMaterialCatalog.harbor_wood();n.add_child(m)
static func _tower(root:Node3D,name:String,pos:Vector3,role:String,range_value:float,reload:float)->void:
	var n:=Node3D.new();n.name=name;n.position=pos;n.set_meta("production_slot",name);n.set_meta("tower_role",role);n.set_meta("tower_range",range_value);n.set_meta("tower_reload",reload);n.set_meta("live_damage",false);n.set_meta("server_required",true);n.set_meta("visual_only",true);root.add_child(n)
	if AssetVisualLibrary.install(n,name)==null:
		var m:=MeshInstance3D.new();m.mesh=FallbackPrimitiveLibrary.cylinder(0.68,0.86,1.8);m.material_override=EnvironmentMaterialCatalog.harbor_stone();n.add_child(m)
