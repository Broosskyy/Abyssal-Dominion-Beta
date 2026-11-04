extends SceneTree
## Render derived PNGs from private source meshes; no network or game execution.
var stage: SubViewport
var pivot: Node3D
var model: MeshInstance3D
var camera: Camera3D
const ROOT := "res://assets/classic/private_seaofbones/"
const CELL := 512

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	stage = SubViewport.new()
	stage.size = Vector2i(CELL, CELL)
	stage.transparent_bg = true
	stage.own_world_3d = true
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	light.light_energy = 1.0
	stage.add_child(light)
	var lighting := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.7
	lighting.environment = environment
	stage.add_child(lighting)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.35
	camera.position = Vector3(0, 6.8, 4.3)
	stage.add_child(camera)
	camera.look_at(Vector3.ZERO)
	pivot = Node3D.new()
	stage.add_child(pivot)
	model = MeshInstance3D.new()
	pivot.add_child(model)
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "models/models.json"))
	var results: Array = []
	for item: Dictionary in entries:
		if str(item.get("status", "")) != "ready":
			continue
		var only := OS.get_environment("M3035_RENDER_ONLY")
		if not only.is_empty() and not str(item.name) in only.split(","):
			continue
		var mesh := load(ROOT + "models/" + str(item.mesh)) as Mesh
		if mesh == null:
			push_error("Missing preview mesh: " + str(item.mesh))
			quit(1)
			return
		model.mesh = mesh
		var bounds := mesh.get_aabb()
		var extent := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
		var normalizer := 1.65 / maxf(extent, 0.001)
		model.scale = Vector3.ONE * normalizer
		model.position = -bounds.get_center() * normalizer
		var material := StandardMaterial3D.new()
		var bitmap := Image.new()
		bitmap.load(ProjectSettings.globalize_path(ROOT + "models/" + str(item.albedo)))
		if bitmap == null or bitmap.is_empty():
			push_error("Source texture is missing or corrupt: " + str(item.albedo))
			quit(1)
			return
		material.albedo_texture = ImageTexture.create_from_image(bitmap)
		material.roughness = 0.9
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		model.material_override = material
		var frames := int(item.frames)
		var columns := 4 if frames == 8 else 1
		var rows := 2 if frames == 8 else 1
		var atlas := Image.create(CELL * columns, CELL * rows, false, Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		var alpha_min := 255
		var alpha_max := 0
		for frame in frames:
			pivot.rotation.y = TAU * float(frame) / float(frames)
			await process_frame
			await RenderingServer.frame_post_draw
			var image := stage.get_texture().get_image()
			if image == null or image.is_empty():
				push_error("Renderer returned no pixels")
				quit(1)
				return
			image.convert(Image.FORMAT_RGBA8)
			atlas.blit_rect(image, Rect2i(0, 0, CELL, CELL), Vector2i((frame % columns) * CELL, (frame / columns) * CELL))
		var destination := ROOT + str(item.slot)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination.get_base_dir()))
		var error := atlas.save_png(destination)
		if error != OK:
			push_error("PNG write failed: " + destination)
			quit(1)
			return
		results.append({"source_mesh": item.name, "png": item.slot, "columns": columns, "rows": rows, "cell": CELL,
			"derived": true, "camera": [0, 68, 43], "heading_degrees": "frame * 360 / frames", "transparent_viewport": true})
		print("Rendered ", item.name, " -> ", destination)
	FileAccess.open(ROOT + "derived_atlases.json", FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	quit()
