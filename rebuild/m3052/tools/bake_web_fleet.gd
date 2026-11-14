extends SceneTree
## Offline renderer: actual installed GLB meshes -> eight transparent 2D
## directional frames each. Runs inside the Linux CI build using real Godot
## OpenGL under Xvfb. Never run this on an Android phone or browser.
## The runtime loads only baked atlases. It never imports GLB resources.
const MESH = preload("res://ship_mesh_layer.gd")
const TAPER = preload("res://stern_hull_taper.gd")
const OUT := "res://assets/classic_baked"
const FRAME := 256
const ANGLES := 8
const CAMERA_SIZE := 3.35
const MODELS := {
	"schattenkriegsschiff_shaded":"res://assets/player/schattenkriegsschiff_shaded.glb",
	"black_crown_corsair_elite_test":"res://assets/npc/meshy/models/black_crown_corsair_elite_test.glb",
	"old_harbor_trader":"res://assets/npc/meshy/models/old_harbor_trader.glb",
	"merchant_brig_3002":"res://assets/npc/meshy/models/merchant_brig_3002.glb",
	"merchant_brig_2921":"res://assets/npc/meshy/models/merchant_brig_2921.glb",
	"merchant_brig_2912":"res://assets/npc/meshy/models/merchant_brig_2912.glb",
	"weathered_voyager":"res://assets/npc/meshy/models/weathered_voyager.glb",
	"weathered_junk":"res://assets/npc/meshy/models/weathered_junk.glb",
	"emerald_voyager":"res://assets/npc/meshy/models/emerald_voyager.glb",
	"midnight_mariner":"res://assets/npc/meshy/models/midnight_mariner.glb",
	"crimson_tide_galley":"res://assets/npc/meshy/models/crimson_tide_galley.glb"
}
const ELITE_PAINT := [
	"res://assets/elite_v2/textures/Elite_01_Obsidian_Albedo.png",
	"res://assets/elite_v2/textures/Elite_02_Bordeaux_Albedo.png",
	"res://assets/elite_v2/textures/Elite_03_Tiefblau_Albedo.png",
	"res://assets/elite_v2/textures/Elite_04_Waldgruen_Albedo.png",
	"res://assets/elite_v2/textures/Elite_05_Violett_Albedo.png",
	"res://assets/elite_v2/textures/Elite_06_Petrol_Albedo.png",
	"res://assets/elite_v2/textures/Elite_07_Elfenbein_Albedo.png",
	"res://assets/elite_v2/textures/Elite_08_Stahlblau_Albedo.png",
	"res://assets/elite_v2/textures/Elite_09_Karmesin_Albedo.png",
	"res://assets/elite_v2/textures/Elite_10_Knochen_Albedo.png",
	"res://assets/expansion/halloween.webp",
	"res://assets/expansion/columbus.webp"
]
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var output: String=OUT
var files: Array[Dictionary]=[]

func _monster_baselines() -> Dictionary:
	var result: Dictionary={}
	var image: Image=Image.load_from_file("res://assets/reference/monsters/tiamat.png")
	var cell: Vector2=Vector2(image.get_size())/Vector2(4,10)
	var bottom: float=0.0
	for row in 10:
		for column in 4:
			var region: Image=image.get_region(Rect2i(Vector2(column,row)*cell,cell))
			bottom=maxf(bottom,(float(region.get_used_rect().end.y)-cell.y*.68)*210.0/cell.x)
	result["tiamat"]=bottom
	for key: String in ["kraken","serpent","crab","glitter","pumpkin"]:
		var source: Image=Image.load_from_file("res://assets/expansion/"+key+".webp")
		result[key]=(float(source.get_used_rect().end.y)-source.get_height()*.5)*227.5/maxf(source.get_width(),source.get_height())+2.5
	return result

func _initialize() -> void:
	call_deferred("_bake_all")

func _prepare_view() -> void:
	root.content_scale_size=Vector2i.ZERO
	viewport=SubViewport.new()
	viewport.name="WebSpriteBake"
	viewport.size=Vector2i(FRAME,FRAME)
	viewport.own_world_3d=true
	viewport.transparent_bg=true
	viewport.render_target_clear_mode=SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_4X
	root.add_child(viewport)
	world=Node3D.new()
	viewport.add_child(world)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=CAMERA_SIZE
	camera.near=.1
	camera.far=100.0
	viewport.add_child(camera)
	var focus=Vector3(0,.47,0)
	var tilt=deg_to_rad(MESH.FLEET_CAMERA_TILT_DEGREES)
	camera.position=focus+Vector3(0,cos(tilt)*9.0,sin(tilt)*9.0)
	camera.look_at(focus,Vector3(0,0,-1))
	camera.current=true
	var key=DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-58,-38,0)
	key.light_energy=1.52
	key.shadow_enabled=false
	viewport.add_child(key)
	var fill=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-55,135,0)
	fill.light_energy=.78
	fill.shadow_enabled=false
	viewport.add_child(fill)
	var env_node=WorldEnvironment.new()
	var env=Environment.new()
	env.background_mode=Environment.BG_CLEAR_COLOR
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(.92,.94,1.0)
	env.ambient_light_energy=1.14
	env_node.environment=env
	viewport.add_child(env_node)

func _configure_surfaces(model: Node3D,paint: int) -> void:
	# Match the actual runtime's double-sided sails; Elite 01–10 and event
	# finishes are applied to the shared ORIGINAL Corsair mesh, not a new hull.
	var texture: Texture2D=null
	if paint>0:
		texture=load(ELITE_PAINT[paint-1]) as Texture2D
		if texture==null:
			push_error("Missing original elite texture: "+ELITE_PAINT[paint-1])
			quit(1)
	var pending: Array[Node]=[model]
	while not pending.is_empty():
		var node: Node=pending.pop_back()
		for child: Node in node.get_children():pending.append(child)
		if not node is MeshInstance3D:continue
		var piece=node as MeshInstance3D
		if piece.mesh==null:continue
		for surface in range(piece.mesh.get_surface_count()):
			var original: Material=piece.get_active_material(surface)
			if not original is StandardMaterial3D:continue
			var copy=(original as StandardMaterial3D).duplicate() as StandardMaterial3D
			copy.cull_mode=BaseMaterial3D.CULL_DISABLED
			if texture!=null:
				copy.albedo_texture=texture
				copy.albedo_color=Color.WHITE
			piece.set_surface_override_material(surface,copy)

func _spawn(key: String,paint: int) -> Node3D:
	var info: Array=MESH.MODEL_INFO[key]
	var packed=load(MODELS[key]) as PackedScene
	if packed==null:
		push_error("GLB not imported: "+key)
		return null
	var model=packed.instantiate() as Node3D
	if model==null:return null
	var owner=Node3D.new()
	world.add_child(owner)
	var axis=Node3D.new()
	axis.rotation_degrees.y=float(info[5]) if info.size()>5 else 0.0
	owner.add_child(axis)
	axis.add_child(model)
	if key=="schattenkriegsschiff_shaded":
		TAPER.apply_to_scene(model)
	# Exactly the native game's original model centering and keel immersion.
	var immersion: float=.23 if key=="schattenkriegsschiff_shaded" else .205 if key=="black_crown_corsair_elite_test" else .13
	model.position=Vector3(-float(info[3]),-float(info[1])-float(info[2])*immersion,-float(info[4]))
	_configure_surfaces(model,paint)
	return owner

func _render_atlas(key: String,paint: int,name: String) -> bool:
	var owner: Node3D=_spawn(key,paint)
	if owner==null:return false
	var atlas=Image.create(FRAME*ANGLES,FRAME,false,Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var coverage: Array[int]=[]
	var frames: Array[Dictionary]=[]
	var water_pivot: Vector2=camera.unproject_position(Vector3.ZERO)
	var reference_extent: float=float(FRAME)*float(MESH.MODEL_INFO[key][0])/CAMERA_SIZE
	var stable_bottom: float=0.0
	for heading_index in range(ANGLES):
		# Eight distinct baked model views: N, NE, E, SE, S, SW, W, NW.
		# The FOUR legacy diagonal facings MUST match the actual 48x32
		# chart step, not 45-degree compass facings. 45-degree frames
		# looked like the ship was sideways/sliding during a 3:2 leg.
		# This affects only 2D source-GLB atlas renders; native 3D is
		# the same untouched GLB geometry.
		var heading_angle: float=-PI*.5+float(heading_index)*PI*.25
		var iso_angle: float=atan2(32.0,48.0)
		match heading_index:
			1:heading_angle= -iso_angle
			3:heading_angle=iso_angle
			5:heading_angle=PI-iso_angle
			7:heading_angle= -PI+iso_angle
		owner.rotation.y=wrapf(PI-heading_angle,-PI,PI)
		for _i in 3:await process_frame
		await RenderingServer.frame_post_draw
		var capture: Image=viewport.get_texture().get_image()
		if capture==null or capture.is_empty():
			push_error("Blank framebuffer: "+name)
			owner.queue_free()
			return false
		if capture.get_format()!=Image.FORMAT_RGBA8:capture.convert(Image.FORMAT_RGBA8)
		var visible=0
		for yy in range(8,FRAME-8,8):
			for xx in range(8,FRAME-8,8):
				if capture.get_pixel(xx,yy).a>.05:visible+=1
		if visible<15 or visible>850:
			push_error("Invalid alpha coverage %d in %s heading %d" % [visible,name,heading_index])
			owner.queue_free()
			return false
		coverage.append(visible)
		var bounds: Rect2i=capture.get_used_rect()
		if bounds.position.x<2 or bounds.position.y<2 or bounds.end.x>FRAME-2 or bounds.end.y>FRAME-2:
			push_error("Clipped original GLB render: "+name+" heading "+str(heading_index))
			owner.queue_free()
			return false
		frames.append({"rect":[heading_index*FRAME+bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],
			"pivot":[water_pivot.x-bounds.position.x,water_pivot.y-bounds.position.y],"reference_extent":reference_extent,
			"heading_angle_rad":heading_angle})
		stable_bottom=maxf(stable_bottom,float(bounds.end.y)-water_pivot.y)
		atlas.blit_rect(capture,Rect2i(0,0,FRAME,FRAME),Vector2i(heading_index*FRAME,0))
	owner.queue_free()
	var path=output+"/"+name+".png"
	var err=atlas.save_png(path)
	if err!=OK:
		push_error("Cannot write "+path+": "+str(err))
		return false
	# Every heading keeps the SAME source-unit scale and water-contact pivot.
	# Alpha crops remove padding, never resize each view to a different size.
	files.append({"name":name,"source":key,"paint":paint,"coverage":coverage,
		"frames":frames,"reference_extent":reference_extent,"stable_bottom":stable_bottom})
	print("BAKED_GLTF_ATLAS "+name+" "+str(coverage))
	await process_frame
	return true

func _bake_all() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var mkdir=DirAccess.make_dir_recursive_absolute(output)
	if mkdir!=OK:
		push_error("No output folder: "+output)
		quit(1)
		return
	_prepare_view()
	for key in MODELS:
		var baked: bool=await _render_atlas(key,0,key)
		if not baked:
			quit(1)
			return
	for i in range(ELITE_PAINT.size()):
		var name="elite_%02d" % (i+1) if i<10 else "event_halloween" if i==10 else "event_columbus"
		var painted: bool=await _render_atlas("black_crown_corsair_elite_test",i+1,name)
		if not painted:
			quit(1)
			return
	var data={"status":"BAKED_FROM_ORIGINAL_GLBS","angles":ANGLES,"frame_px":FRAME,
		"order":"N,NE,E,SE,S,SW,W,NW","atlases":files,"monster_bottoms":_monster_baselines()}
	var manifest=FileAccess.open(output+"/manifest.json",FileAccess.WRITE)
	if manifest==null:
		push_error("Cannot save atlas manifest")
		quit(1)
		return
	manifest.store_string(JSON.stringify(data,"\t"))
	manifest.close()
	print("WEB_SPRITES_READY "+JSON.stringify({"status":"PASS","atlases":files.size(),"frames":files.size()*ANGLES,"frame_px":FRAME}))
	quit(0)
