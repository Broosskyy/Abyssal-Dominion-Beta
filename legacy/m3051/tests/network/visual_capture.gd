extends SceneTree
func _initialize() -> void: call_deferred("run")
func save_frame(path: String) -> void:
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(path)
	assert(err==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	root.set_meta("m3035_graphic_mode","private_sprite")
	var server := load("res://scenes/network/zone_server.tscn").instantiate() as Node
	root.add_child(server)
	var game := load("res://scenes/network/crossplay_chart.tscn").instantiate() as Node3D
	root.add_child(game)
	current_scene=game
	var observer := WebSocketPeer.new()
	observer.connect_to_url("ws://127.0.0.1:9080")
	for i in 90:
		observer.poll()
		await process_frame
	DirAccess.make_dir_recursive_absolute("res://builds/m3050")
	await save_frame("res://builds/m3050/online_landscape.png")
	game._toggle_ammo_inventory()
	await save_frame("res://builds/m3050/ammunition.png")
	game._toggle_ammo_inventory()
	root.size=Vector2i(844,390)
	await save_frame("res://builds/m3050/mobile_landscape.png")
	observer.close()
	game.queue_free()
	server.queue_free()
	print("M3050_CAPTURE_PASS")
	quit()
