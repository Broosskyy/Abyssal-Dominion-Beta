extends SceneTree
## Native renderer capture; files are generated only when an output is provided.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var output := OS.get_environment("M3035_CAPTURE_DIR")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var packed := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	var scene: Node3D = packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(844,390), Vector2i(1920,1080)]:
		DisplayServer.window_set_size(dimensions)
		root.size = dimensions
		for i in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		var name := "native_%dx%d.png" % [dimensions.x, dimensions.y]
		picture.save_png(output.path_join(name))
		print("Captured ", name, " actual=", picture.get_size())
	# Exercise the screen-to-world click path before the movement screenshot.
	var destination: Vector2 = scene.camera.unproject_position(scene.ship.global_position + Vector3(10,0,3))
	scene._world_click(destination)
	for i in 90:
		scene._sail(1.0 / 60.0)
		scene._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("native_after_course.png"))
	DisplayServer.window_set_size(Vector2i(1280,720))
	root.size = Vector2i(1280,720)
	var creature: Node3D = scene.enemies[5].node
	scene.pan = creature.position - scene.ship.position
	scene.zoom = 55.0
	scene._process(2.0)
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("native_monster.png"))
	quit()
