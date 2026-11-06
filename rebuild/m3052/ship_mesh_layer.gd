extends TextureRect
## Real 3D Meshy ships composited onto the existing 2D sea simulation.
## GLB meshes are not replaced by fake sprites. 2.5D / 3D use the same fleet,
## damage, collision, pathfinding, IDs, saves and nameplate screen anchors.
const MODEL_ROOT := "res://assets/npc/meshy/models/"
const PLAYER_MODEL_ROOT := "res://assets/player/test_ships/"
const TEST_SHIP_SKINS := {27:"crimson_voyager",28:"test_ship_2",29:"base_basic_pbr"}
# Export-critical hard references. The three new models are played by users,
# not the old NPC roster; string-based dynamic loading was insufficient to
# make the exporter retain their converted GLTF scenes in the signed PCK.
const PLAYER_TEST_SCENES := {
	"crimson_voyager":preload("res://assets/player/test_ships/crimson_voyager.glb"),
	"test_ship_2":preload("res://assets/player/test_ships/test_ship_2.glb"),
	"base_basic_pbr":preload("res://assets/player/test_ships/base_basic_pbr.glb")
}
# Confirmed with orthographic renders of ORIGINAL GLB source geometry:
# the red starter bows along -X; both big galleons bow along +Z.
# A -90 deg local Y pivot maps +Z onto -X, like the original NPC fleet.
const PLAYER_RAW_BOW := {"crimson_voyager":Vector3(-1,0,0),"test_ship_2":Vector3(0,0,1),"base_basic_pbr":Vector3(0,0,1)}
const PLAYER_WATER_IMMERSION := 0.205
const REQUIRED_NPC_KEYS := ["old_harbor_trader","merchant_brig_3002","merchant_brig_2921","merchant_brig_2912","weathered_voyager","weathered_junk","emerald_voyager","midnight_mariner","crimson_tide_galley"]
## Source Meshy glTF is already Y-UP. No -90-degree X rotation is needed.
## [hull length X, lowest Y, total Y height, X midpoint, Z midpoint].
## Measured from the nine complete ORIGINAL ~30k-triangle GLBs (not decimated assets).
const MODEL_INFO := {
	"old_harbor_trader":[1.9042,-0.9302,1.8281,-0.0009,0.0031],
	"merchant_brig_3002":[1.9012,-0.6511,1.3133,-0.0011,-0.0005],
	"merchant_brig_2921":[1.9025,-0.7811,1.5618,-0.0004,0.0016],
	"merchant_brig_2912":[1.9022,-0.7712,1.5394,-0.0006,-0.0005],
	"weathered_voyager":[1.9002,-0.7078,1.4143,-0.0004,-0.0045],
	"weathered_junk":[1.9014,-0.7706,1.5438,-0.0020,-0.0003],
	"emerald_voyager":[1.9000,-0.7652,1.5336,0.0008,-0.0004],
	"midnight_mariner":[1.9016,-0.7520,1.5024,-0.0001,-0.0030],
	"crimson_tide_galley":[1.9017,-0.6453,1.2821,-0.0002,-0.0001],
	# [longest horizontal dimension, minY, height, original centerX, centerZ, optional Y yaw]
	"crimson_voyager":[1.902524,-0.830722,1.660758,-0.000502,-0.000408,0.0],
	"test_ship_2":[1.954767,-0.510260,1.021000,-0.000050,0.022532,-90.0],
	"base_basic_pbr":[1.999924,-0.830467,1.661094,-0.000236,0.000038,-90.0]
}
var host
var stage: SubViewport
var world_root: Node3D
var mesh_camera: Camera3D
var model_scenes: Dictionary={}
var model_instances: Dictionary={}
var model_instance_keys: Dictionary={}
var mode := "classic"
var resolution_factor := 0.8
# M3088 A/B/C player-only render profile. Original imported models remain intact.
const PLAYER_STYLES := ["original","gameplay","sprite"]
var player_style := "original"
var saved_player_materials: Dictionary={}
var stylized_surface_count := 0

func set_player_style(value: String) -> void:
	player_style=value if value in PLAYER_STYLES else "original"
	var owner: Node3D=model_instances.get(0)
	if owner!=null and is_instance_valid(owner) and model_instance_keys.get(0,"")=="base_basic_pbr":
		_restyle_black_green_owner(owner)

func _restyle_black_green_owner(owner: Node3D) -> void:
	var pivot: Node3D=owner.get_node_or_null("OriginalAxisCorrection")
	if pivot==null or pivot.get_child_count()==0:return
	var pending: Array[Node]=[]
	pending.append(pivot.get_child(0))
	stylized_surface_count=0
	while not pending.is_empty():
		var current: Node=pending.pop_back()
		for child: Node in current.get_children():pending.append(child)
		if not current is MeshInstance3D:continue
		var drawable: MeshInstance3D=current as MeshInstance3D
		if drawable.mesh==null:continue
		for surface in drawable.mesh.get_surface_count():
			var material_key: String=str(drawable.get_instance_id())+":"+str(surface)
			if not saved_player_materials.has(material_key):
				saved_player_materials[material_key]=drawable.get_surface_override_material(surface)
			var source: Material=saved_player_materials[material_key]
			if source==null:source=drawable.mesh.surface_get_material(surface)
			if player_style!="gameplay":
				drawable.set_surface_override_material(surface,saved_player_materials[material_key])
				continue
			if source is StandardMaterial3D:
				var flat: StandardMaterial3D=source.duplicate() as StandardMaterial3D
				flat.roughness=maxf(flat.roughness,0.88)
				flat.metallic=minf(flat.metallic,0.12)
				flat.specular=0.20
				flat.normal_enabled=false
				drawable.set_surface_override_material(surface,flat)
				stylized_surface_count+=1
			else:
				drawable.set_surface_override_material(surface,saved_player_materials[material_key])


func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode=TextureRect.STRETCH_SCALE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	stage=SubViewport.new()
	stage.name="MeshyShipViewport"
	stage.size=Vector2i(32,32)
	stage.own_world_3d=true
	stage.transparent_bg=true
	stage.render_target_clear_mode=SubViewport.CLEAR_MODE_ALWAYS
	stage.render_target_update_mode=SubViewport.UPDATE_DISABLED
	stage.msaa_3d=Viewport.MSAA_4X
	add_child(stage)
	world_root=Node3D.new()
	world_root.name="Fleet3D"
	stage.add_child(world_root)
	mesh_camera=Camera3D.new()
	mesh_camera.name="Sea3DCamera"
	mesh_camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	mesh_camera.near=0.1
	mesh_camera.far=6000.0
	stage.add_child(mesh_camera)
	mesh_camera.current=true
	var sun=DirectionalLight3D.new()
	sun.name="SeaSun"
	sun.rotation_degrees=Vector3(-58,-38,0)
	sun.light_energy=1.66
	sun.shadow_enabled=false
	stage.add_child(sun)
	# Meshy baked albedo is dark. Add opposing soft fill to reveal the far
	# side of sails and masts instead of producing dark, wreck-like outlines.
	var fill_light=DirectionalLight3D.new()
	fill_light.name="SeaSoftFill"
	fill_light.rotation_degrees=Vector3(-55,135,0)
	fill_light.light_energy=0.59
	fill_light.shadow_enabled=false
	stage.add_child(fill_light)
	var ambience=WorldEnvironment.new()
	var environment=Environment.new()
	environment.background_mode=Environment.BG_CLEAR_COLOR
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color(0.92,0.94,1.0)
	environment.ambient_light_energy=1.09
	ambience.environment=environment
	stage.add_child(ambience)
	for key: String in MODEL_INFO:
		if PLAYER_TEST_SCENES.has(key):
			# A real scene preload is exported into the signed data pack.
			var packed: PackedScene=PLAYER_TEST_SCENES[key]
			if packed!=null:model_scenes[key]=packed
			else:push_error("Player GLB not imported: "+key)
			continue
		var path=MODEL_ROOT+key+".glb"
		if not ResourceLoader.exists(path):
			push_warning("3D NPC ship unavailable: "+path)
			continue
		var scene=load(path)
		if scene is PackedScene:model_scenes[key]=scene
	texture=stage.get_texture()
	set_render_mode("classic")

func has_complete_fleet() -> bool:
	for key: String in REQUIRED_NPC_KEYS:
		if not model_scenes.has(key):return false
	return true

func player_key_for_skin(skin: int) -> String:
	return str(TEST_SHIP_SKINS.get(skin,""))

func has_test_ship(skin: int) -> bool:
	return model_scenes.has(player_key_for_skin(skin))

func set_render_mode(requested: String) -> void:
	mode=requested if requested in ["classic","hybrid","3d"] and (requested=="classic" or has_complete_fleet()) else "classic"
	visible=mode!="classic"
	if stage!=null:
		stage.render_target_update_mode=SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	if not visible:
		for item: Node3D in model_instances.values():item.visible=false

func can_render_actor(actor: Dictionary) -> bool:
	if not visible:return false
	if int(actor.get("id",-1))==0:
		return not (int(actor.get("skin",-1))==29 and player_style=="sprite") and has_test_ship(int(actor.get("skin",-1)))
	return int(actor.get("id",0))>0 and str(actor.get("kind",""))=="ship" and model_scenes.has(str(actor.get("visual_key","")))

# Lower-hull envelope from the source GLB bounds, not the eight-angle sprite.
# Preserve the physical bow/oars and stern at every heading. The ship's
# true projection changes with camera zoom and 3D yaw, so the label must too.
const PLAYER_SOURCE_BEAMS := {"crimson_voyager":0.355,"test_ship_2":0.440,"base_basic_pbr":0.433}

func projected_hull_bottom(actor: Dictionary) -> float:
	if not can_render_actor(actor) or int(actor.get("id",-1))!=0:return -INF
	var owner: Node3D=model_instances.get(0)
	if owner==null or not is_instance_valid(owner):return -INF
	var pivot: Node3D=owner.get_node_or_null("OriginalAxisCorrection")
	if pivot==null or pivot.get_child_count()==0:return -INF
	var model: Node3D=pivot.get_child(0) as Node3D
	if model==null or mesh_camera==null:return -INF
	var key: String=player_key_for_skin(int(actor.get("skin",-1)))
	if not MODEL_INFO.has(key):return -INF
	var info: Array=MODEL_INFO[key]
	var z_long: bool=absf(float(info[5]))>1.0
	var half_length: float=float(info[0])*.5
	var half_beam: float=float(PLAYER_SOURCE_BEAMS.get(key,.44))
	var origin_screen: Vector2=mesh_camera.unproject_position(owner.global_position)
	var maximum: float=-INF
	for along in [-1.0,0.0,1.0]:
		for across in [-1.0,0.0,1.0]:
			for height in [0.08,0.36]:
				var px: float=float(info[3])+(across*half_beam if z_long else along*half_length)
				var pz: float=float(info[4])+(along*half_length if z_long else across*half_beam)
				var py: float=float(info[1])+float(info[2])*height
				var projected: Vector2=mesh_camera.unproject_position(model.to_global(Vector3(px,py,pz)))
				maximum=maxf(maximum,projected.y)
	# Use the current 2D interpolated player center so the projected name
	# stays pinned even if the 3D viewport/camera was synced one frame ago.
	var screen_center: Vector2=host.get_canvas_transform()*host._visual_actor_pos(actor)
	return screen_center.y+maximum-origin_screen.y

func resize_view(screen: Vector2) -> void:
	position=Vector2.ZERO
	size=screen
	if stage==null:return
	var factor=1.0 # Render at native screen resolution; source texture mips provide downsampling.
	resolution_factor=factor
	var wanted=Vector2i(maxi(64,roundi(screen.x*factor)),maxi(64,roundi(screen.y*factor)))
	if stage.size!=wanted:stage.size=wanted

func _create_ship(actor: Dictionary,key: String) -> Node3D:
	var packed: PackedScene=model_scenes[key]
	var model: Node3D=packed.instantiate() as Node3D
	if model==null:return null
	var owner=Node3D.new()
	owner.name="Ship3D_%s"%str(actor.id)
	world_root.add_child(owner)
	var info: Array=MODEL_INFO[key]
	# Z-long test ships are rotated into the original -X-bow coordinate frame.
	# Keep their own transform pivot independent of navigation/yaw.
	var pivot=Node3D.new()
	pivot.name="OriginalAxisCorrection"
	pivot.rotation_degrees.y=float(info[5]) if info.size()>5 else 0.0
	owner.add_child(pivot)
	pivot.add_child(model)
	var scale_factor=float(host._actor_visual_length(actor))/maxf(float(info[0]),0.1)
	model.rotation_degrees=Vector3.ZERO # Original Meshy glTF already uses Y-up.
	model.scale=Vector3.ONE*scale_factor
	# Pull the test ship keel a little deeper into the sea surface. Source
	# bounds include the sails; sinking to the old 13% of total height made
	# the player hull look detached from the flat 2D ocean underneath it.
	var immersion: float=PLAYER_WATER_IMMERSION if int(actor.id)==0 else 0.13
	model.position=Vector3(-float(info[3])*scale_factor,(-float(info[1])-float(info[2])*immersion)*scale_factor,-float(info[4])*scale_factor)
	model_instances[int(actor.id)]=owner
	model_instance_keys[int(actor.id)]=key
	if int(actor.id)==0 and key=="base_basic_pbr":
		saved_player_materials.clear()
		_restyle_black_green_owner(owner)
	return owner


# VERIFIED AGAINST NINE FULL MESHY GLBS (Nov 2026):
# Their bowsprits extend towards local -X, stern/cabins are towards +X.
# Godot's world X/Z maps to the chart X/Y; rotating local -X by
# (PI-heading.angle()) sends the *bow* into the simulated heading.
# Never rotate the entire mesh on X or offset the movement / hit positions.
func yaw_for_heading(heading: Vector2) -> float:
	if heading.length_squared()<0.000001:return 0.0
	return wrapf(PI-heading.angle(),-PI,PI)

# Keep GLB bows facing the movement vector without teleporting through 90/180
# degree changes when the patrol route chooses a new leg.
# Faster helm follow-through for the human captain: the movement simulation
# follows the requested course immediately, so a 110deg/s NPC turn would
# leave the visual player ship sailing sideways for too long.
func smooth_player_yaw(current: float,desired: float,seconds: float) -> float:
	var dt: float=clampf(seconds,0.0,0.05)
	var turn: float=angle_difference(current,desired)
	var eased: float=turn*clampf(dt*11.0,0.0,1.0)
	var limit: float=deg_to_rad(285.0)*dt
	return wrapf(current+clampf(eased,-limit,limit),-PI,PI)

# Debuggable per-model heading contract used by the automated test.
func forward_for_model(key: String,heading: Vector2) -> Vector2:
	if not PLAYER_RAW_BOW.has(key):return Vector2.ZERO
	var local_bow: Vector3=PLAYER_RAW_BOW[key]
	var normalized: Vector3=local_bow.rotated(Vector3.UP,deg_to_rad(float(MODEL_INFO[key][5])))
	var world_bow: Vector3=normalized.rotated(Vector3.UP,yaw_for_heading(heading))
	return Vector2(world_bow.x,world_bow.z).normalized()

func smooth_yaw(current: float,desired: float,seconds: float) -> float:
	var dt: float=clampf(seconds,0.0,0.05)
	var remaining: float=angle_difference(current,desired)
	var eased: float=remaining*clampf(dt*3.6,0.0,1.0)
	var limited: float=deg_to_rad(110.0)*dt
	return wrapf(current+clampf(eased,-limited,limited),-PI,PI)

func sync_fleet(fleet: Array[Dictionary],chart_camera: Camera2D,screen: Vector2) -> void:
	if not visible or chart_camera==null or stage==null:return
	resize_view(screen)
	var center: Vector2=chart_camera.position
	var tilt=deg_to_rad(43.0 if mode=="3d" else 39.0) # Consistent gameplay silhouette in both ship-render modes.
	var foreshortening=maxf(cos(tilt),0.1)
	mesh_camera.size=screen.y/maxf(chart_camera.zoom.y,.05)
	var altitude=950.0
	mesh_camera.position=Vector3(center.x,altitude*cos(tilt),center.y+altitude*sin(tilt))
	mesh_camera.look_at(Vector3(center.x,0,center.y),Vector3(0,0,-1))
	var kept: Dictionary={}
	for actor: Dictionary in fleet:
		if int(actor.get("hp",0))<=0 or not can_render_actor(actor):continue
		var id=int(actor.id)
		var key: String=player_key_for_skin(int(actor.get("skin",-1))) if id==0 else str(actor.get("visual_key",""))
		var node: Node3D=model_instances.get(id)
		var newly_instanced: bool=node==null or model_instance_keys.get(id,"")!=key
		if newly_instanced:
			if node!=null:node.queue_free()
			node=_create_ship(actor,key)
		if node==null:continue
		var point: Vector2=host._visual_actor_pos(actor)
		# Project ground-plane centers onto the exact 2D chart positions.
		# Only the mesh gets depth / perspective; taps and combat stay 2D.
		node.position=Vector3(point.x,0,center.y+(point.y-center.y)/foreshortening)
		var heading: Vector2=actor.heading
		var desired_yaw: float=yaw_for_heading(heading)
		# Spawn at correct nose direction; only subsequent turns are smoothed.
		if newly_instanced:node.rotation.y=desired_yaw
		else:
			var dt: float=get_process_delta_time()
			node.rotation.y=smooth_player_yaw(node.rotation.y,desired_yaw,dt) if id==0 else smooth_yaw(node.rotation.y,desired_yaw,dt)
		# Subtle animated heave/roll: under one world unit so the real keel
		# stays on the 2D sea plane. Larger hulls move more heavily.
		var cruise: float=host._wake_intensity_for(actor)
		var long_ship: bool=float(host._actor_visual_length(actor))>=175.0
		var swell: float=0.27 if long_ship else 0.42
		var clock: float=host.elapsed*1.55+float(id)*1.37
		node.position.y=sin(clock)*swell*(.32+.68*cruise)
		var axis: Node3D=node.get_node_or_null("OriginalAxisCorrection")
		if axis!=null:
			var base_yaw: float=deg_to_rad(float(MODEL_INFO[key][5])) if MODEL_INFO[key].size()>5 else 0.0
			var bank: float=clampf(rad_to_deg(angle_difference(node.rotation.y,desired_yaw))*.035,-1.6,1.6)
			axis.rotation=Vector3(
				deg_to_rad(sin(clock*.78)*(.30+.40*cruise)),
				base_yaw,
				deg_to_rad(sin(clock+.65)*(.24+.36*cruise)+bank)
			)
		node.visible=true
		kept[id]=true
	for id: Variant in model_instances.keys():
		if kept.has(id):continue
		var previous: Node3D=model_instances[id]
		previous.queue_free()
		model_instances.erase(id)
		model_instance_keys.erase(id)
