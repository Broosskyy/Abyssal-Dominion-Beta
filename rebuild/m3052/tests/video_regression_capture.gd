extends SceneTree
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var output="user://video-regressions"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	# Reproduce the submitted phone's physical size WITH the project's canvas stretch.
	root.content_scale_size=Vector2i(1280,720)
	root.size=Vector2i(2340,1080)
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false)
	game.sim.npcs.clear();game.sim.drops.clear()
	game.sim.level=4
	game.sim.player.skin=26
	game.sim.player.hp=game.sim.player.max_hp
	game.camera.zoom=Vector2.ONE*1.2
	game.elapsed=2.0
	DirAccess.make_dir_recursive_absolute(output)
	for scenario in ["portal-under-ship","portal-clear","damage-volley","harbor-frame"]:
		game.sim.events.clear();game.modal.hide();game.modal_backdrop.hide()
		game.sim.player.pos=game.sim.portals[0].pos
		if scenario=="portal-clear":game.sim.player.pos+=Vector2(-260,100)
		game.camera.position=game.sim.portals[0].pos
		if scenario=="damage-volley":
			game.camera.position=game.sim.player.pos
			game.sim.clock=1.2
			for i in 3:game.sim.events.append({"type":"impact","pos":game.sim.player.pos,"actor":0,"time":1.0+float(i)*0.08,"value":31})
		if scenario=="harbor-frame":
			game.sim.player.pos=game.sim.harbor
			game.sim.player.gold=1200
			game.sim.dock()
			game.camera.position=game.sim.player.pos
			game._open_modal("Hafen");game.modal_backdrop.show()
		game._layout();game._refresh_ui();game.queue_redraw()
		game.ocean.set_shader_parameter("camera_world",game.camera.position)
		game.ocean.set_shader_parameter("map_zoom",game.camera.zoom.x)
		game.ocean.set_shader_parameter("viewport_size",game.get_viewport_rect().size)
		for i in 4:await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(output+"/"+scenario+".png")!=OK:quit(1);return
		print(JSON.stringify({"status":"CAPTURED","scenario":scenario,"physical":[2340,1080],"canvas":str(game.get_viewport_rect().size),"fixture":true}))
	quit()
