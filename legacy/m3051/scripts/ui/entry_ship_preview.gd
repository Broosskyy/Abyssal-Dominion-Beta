class_name EntryShipPreview
extends SubViewportContainer
## Original reconstructed mesh assembly; static showroom, not a game screenshot.
var ship_id := "clipper"

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 240)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(420, 300)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("092636")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("c4e9ef")
	world.environment.ambient_light_energy = 0.8
	stage.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -25, 0)
	sun.light_energy = 1.4
	stage.add_child(sun)
	var ship := Node3D.new()
	ship.set_meta("visual_profile", ship_id if ShipCatalog.has_ship(ship_id) else "clipper")
	stage.add_child(ship)
	ship.add_child(ReferenceVisualAdapter.new())
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	_fit_camera.call_deferred(ship, camera, viewport)
	resized.connect(func(): _fit_camera.call_deferred(ship, camera, viewport))


func _fit_camera(ship: Node3D, camera: Camera3D, viewport: SubViewport) -> void:
	if not is_inside_tree() or not ship.is_inside_tree():
		return
	var bounds := AABB()
	var first := true
	for mesh in ship.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var center := bounds.get_center()
	var extent := maxf(bounds.size.length(), 4.0)
	camera.position = center + Vector3(1.2, 0.8, 1.5).normalized() * extent * 2.0
	camera.look_at(center)
	# Orthogonal KEEP_HEIGHT: narrow portrait viewports need extra horizontal room.
	var aspect := maxf(size.x / maxf(size.y, 1.0), 0.1)
	camera.size = extent * 1.05 / minf(aspect, 1.0)
	camera.far = extent * 6.0
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
