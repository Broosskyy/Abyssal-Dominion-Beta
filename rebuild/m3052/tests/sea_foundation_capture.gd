extends SceneTree
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var output="user://sea-foundation"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false)
	game.sim.player.pos=Vector2(500,500);game.camera.position=Vector2(850,540);game.camera.zoom=Vector2.ONE
	var npc=game.sim.npcs[0];npc.pos=Vector2(600,500);npc.home=npc.pos
	game.sim.npcs.clear();game.sim.npcs.append(npc);game.sim.drops.clear()
	npc.path=game.sim.plan_actor_path(npc,Vector2(1180,500))
	DirAccess.make_dir_recursive_absolute(output)
	var telemetry: Array=[]
	for frame in 140:
		game.sim._move(npc,0.1)
		game.elapsed+=0.1;game.queue_redraw()
		game.ocean.set_shader_parameter("camera_world",game.camera.position)
		game.ocean.set_shader_parameter("map_zoom",game.camera.zoom.x)
		game.ocean.set_shader_parameter("viewport_size",game.get_viewport_rect().size)
		game.chart_mini.camera_world=game.camera.position;game.chart_mini.view_world=game.get_viewport_rect().size/game.camera.zoom;game.chart_mini.queue_redraw()
		telemetry.append({"time":float(frame)*.1,"x":npc.pos.x,"y":npc.pos.y,"hx":npc.heading.x,"hy":npc.heading.y})
		await process_frame;await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(output+"/motion_%03d.png"%frame)!=OK:quit(1);return
	var f=FileAccess.open(output+"/zigzag.json",FileAccess.WRITE);f.store_string(JSON.stringify(telemetry));f.close()
	game.sim.player.pos=Vector2(1850,1400);game.camera.position=game.sim.player.pos;game.sim.npcs.clear()
	game.camera.zoom=Vector2.ONE*.96;game._refresh_ui();game.queue_redraw()
	game.ocean.set_shader_parameter("camera_world",game.camera.position)
	game.chart_mini.camera_world=game.camera.position;game.chart_mini.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/coast-water-ammo.png")
	print(JSON.stringify({"status":"CAPTURED","scenario":"real four-view movement","frames":140,"telemetry":true}))
	quit()
