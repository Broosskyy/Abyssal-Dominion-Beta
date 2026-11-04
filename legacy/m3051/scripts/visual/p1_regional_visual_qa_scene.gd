class_name P1RegionalVisualQaScene
extends Node3D

const LANES := [
	{"id":"crimson_sea","label":"CRIMSON SEA · PL6–10","x":-13.0,"ship":"npc_storm_raider","admiral":"npc_storm_admiral","monster":"monster_krakenling_01","island":"island_module_crimson_coast_01","harbor":"harbor_stormreach"},
	{"id":"drowned_reach","label":"DROWNED REACH · PL11–15","x":13.0,"ship":"npc_ember_raider","admiral":"npc_ember_admiral","monster":"monster_drowned_beast_01","island":"island_module_drowned_coast_01","harbor":"harbor_ember"}
]

func _ready() -> void:
	name = "M150P1RegionalVisualAcceptance"
	set_meta("milestone","M150")
	set_meta("acceptance_basis","mobile_oblique_top_down")
	_build_environment()
	for lane in LANES: _build_lane(lane)

func _build_environment() -> void:
	var world := WorldEnvironment.new(); world.name = "WorldEnvironment"; add_child(world)
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("173847")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("afc9c7"); env.ambient_light_energy = 0.78
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; world.environment = env
	var sun := DirectionalLight3D.new(); sun.name = "Sun"; sun.rotation_degrees = Vector3(-52,-32,0); sun.light_color = Color("ffe0b8"); sun.light_energy = 1.15; sun.shadow_enabled = true; add_child(sun)
	var camera := Camera3D.new(); camera.name = "MobileObliqueCamera"; camera.position = Vector3(0,34,39); camera.fov = 46.0; camera.current = true; add_child(camera); camera.look_at(Vector3(0,0,0))
	var floor := MeshInstance3D.new(); floor.name = "SeaMapAcceptanceFloor"; var plane := PlaneMesh.new(); plane.size = Vector2(62,42); floor.mesh = plane
	var floor_mat := StandardMaterial3D.new(); floor_mat.albedo_color = Color("0a4b63"); floor_mat.roughness = 0.32; floor_mat.metallic = 0.04; floor.material_override = floor_mat; floor.position.y = -0.58; add_child(floor)

func _build_lane(lane: Dictionary) -> void:
	var lane_root := Node3D.new(); lane_root.name = str(lane.id).to_pascal_case(); lane_root.position.x = float(lane.x); lane_root.set_meta("region_id",lane.id); add_child(lane_root)
	_label(lane_root,str(lane.label),Vector3(0,5.8,-8.0),42)
	_add_asset(lane_root,str(lane.id),str(lane.ship),"ship",Vector3(-4.2,0,-2.5),false)
	_add_asset(lane_root,str(lane.id),str(lane.admiral),"ship",Vector3(4.2,0,-2.5),true)
	_add_asset(lane_root,str(lane.id),str(lane.monster),"monster",Vector3(-5.0,0,6.0),true)
	_add_asset(lane_root,str(lane.id),str(lane.island),"world",Vector3(1.0,0,7.2),false)
	_add_asset(lane_root,str(lane.id),str(lane.harbor),"harbor",Vector3(6.0,0,6.2),true)
	_label(lane_root,"NPC",Vector3(-4.2,3.5,-2.5),24); _label(lane_root,"ADMIRAL",Vector3(4.2,4.0,-2.5),24)
	_label(lane_root,"MONSTER",Vector3(-5.0,3.5,6.0),24); _label(lane_root,"ISLAND",Vector3(1.0,3.5,7.2),24); _label(lane_root,"HARBOR",Vector3(6.0,3.5,6.2),24)

func _add_asset(parent: Node3D, region_id: String, slot: String, family: String, pos: Vector3, hero: bool) -> void:
	var holder := Node3D.new(); holder.name = slot; holder.position = pos; holder.set_meta("production_slot",slot); holder.set_meta("qa_family",family); parent.add_child(holder)
	var size := Vector3.ONE * (0.38 if family in ["world","harbor"] else 0.72)
	AssetVisualLibrary.install(holder,slot,size)
	if family in ["ship","monster"]:
		holder.set_meta("encounter_kind",family)
		P1RegionalPresentationAdapter.apply_entity(holder,region_id,family,hero)
	elif family == "harbor": P1RegionalPresentationAdapter.apply_harbor(holder,region_id)
	else: P1RegionalPresentationAdapter.apply_world_asset(holder,region_id,"world")

func _label(parent: Node3D, value: String, pos: Vector3, size: int) -> void:
	var label := Label3D.new(); label.text = value; label.position = pos; label.font_size = size; label.outline_size = 8; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; parent.add_child(label)
