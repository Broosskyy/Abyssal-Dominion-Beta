class_name GuildIslandComposer
extends RefCounted
## M90 early-world Guild Island visual/interaction presentation from map level 2.
## Visual/client preview only. M163 adds authorable building/tower/rank profiles; ownership, treasury, war and live damage remain server-authoritative.

const CONTRACT_PATH:="res://data/m89_guild_island_map2_contract.json"

static func contract()->Dictionary:
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	return parsed if parsed is Dictionary else {}

static func should_spawn(map_level:int)->bool:
	return map_level>=int(contract().get("minimum_map_level",2))

static func create(position:Vector3,map_level:int)->Node3D:
	var root:=Node3D.new()
	root.name="GuildIslandPreview"
	root.position=position
	root.add_to_group("guild_islands")
	root.add_to_group("world_poi_markers")
	root.set_meta("guild_island_preview",true)
	root.set_meta("map_level",map_level)
	root.set_meta("ownership_persistence",false)
	root.set_meta("server_authority_required",true)
	root.set_meta("interaction_range",10.0)
	root.set_meta("world_marker_kind","guild_island")
	root.set_meta("poi_kind","guild_island")
	root.set_meta("poi_label","GILDENINSEL")
	root.set_meta("marker_slot","m89_guild_island")
	root.set_meta("relation","neutral_preview")
	root.set_meta("relation_authoritative",false)
	root.set_meta("marker_priority",86)
	_add_facility(root,"guild_island_base_01",Vector3.ZERO,Vector3(8.4,1.0,6.5),"island_base","basis")
	_add_facility(root,"guild_harbor_dock_01",Vector3(0,0.36,5.4),Vector3(4.6,0.34,1.25),"harbor","ANLEGEN")
	_add_facility(root,"guild_hall_01",Vector3(-1.4,0.92,-0.6),Vector3(2.3,1.65,1.8),"guild_hall","GILDE")
	_add_facility(root,"guild_warehouse_01",Vector3(2.2,0.68,-1.0),Vector3(1.9,1.15,1.55),"warehouse","LAGER")
	_add_facility(root,"guild_repair_station_01",Vector3(2.7,0.48,3.1),Vector3(1.6,0.7,1.25),"repair_station","REPARATUR")
	_add_tower(root,"guild_tower_cannon_01",Vector3(-5.3,0.72,1.7),"cannon",21.0,4.0)
	_add_tower(root,"guild_tower_chain_01",Vector3(5.2,0.72,1.5),"chain",18.0,5.2)
	_add_fortification(root,"guild_wall_straight_01",Vector3(-3.6,0.48,-4.1),Vector3(3.3,0.72,0.36),0.0)
	_add_fortification(root,"guild_wall_straight_01",Vector3(3.6,0.48,-4.1),Vector3(3.3,0.72,0.36),0.0)
	_add_fortification(root,"guild_wall_corner_01",Vector3(-6.0,0.50,-3.1),Vector3(0.65,0.82,1.8),0.0)
	_add_fortification(root,"guild_wall_corner_01",Vector3(6.0,0.50,-3.1),Vector3(0.65,0.82,1.8),0.0)
	_add_fortification(root,"guild_wall_gate_01",Vector3(0,0.54,4.1),Vector3(2.5,1.15,0.38),0.0)
	_add_fortification(root,"guild_watch_platform_01",Vector3(0,1.15,-4.4),Vector3(1.65,0.34,1.25),0.0)
	_add_objective_visual(root,"guild_shield_core_01",Vector3(0,1.02,-0.8),"shield_core")
	_add_objective_visual(root,"guild_shield_node_01",Vector3(-4.4,0.88,-1.8),"shield_node_left")
	_add_objective_visual(root,"guild_shield_node_01",Vector3(4.4,0.88,-1.8),"shield_node_right")
	root.set_meta("interaction_ids",["dock","inspect_guild","inspect_defense","inspect_facilities","inspect_harbor","range_preview"])
	root.set_meta("visual_upgrade_tier",1)
	root.set_meta("visual_damage_state","intact")
	root.set_meta("visual_state_authoritative",false)
	M159GuildIslandDepth.enrich(root)
	GuildIslandVisualState.apply(root)
	return root

static func interaction_rows(root:Node)->Array:
	if root==null or not bool(root.get_meta("guild_island_preview",false)):return []
	return contract().get("early_island",{}).get("interactions",[]).duplicate(true)

static func facility_rows(root:Node)->Array:
	var result:Array=[]
	if root==null:return result
	for node in root.get_children():
		if node is Node3D and node.has_meta("facility_id"):
			result.append({
				"id":str(node.get_meta("facility_id","")),
				"label":str(node.get_meta("facility_label","")),
				"server_required":bool(node.get_meta("server_required",true)),
				"production_slot":str(node.get_meta("production_slot","")),
				"visual_tier":int(node.get_meta("visual_tier",1)),
				"visual_damage_state":str(node.get_meta("visual_damage_state","intact")),
				"damage_state_slot":str(node.get_meta("damage_state_slot",""))
			})
	return result

static func tower_rows(root:Node)->Array:
	var result:Array=[]
	if root==null:return result
	for node in root.get_children():
		if node is Node3D and node.has_meta("tower_role"):
			result.append({
				"role":str(node.get_meta("tower_role","")),
				"range":float(node.get_meta("tower_range",0.0)),
				"reload":float(node.get_meta("tower_reload",0.0)),
				"damage_definition":str(node.get_meta("damage_definition","")),
				"live_damage":bool(node.get_meta("live_damage",false)),
				"production_slot":str(node.get_meta("production_slot","")),
				"visual_tier":int(node.get_meta("visual_tier",1)),
				"visual_damage_state":str(node.get_meta("visual_damage_state","intact")),
				"damage_state_slot":str(node.get_meta("damage_state_slot","guild_tower_state_intact_01"))
			})
	return result

static func _add_facility(root:Node3D,slot:String,pos:Vector3,fallback_size:Vector3,facility_id:String,label:String)->void:
	var socket:=Node3D.new()
	socket.name=slot
	socket.position=pos
	socket.set_meta("production_slot",slot)
	socket.set_meta("visual_only",true)
	socket.set_meta("facility_id",facility_id)
	socket.set_meta("facility_label",label)
	socket.set_meta("server_required",facility_id not in ["island_base","harbor"])
	root.add_child(socket)
	if AssetVisualLibrary.install(socket,slot)==null:
		var mesh:=MeshInstance3D.new()
		mesh.name="Fallback"
		mesh.mesh=FallbackPrimitiveLibrary.box(fallback_size)
		mesh.material_override=EnvironmentMaterialCatalog.harbor_wood()
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		socket.add_child(mesh)

static func _add_objective_visual(root:Node3D,slot:String,pos:Vector3,objective_id:String)->void:
	var socket:=Node3D.new()
	socket.name="Objective_"+objective_id
	socket.position=pos
	socket.set_meta("production_slot",slot)
	socket.set_meta("objective_id",objective_id)
	socket.set_meta("visual_only",true)
	socket.set_meta("combat_authority",false)
	socket.set_meta("capture_authority",false)
	socket.set_meta("persistent_state",false)
	socket.set_meta("marker_priority",91 if objective_id=="shield_core" else 88)
	socket.set_meta("mobile_readability","primary" if objective_id=="shield_core" else "secondary")
	socket.set_meta("objective_label","SCHILDKERN" if objective_id=="shield_core" else "SCHILDKNOTEN")
	socket.set_meta("poi_kind","guild_objective")
	socket.set_meta("poi_label",str(socket.get_meta("objective_label","GILDENZIEL")))
	socket.set_meta("marker_slot","guild_focus_01")
	socket.add_to_group("world_poi_markers")
	root.add_child(socket)
	if AssetVisualLibrary.install(socket,slot)==null:
		var mesh:=MeshInstance3D.new()
		mesh.mesh=FallbackPrimitiveLibrary.cylinder(0.42,0.62,0.72) if objective_id=="shield_core" else FallbackPrimitiveLibrary.sphere(0.32,0.46)
		var mat:=StandardMaterial3D.new()
		mat.albedo_color=Color("557f78");mat.emission_enabled=true;mat.emission=Color("35645e");mat.emission_energy_multiplier=0.32
		mesh.material_override=mat;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		socket.add_child(mesh)

static func _add_fortification(root:Node3D,slot:String,pos:Vector3,fallback_size:Vector3,yaw:float)->void:
	var socket:=Node3D.new()
	socket.name=slot+"_"+str(root.get_child_count())
	socket.position=pos
	socket.rotation_degrees.y=yaw
	socket.set_meta("production_slot",slot)
	socket.set_meta("visual_only",true)
	socket.set_meta("fortification_visual",true)
	socket.set_meta("collision_authority",false)
	socket.set_meta("siege_authority",false)
	socket.set_meta("permanent_destruction",false)
	root.add_child(socket)
	if AssetVisualLibrary.install(socket,slot)==null:
		var mesh:=MeshInstance3D.new()
		mesh.name="Fallback"
		mesh.mesh=FallbackPrimitiveLibrary.box(fallback_size)
		mesh.material_override=EnvironmentMaterialCatalog.harbor_stone() if "wall" in slot else EnvironmentMaterialCatalog.harbor_wood()
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		socket.add_child(mesh)

static func _add_tower(root:Node3D,slot:String,pos:Vector3,role:String,range_value:float,reload_value:float)->void:
	var socket:=Node3D.new()
	socket.name=slot
	socket.position=pos
	socket.set_meta("production_slot",slot)
	socket.set_meta("tower_role",role)
	socket.set_meta("tower_range",range_value)
	socket.set_meta("tower_reload",reload_value)
	socket.set_meta("damage_definition","guild_%s_tower_preview"%role)
	socket.set_meta("combat_contract","target_range_reload_damage_definition")
	socket.set_meta("live_damage",false)
	socket.set_meta("server_required",true)
	socket.set_meta("visual_tier",1)
	socket.set_meta("visual_damage_state","intact")
	socket.set_meta("tier_authoritative",false)
	socket.set_meta("damage_authoritative",false)
	socket.set_meta("damage_state_slot","guild_tower_state_intact_01")
	socket.set_meta("permanent_destruction",false)
	root.add_child(socket)
	if AssetVisualLibrary.install(socket,slot)==null:
		var body:=MeshInstance3D.new()
		body.name="TowerBody"
		body.mesh=FallbackPrimitiveLibrary.cylinder(0.72,0.92,1.7)
		body.material_override=EnvironmentMaterialCatalog.harbor_stone()
		body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		socket.add_child(body)
		var gun:=MeshInstance3D.new()
		gun.name="PresentationGun"
		gun.position=Vector3(0,1.05,0.35)
		gun.mesh=FallbackPrimitiveLibrary.box(Vector3(0.24,0.22,1.15))
		gun.material_override=EnvironmentMaterialCatalog.harbor_wood()
		gun.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		socket.add_child(gun)
