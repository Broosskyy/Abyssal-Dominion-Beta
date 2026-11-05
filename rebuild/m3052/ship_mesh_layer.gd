extends TextureRect
## Real 3D Meshy ships composited onto the existing 2D sea simulation.
## GLB meshes are not replaced by fake sprites. 2.5D / 3D use the same fleet,
## damage, collision, pathfinding, IDs, saves and nameplate screen anchors.
const MODEL_ROOT := "res://assets/npc/meshy/models/"
## [horizontal water-plane span, original lowest Z, Z height, X midpoint, Y midpoint].
## Original Meshy source is Z-up; rotate imported nodes -90 degrees around X.
const MODEL_INFO := {
	"old_harbor_trader":[1.94,-0.26,0.51,0.14,-0.60],
	"merchant_brig_3002":[1.92,-0.21,0.42,0.16,-0.34],
	"merchant_brig_2921":[1.95,-0.26,0.54,0.02,-0.42],
	"merchant_brig_2912":[1.95,-0.29,0.57,0.29,-0.44],
	"weathered_voyager":[1.94,-0.30,0.60,-0.04,-0.34],
	"weathered_junk":[1.94,-0.25,0.49,0.19,-0.43],
	"emerald_voyager":[1.95,-0.27,0.55,0.08,-0.46],
	"midnight_mariner":[1.94,-0.25,0.51,0.07,-0.40],
	"crimson_tide_galley":[1.95,-0.32,0.67,0.16,-0.40]
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
	sun.light_energy=1.25
	sun.shadow_enabled=false
	stage.add_child(sun)
	var ambience=WorldEnvironment.new()
	var environment=Environment.new()
	environment.background_mode=Environment.BG_CLEAR_COLOR
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color(0.74,0.82,0.88)
	environment.ambient_light_energy=0.75
	ambience.environment=environment
	stage.add_child(ambience)
	for key: String in MODEL_INFO:
		var path=MODEL_ROOT+key+".glb"
		if not ResourceLoader.exists(path):
			push_warning("3D ship model unavailable: "+path)
			continue
		var scene=load(path)
		if scene is PackedScene:model_scenes[key]=scene
	texture=stage.get_texture()
	set_render_mode("classic")

func has_complete_fleet() -> bool:
	return model_scenes.size()==MODEL_INFO.size()

func set_render_mode(requested: String) -> void:
	mode=requested if requested in ["classic","hybrid","3d"] and (requested=="classic" or has_complete_fleet()) else "classic"
	visible=mode!="classic"
	if stage!=null:
		stage.render_target_update_mode=SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	if not visible:
		for item: Node3D in model_instances.values():item.visible=false

func can_render_actor(actor: Dictionary) -> bool:
	return visible and int(actor.get("id",0))>0 and str(actor.get("kind",""))=="ship" and model_scenes.has(str(actor.get("visual_key","")))

func resize_view(screen: Vector2) -> void:
	position=Vector2.ZERO
	size=screen
	if stage==null:return
	var factor=0.76 if OS.has_feature("mobile") else 1.0
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
	owner.add_child(model)
	var info: Array=MODEL_INFO[key]
	var scale_factor=float(host._actor_visual_length(actor))/maxf(float(info[0]),0.1)
	model.rotation_degrees=Vector3(-90,0,0)
	model.scale=Vector3.ONE*scale_factor
	# Waterline intersects the low hull; sails remain above the sea plane.
	model.position=Vector3(-float(info[3])*scale_factor,(-float(info[1])-float(info[2])*.13)*scale_factor,float(info[4])*scale_factor)
	model_instances[int(actor.id)]=owner
	model_instance_keys[int(actor.id)]=key
	return owner

func sync_fleet(fleet: Array[Dictionary],chart_camera: Camera2D,screen: Vector2) -> void:
	if not visible or chart_camera==null or stage==null:return
	resize_view(screen)
	var center: Vector2=chart_camera.position
	var tilt=deg_to_rad(24.0) if mode=="3d" else 0.0
	var foreshortening=maxf(cos(tilt),0.1)
	mesh_camera.size=screen.y/maxf(chart_camera.zoom.y,.05)
	var altitude=950.0
	mesh_camera.position=Vector3(center.x,altitude*cos(tilt),center.y+altitude*sin(tilt))
	mesh_camera.look_at(Vector3(center.x,0,center.y),Vector3(0,0,-1))
	var kept: Dictionary={}
	for actor: Dictionary in fleet:
		if int(actor.get("hp",0))<=0 or not can_render_actor(actor):continue
		var id=int(actor.id)
		var key=str(actor.visual_key)
		var node: Node3D=model_instances.get(id)
		if node==null or model_instance_keys.get(id,"")!=key:
			if node!=null:node.queue_free()
			node=_create_ship(actor,key)
		if node==null:continue
		var point: Vector2=host._visual_actor_pos(actor)
		# Project ground-plane centers onto the exact 2D chart positions.
		# Only the mesh gets depth / perspective; taps and combat stay 2D.
		node.position=Vector3(point.x,0,center.y+(point.y-center.y)/foreshortening)
		var heading: Vector2=actor.heading
		node.rotation.y=-heading.angle()-PI*.5
		node.visible=true
		kept[id]=true
	for id: Variant in model_instances.keys():
		if kept.has(id):continue
		var previous: Node3D=model_instances[id]
		previous.queue_free()
		model_instances.erase(id)
		model_instance_keys.erase(id)
