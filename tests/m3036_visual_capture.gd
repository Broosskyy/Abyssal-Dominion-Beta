extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var output := OS.get_environment("M3036_CAPTURE_DIR")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.set_meta("m3035_graphic_mode", "private_sprite")
	var scene: Node3D = (load("res://scenes/classic/classic_sea_map.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	scene.set_process(false)
	for dimensions: Vector2i in [Vector2i(844,390), Vector2i(1280,720), Vector2i(1920,1080)]:
		DisplayServer.window_set_size(dimensions)
		root.size = dimensions
		for i in 4:
			await process_frame
		scene._layout_hud()
		scene._process(0.0)
		scene._refresh()
		await process_frame
		await RenderingServer.frame_post_draw
		var bounds := scene.get_viewport().get_visible_rect()
		for key: String in scene._hud_controls:
			var button: Button = scene._hud_controls[key]
			if not bounds.encloses(button.get_global_rect()):
				failures.append("Button outside viewport: " + key + " " + str(dimensions))
		if scene._hud_controls["zoom_in"].get_global_rect().intersects(scene._hud_controls["repair"].get_global_rect()):
			failures.append("Navigation/combat overlap " + str(dimensions))
		if not scene._hud_status_frame.get_global_rect().encloses(scene.status.get_global_rect()):
			failures.append("Status outside its panel " + str(dimensions))
		root.get_texture().get_image().save_png(output.path_join("seabattles_%dx%d.png" % [dimensions.x,dimensions.y]))
	DisplayServer.window_set_size(Vector2i(1280,720))
	root.size = Vector2i(1280,720)
	for i in 4:
		await process_frame
	scene._menu_button.pressed.emit()
	scene._layout_hud()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("graphics_menu.png"))
	scene._pack_button.pressed.emit()
	scene._options_close.pressed.emit()
	scene._process(0.0)
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("seaofbones_1280x720.png"))
	scene.target = 0
	scene._refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("selected_target.png"))
	print(JSON.stringify({"layout_status": "PASS" if failures.is_empty() else "FAIL", "failures": failures}))
	quit(0 if failures.is_empty() else 1)
