extends SceneTree
## M392 OFFLINE ONLY: Import a reviewed Meshy/GLB source once and bake a
## consistent transparent 4- or 8-angle island sprite set.
##
## Godot editor import must already be complete. This never calls Meshy,
## cloud APIs, additional credits, or deploys to Vercel.
##
##   godot --headless --path rebuild/m3052 --editor --import --quit
##   xvfb-run -a godot --path rebuild/m3052 --script tools/bake_island_views.gd -- --asset=A01 --views=8
##
## The files remain PENDING until manual art and shoreline validation,
## and the approved catalog record are committed together.
const CATALOG=preload("res://island_asset_catalog.gd")
const FRAME=512
const CAMERA_ELEVATION=48.0
const TARGET_EXTENT=2.6
var viewport: SubViewport
var studio: Node3D
var camera: Camera3D

func _initialize() -> void:
	call_deferred("_bake")

func _bake() -> void:
	var asset_id: String=""
	var frames: int=8
	for option: String in OS.get_cmdline_user_args():
		if option.begins_with("--asset="):asset_id=option.trim_prefix("--asset=").to_upper()
		elif option.begins_with("--views="):frames=int(option.trim_prefix("--views="))
	if not frames in [4,8]:
		push_error("M392 requires --views=4 or --views=8")
		quit(1)
		return
	var item: Dictionary=CATALOG.entry(asset_id)
	if item.is_empty():
		push_error("Unknown M392 island ID: "+asset_id)
		quit(1)
		return
	var glb_path: String=str(item.mesh_glb)
	if not ResourceLoader.exists(glb_path):
		push_error("Reviewed GLB not found (no model is fabricated): "+glb_path)
		quit(1)
		return
	var model_resource: Resource=load(glb_path)
	if not model_resource is PackedScene:
		push_error("Island GLB failed Godot import: "+glb_path)
		quit(1)
		return
	root.content_scale_size=Vector2i.ZERO
	viewport=SubViewport.new()
	viewport.size=Vector2i(FRAME,FRAME)
	viewport.name="M392ApprovedIslandBake"
	viewport.transparent_bg=true
	viewport.own_world_3d=true
	viewport.render_target_clear_mode=SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_4X
	root.add_child(viewport)
	studio=Node3D.new()
	viewport.add_child(studio)
	var island: Node3D=(model_resource as PackedScene).instantiate() as Node3D
	if island==null:
		push_error("Imported GLB has no 3D root")
		quit(1)
		return
	studio.add_child(island)
	var surfaces: Array[MeshInstance3D]=[]
	_collect_meshes(island,surfaces)
	if surfaces.is_empty():
		push_error("Island GLB has no mesh geometry")
		quit(1)
		return
	var world_bounds: AABB=AABB()
	var first: bool=true
	for surface: MeshInstance3D in surfaces:
		if surface.mesh==null:continue
		var box: AABB=surface.global_transform*surface.mesh.get_aabb()
		if first:
			world_bounds=box
			first=false
		else:
			world_bounds=world_bounds.merge(box)
	if first or world_bounds.size.length()<0.001:
		push_error("Island GLB contains no meaningful vertices")
		quit(1)
		return
	var center: Vector3=world_bounds.get_center()
	var max_span: float=maxf(maxf(world_bounds.size.x,world_bounds.size.z),world_bounds.size.y)
	var ratio: float=TARGET_EXTENT/maxf(.001,max_span)
	island.scale=Vector3.ONE*ratio
	island.position=-center*ratio
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.9
	camera.near=.1
	camera.far=80.0
	studio.add_child(camera)
	camera.current=true
	var main_light:=DirectionalLight3D.new()
	main_light.rotation_degrees=Vector3(-52,-34,0)
	main_light.light_energy=1.5
	studio.add_child(main_light)
	var bounce:=DirectionalLight3D.new()
	bounce.rotation_degrees=Vector3(-40,122,0)
	bounce.light_energy=.75
	studio.add_child(bounce)
	var environment_node:=WorldEnvironment.new()
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_CLEAR_COLOR
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("e2e9ee")
	environment.ambient_light_energy=.95
	environment_node.environment=environment
	studio.add_child(environment_node)
	var directory: String=str(item["views_"+str(frames)])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var elevation: float=deg_to_rad(CAMERA_ELEVATION)
	var saved: Array[String]=[]
	for heading in frames:
		var azimuth: float=PI*.25+float(heading)*TAU/float(frames)
		var vector:=Vector3(cos(elevation)*sin(azimuth),sin(elevation),cos(elevation)*cos(azimuth))
		camera.position=vector*7.5
		camera.look_at(Vector3.ZERO,Vector3.UP)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var picture: Image=viewport.get_texture().get_image()
		var save_to: String="%s/%02d.png" % [directory,heading]
		if picture.save_png(save_to)!=OK:
			push_error("Could not save actual 3D island render "+save_to)
			quit(1)
			return
		saved.append(save_to)
	# JSON log allows a separate validator to audit exact frame count,
	# orientation and 512px transparent outputs before artist approval.
	print(JSON.stringify({"status":"BAKED","asset":asset_id,"views":frames,"frame_px":FRAME,
		"elevation_degrees":CAMERA_ELEVATION,"files":saved}))
	quit(0)

func _collect_meshes(node: Node,surfaces: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:surfaces.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		_collect_meshes(child,surfaces)
