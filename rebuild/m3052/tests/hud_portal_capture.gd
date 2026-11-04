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
		var frame: Rect2=game.modal.get_global_rect()
		print(JSON.stringify({"capture":name,"frame":str(frame),"scroll":str(bounds),"body":str(game.modal_body.get_global_rect())}))
		if bounds.end.x>frame.end.x-10:
			push_error("Scroll container expands beyond modal frame: "+name);quit(1);return
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
	var captain_before: Vector2=game.sim.player.pos
	var stick=InputEventScreenTouch.new();stick.index=12;stick.pressed=true;stick.position=game.camera_pad.size*.5+Vector2(30,0)
	game.camera_pad._gui_input(stick);game._pan_camera(game.camera_pad.value,.45)
	game.camera.position=game.sim.player.pos+game.pan;game.camera.force_update_scroll()
	await _shot(game,output,"camera-pan-1560x720")
	var pad_receipt=FileAccess.open(output+"/camera-pad.json",FileAccess.WRITE)
	pad_receipt.store_string(JSON.stringify({"touch_owned":game.camera_pad.touch_id==12,"camera_offset":game.pan.length(),"ship_unchanged":game.sim.player.pos==captain_before}));pad_receipt.close()
	if game.pan.length()<50 or game.sim.player.pos!=captain_before:push_error("Camera-only joystick acceptance failed");quit(1);return
	game._recenter_camera();game.camera.position=game.sim.player.pos
	game.sim.player.reload=.9
	await _shot(game,output,"combat-reload-1560x720")
	game.sim.player.reload=0
	game._open_modal("Anzeige")
	await _shot(game,output,"display-1560x720")
	game._set_display(1,true);game.modal.hide();game.modal_backdrop.hide()
	root.size=Vector2i(1280,720)
	game.sim.configure_map(0);game.previous_region=0;game.sim.docked=false;game.sim.bonus={}
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
	game._advance_loading(0.7)
	await _shot(game,output,"loading-1280x720")
	game._advance_loading(5.0)
	await _shot(game,output,"portal-after")
	var receipt=FileAccess.open(output+"/portal-touch.json",FileAccess.WRITE)
	receipt.store_string(JSON.stringify({"queued_by_touch":queued,"map":game.sim.map_id,"pending":game.sim.pending_portal,"steps":steps,"camera_synced":game.camera.position==game.sim.player.pos}));receipt.close()
	if not queued or game.sim.map_id!=1:push_error("Portal capture did not complete its actual crossing");quit(1);return
	var systems=await _systems(game,output)
	if not systems.ok:push_error("Seafight systems capture failed: "+JSON.stringify(systems));quit(1);return
	print(JSON.stringify({"status":"CAPTURED","hud_sizes":4,"portal_touch_crossing":true,"systems":systems}))
	quit()
func _systems(game: Node,output: String) -> Dictionary:
	var sim=game.sim
	root.size=Vector2i(1280,720)
	# Korsarenfestung with its four towers, first held by the corsairs, then by the captain's guild.
	sim.level=6;sim.player.hp=sim.player.max_hp;sim.player.last_hit=-100;sim.docked=false
	sim.configure_map(2);game.previous_region=2
	var island: Dictionary=sim.fortress_island()
	var anchor=Vector2(island.bounds.get_center().x,island.bounds.end.y+150)
	for step in 12:
		if not sim.blocked(anchor):break
		anchor.y+=40
	sim.player.pos=anchor;sim.player.path=[];sim.player.heading=Vector2.UP
	var towers: Array=[]
	for npc in sim.npcs:
		if npc.kind=="tower":towers.append(npc)
		elif npc.pos.distance_to(anchor)<900:npc.pos=npc.home+Vector2(1200,0)
	sim.select(int(towers[0].id))
	game.camera.position=(anchor+island.bounds.get_center())*.5;game.camera.zoom=Vector2.ONE*.82
	await _shot(game,output,"fortress-1280x720")
	sim.guild={"name":"Sturmkrone","tag":"SKR"};sim.fortress_hold=1500.0
	sim.activate_blessing(600.0);sim.add_tide_deck(1800.0);sim.powder_on=true
	game.quick_page=1;game._apply_page()
	await _shot(game,output,"guild-island-1280x720")
	var held=sim.tower_friendly() and sim.tower_tag()=="SKR"
	game.quick_page=0;game._apply_page();sim.powder_on=false
	# Harbor panels for the cauldron, bonus scrolls and the guild.
	sim.player.pos=sim.harbor;sim.docked=true;sim.essence=12;sim.fragments=7;sim.scrolls=[1,0,0]
	sim.throw_kessel(5,"2026-11-04")
	for kind in ["Kessel","Bonuskarten","Gilde","Kastelle","Decks"]:
		game._open_modal(kind)
		await _shot(game,output,"panel-%s-1280x720" % kind.to_lower())
	game.modal.hide();game.modal_backdrop.hide()
	# A real bronze run: scroll spent, wave one spawned on Bronzeriff.
	sim.depart();sim.player.pos=sim.START;sim.bonus={}
	var started: bool=sim.start_bonus(0)
	game._sync_region();game._advance_loading(5.0)
	for _i in 120:sim.step(1.0/30.0)
	var bonus_map: int=sim.map_id
	var wave: int=sim.bonus_wave_alive()
	for npc in sim.npcs:
		if bool(npc.get("wave",false)):
			npc.pos=sim.player.pos+(npc.pos-sim.player.pos).limit_length(380.0);sim.select(int(npc.id));break
	game.camera.position=sim.player.pos;game.camera.zoom=Vector2.ONE*.82
	await _shot(game,output,"bonus-wave-1280x720")
	root.size=Vector2i(720,405);game.camera.zoom=Vector2.ONE*.78
	await _shot(game,output,"bonus-wave-720x405")
	# Staff presence on the sea, the tools, the world chart, the guide, the ship window and a throw in flight.
	sim.leave_bonus();game._sync_region();game._advance_loading(5.0)
	root.size=Vector2i(1280,720);game.camera.zoom=Vector2.ONE*.96
	sim.staff_sign_in("ADMIN-3060");game._refresh_ui()
	sim.player.pos=sim.START;sim.player.heading=Vector2.RIGHT
	game.camera.position=sim.player.pos;game.camera.force_update_scroll()
	await _shot(game,output,"staff-badge-1280x720")
	game._open_modal("Staff")
	await _shot(game,output,"staff-overview-1280x720")
	game.modal_tab["Staff"]="TELEPORT";game._open_modal("Staff")
	await _shot(game,output,"staff-teleport-1280x720")
	game.modal.hide();game.modal_backdrop.hide()
	game._open_modal("Seekarten")
	await _shot(game,output,"world-chart-1280x720")
	game.modal_tab["Seekarten"]="ANLEITUNG";game._open_modal("Seekarten")
	await _shot(game,output,"chart-guide-1280x720")
	game._open_modal("Schiff")
	await _shot(game,output,"ship-window-1280x720")
	sim.docked=true;sim.essence=8
	game.kessel_throw={"start":Time.get_ticks_msec()-180,"results":[{"icon":game.painted.gold_coins,"rarity":3,"text":"Gold"},{"icon":game.painted.scroll_fragment,"rarity":1,"text":"Fragment"}]}
	game._open_modal("Kessel")
	await _shot(game,output,"kessel-throw-1280x720")
	var shown: bool=game.sim.staff.shows_badge() and game.staff_pill.visible and game.modal_body.get_node_or_null("KesselStage")!=null and game.modal_body.get_node_or_null("KesselStage").busy()
	sim.staff_sign_out(true);game.modal.hide();game.modal_backdrop.hide()
	return {"ok":towers.size()==4 and held and started and bonus_map==3 and wave>0 and shown,"towers":towers.size(),"guild_held":held,"bonus_started":started,"wave_ships":wave,"staff_badge":shown}
