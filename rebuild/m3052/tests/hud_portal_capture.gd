extends SceneTree
func _initialize() -> void:call_deferred("_run")
func _shot(game: Node,output: String,name: String) -> void:
	game._layout();game._refresh_ui();game.queue_redraw()
	game.ocean.set_shader_parameter("camera_world",game.camera.position)
	game.ocean.set_shader_parameter("map_zoom",game.camera.zoom.x)
	game.ocean.set_shader_parameter("viewport_size",game.get_viewport_rect().size)
	game.chart_mini.camera_world=game.camera.position;game.chart_mini.view_world=game.get_viewport_rect().size/game.camera.zoom;game.chart_mini.queue_redraw()
	# Container minimum sizes and wrapping need several layout passes after profile changes.
	for _frame in 8:await process_frame
	if game.modal.visible:
		var bounds: Rect2=game.modal_scroll.get_global_rect()
		for button: Button in game.modal_body.find_children("*","Button",true,false):
			if button.get_global_rect().end.x>bounds.end.x+1:
				push_error("Rendered modal content exceeds scroll viewport: "+name);quit(1);return
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output+"/"+name+".png")!=OK:push_error("HUD capture failed")
func _run() -> void:
	var output="user://hud-portal"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false);game.elapsed=2.0
	game.hud_size=1;game.journal_visible=true
	game.sim.player.pos=Vector2(1800,1320);game.sim.player.hp=1850;game.sim.level=4
	game.camera.position=Vector2(1720,1180);game.camera.zoom=Vector2.ONE*.96
	var npc=game.sim.npcs[0];npc.pos=game.sim.player.pos+Vector2(260,70);npc.home=npc.pos
	game.sim.npcs.clear();game.sim.npcs.append(npc);game.sim.select(npc.id)
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,405),Vector2i(1560,720)]:
		root.size=dimensions
		game.camera.position=game.sim.player.pos
		game.camera.zoom=Vector2.ONE*(.78 if dimensions.y<560 else .96)
		await _shot(game,output,"hud-%dx%d" % [dimensions.x,dimensions.y])
		game._open_modal("Munition")
		await _shot(game,output,"ammo-%dx%d" % [dimensions.x,dimensions.y])
		game.modal.hide();game.modal_backdrop.hide()
	root.size=Vector2i(1560,720)
	game._set_display(2,false);game.modal.hide();game.modal_backdrop.hide()
	await _shot(game,output,"hud-large-1560x720")
	game._open_modal("Anzeige")
	await _shot(game,output,"display-1560x720")
	game._set_display(1,true);game.modal.hide();game.modal_backdrop.hide()
	root.size=Vector2i(1280,720)
	game.sim.npcs.clear();game.sim.drops.clear();game.sim.player.pos=game.sim.portals[0].pos-Vector2(220,0)
	game.camera.position=game.sim.portals[0].pos;game.camera.force_update_scroll()
	await _shot(game,output,"portal-before")
	var point: Vector2=game.get_canvas_transform()*game.sim.portals[0].pos
	var down=InputEventScreenTouch.new();down.index=0;down.position=point;down.pressed=true
	var up=InputEventScreenTouch.new();up.index=0;up.position=point;up.pressed=false
	game.suppress_tap_until=0;game._unhandled_input(down);game._unhandled_input(up)
	var queued=game.sim.pending_portal==1
	var steps=0
	for _i in 300:
		steps+=1;game.sim.step(1.0/30.0)
		if game.sim.map_id==1:break
	game._process(0)
	await _shot(game,output,"portal-after")
	var receipt=FileAccess.open(output+"/portal-touch.json",FileAccess.WRITE)
	receipt.store_string(JSON.stringify({"queued_by_touch":queued,"map":game.sim.map_id,"pending":game.sim.pending_portal,"steps":steps,"camera_synced":game.camera.position==game.sim.player.pos}));receipt.close()
	if not queued or game.sim.map_id!=1:push_error("Portal capture did not complete its actual crossing");quit(1);return
	print(JSON.stringify({"status":"CAPTURED","hud_sizes":4,"portal_touch_crossing":true}))
	quit()
