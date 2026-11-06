extends SceneTree
const MINI=preload("res://minimap.gd")
var failures: Array[String]=[]
var count:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:failures.append(label)
func label_fits(button: Button) -> bool:
	var font=button.get_theme_font("font")
	var skin=button.get_theme_stylebox("normal")
	var available=button.size.x-skin.get_content_margin(SIDE_LEFT)-skin.get_content_margin(SIDE_RIGHT)
	return font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x<=available+1
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	check(game.ship_textures.size()==10 and game.atlas_textures.size()==16,"ten own ship designs and sixteen directional reference atlases loaded")
	check(game.skins.size()==30,"27 original ship designs plus three playable GLB test ships are listed")
	check(game.mesh_layer!=null and game.mesh_layer.has_complete_fleet(),"all nine actual Meshy GLB PackedScenes import and instantiate")
	check(str(game.skins[27].mesh_key)=="crimson_voyager" and str(game.skins[28].mesh_key)=="test_ship_2" and str(game.skins[29].mesh_key)=="base_basic_pbr","red starter and both boss test GLBs have dedicated shipyard slots")
	for skin_id in [27,28,29]:
		var key: String=game.TEST_SHIP_KEYS[skin_id-27]
		check(game.mesh_layer.has_test_ship(skin_id),"M3083 player GLB is actually imported: "+key)
		check(game.test_ship_textures.has(key),"M3083 genuine 8-direction sprite exported: "+key)
		check(game.skin_previews[skin_id]!=null and game.skin_previews[skin_id]==game.TEST_SHIP_PREVIEWS[key],"M3083 genuine shipyard preview exported: "+key)
	var fresh=game.SIM.new()
	check(int(fresh.player.skin)==27,"new captains begin on the red Crimson Voyager")
	var fresh_save=fresh.export_save()
	fresh.player.skin=29
	check(fresh.restore_save(fresh.export_save()) and int(fresh.player.skin)==29,"large test ship survives captain save and restore")
	fresh.player.skin=27
	check(fresh.restore_save(fresh_save) and int(fresh.player.skin)==27,"red starter survives saving and loading")
	# Verify real physical bow direction for both Z-long originals and red X-long
	# starter, at all eight map bearings. This catches 180-degree import errors.
	for model_key in ["crimson_voyager","test_ship_2","base_basic_pbr"]:
		for course in [Vector2.RIGHT,Vector2(1,1).normalized(),Vector2.DOWN,Vector2(-1,1).normalized(),Vector2.LEFT,Vector2(-1,-1).normalized(),Vector2.UP,Vector2(1,-1).normalized()]:
			check(game.mesh_layer.forward_for_model(model_key,course).distance_to(course)<0.001,"M3084 GLB physical prow points in the direction of travel: "+model_key+" "+str(course))
	var slow_player_turn: float=game.mesh_layer.smooth_player_yaw(0.0,PI,1.0/60.0)
	check(absf(slow_player_turn)>0.0 and absf(slow_player_turn)<=deg_to_rad(285.0)/60.0+0.001,"M3084 player ship steering is responsive but cannot instantly flip 180 degrees")
	var mode_before_anchor: String=game.mesh_layer.mode
	game.mesh_layer.set_render_mode("3d")
	var skin_before_anchor: int=int(game.sim.player.skin)
	game.sim.player.skin=29
	var player_center: Vector2=game.get_canvas_transform()*game._visual_actor_pos(game.sim.player)
	var title_anchor: Vector2=game._plate_screen_anchor(game.sim.player)
	check(title_anchor.y>player_center.y and title_anchor.y-player_center.y<=47.0*game._plate_pixels(),"M3084 3D captain name stays close to the actual ship keel")
	game.sim.player.skin=skin_before_anchor
	game.mesh_layer.set_render_mode(mode_before_anchor)
	check(game.mesh_layer.mode in ["classic","hybrid","3d"],"game has a valid 2.5D or 3D mode")
	# Turn rate is limited and converges smoothly across all heading changes.
	var test_yaw: float=game.mesh_layer.smooth_yaw(0.0,PI*.5,1.0/30.0)
	check(test_yaw>0.0 and test_yaw<=deg_to_rad(110.0)/30.0+0.0001,"3D NPC turn is capped instead of snapping 90 degrees")
	for turn_step in 120:test_yaw=game.mesh_layer.smooth_yaw(test_yaw,PI*.5,1.0/60.0)
	check(absf(angle_difference(test_yaw,PI*.5))<0.005,"smoothing converges within 0.3 degrees of the physical GLB bow direction")
	# All nine original Meshy GLBs are X-long with the physical bowsprit at
	# LOCAL -X (not +X). The simulation heading is in 2D chart coordinates,
	# which map to world (X,Z); verify nose-first travel at all eight angles.
	for key in ["old_harbor_trader","merchant_brig_3002","merchant_brig_2921","merchant_brig_2912","weathered_voyager","weathered_junk","emerald_voyager","midnight_mariner","crimson_tide_galley"]:
		check(game.mesh_layer.model_scenes.has(key),"3D ship orientation contract includes "+key)
	for course in [
		Vector2.RIGHT,Vector2(1,1).normalized(),Vector2.DOWN,
		Vector2(-1,1).normalized(),Vector2.LEFT,Vector2(-1,-1).normalized(),
		Vector2.UP,Vector2(1,-1).normalized()
	]:
		var yaw: float=game.mesh_layer.yaw_for_heading(course)
		var local_bow: Vector3=Vector3(-1,0,0).rotated(Vector3.UP,yaw)
		var world_course:=Vector2(local_bow.x,local_bow.z).normalized()
		check(world_course.distance_to(course)<0.001,"3D GLB physical bow matches simulated course "+str(course))
	check(game.render_toggle is Button and game.render_toggle.visible,"graphics switch exists directly on the chart beside the minimap")
	check(game.render_toggle.text.begins_with("GRAFIK"),"graphics switch shows its currently selected mode")
	check(game._active_data_revision()>=0,"display menu reports exact active signed data revision")
	var before_mode: String=game.render_mode
	game.mesh_layer.set_render_mode("hybrid")
	check(game.mesh_layer.can_render_actor(game.sim.npcs[0]),"hybrid 2.5D renders an actual GLB, not a directional image")
	game.mesh_layer.set_render_mode("3d")
	check(game.mesh_layer.can_render_actor(game.sim.npcs[0]),"3D mode shares the NPC model and simulation")
	game.mesh_layer.set_render_mode("classic")
	check(not game.mesh_layer.can_render_actor(game.sim.npcs[0]),"classic 2.5D sprite fallback remains available")
	game.mesh_layer.set_render_mode(before_mode)
	check(game.CONTENT.NPC_MESHY_ROSTER.size()==9,"nine approved NPC visual designs and roles")
	check(game.sim.npcs.filter(func(npc):return npc.kind=="ship").size()==16,"original sixteen ship spawn points are retained")
	for npc in game.sim.npcs:
		if str(npc.kind)!="ship":continue
		check(game.CONTENT.NPC_MESHY_ROSTER.any(func(entry):return str(entry.key)==str(npc.visual_key)),"NPC has a valid Meshy model key")
		check(game._npc_ship_texture(npc) is Texture2D,"NPC has an imported 4-angle texture or safe fallback")
		check(int(npc.hp)==int(npc.max_hp) and int(npc.shield)==int(npc.max_shield),"NPC health and shield initialize correctly")
	for key in ["cannon","armor","hunter","navigation","logistics","tide","storm","salvage","blessing"]:
		check(game.deck_icons.has(key) and game.deck_icons[key] is Texture2D,"original nautical SVG icon loads for "+key)
	check(game.attack.has_method("_press_visual"),"combat orb has tap-feedback animation")
	check(game._actor_visual_length(game.sim.npcs[14])<game._actor_visual_length(game.sim.npcs[12])*0.7,"elite pinnace stays visibly smaller than a non-elite galleon")
	var previous_skin: int=game.sim.player.skin
	game.sim.player.skin=24
	check(is_equal_approx(game._actor_visual_length(game.sim.player),game._actor_visual_length(game.sim.npcs[14])),"player and NPC versions of the same hull use the same visible size")
	game.sim.player.skin=previous_skin
	check(game._starter_texture(2400,2400)==game.starter_texture,"full HP selects actual intact starter texture")
	check(game._starter_texture(600,2400)==game.starter_damaged_texture,"low HP selects actual damaged starter texture")
	check(game._starter_texture(2400,2400)==game.starter_texture,"repair returns actual texture to intact without stale damage cache")
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,405)]:
		root.size=dimensions
		await process_frame
		game._layout()
		game.sim.select(2)
		game._refresh_ui()
		check(game.nav_buttons.size()==9,"top bar carries nine sea-chart menus")
		for nav: Button in game.nav_buttons:
			check(label_fits(nav),"navigation caption fits without clipping: "+nav.text+" at "+str(dimensions))
			check(nav.get_global_rect().position.x>=game.gold_label.get_global_rect().end.x and nav.get_global_rect().end.x<=game.player_hp.get_global_rect().position.x,"navigation stays between wallet and captain meters at "+str(dimensions))
		var controls: Array=[game.attack,game.repair,game.zoom_in,game.zoom_out,game.center_button,game.settings_button,game.render_toggle,game.interact,game.loadout_button,game.ammo_selector,game.camera_pad,game.target_cycle,game.supply_buttons.powder]
		for item: Button in game.supply_buttons.values():
			if item not in controls:controls.append(item)
		for control: Control in controls:
			var rect=control.get_global_rect()
			check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=dimensions.x+1 and rect.end.y<=dimensions.y+1,"touch control inside viewport %s"%dimensions)
		for i in controls.size():
			for j in range(i+1,controls.size()):
				check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()),"independent touch targets %s / %s at %s"%[controls[i].name,controls[j].name,dimensions])
		check(not game.quest_panel.get_global_rect().intersects(game.target_panel.get_global_rect()),"quest bar and target card do not overlap")
		check(game.quest_panel.size.y<=44 and not game.quest_panel.get_global_rect().intersects(game.camera_pad.get_global_rect()),"quest bar stays a compact strip clear of the joystick at "+str(dimensions))
		var center_water=Rect2(Vector2(dimensions)*.5-Vector2(80,120),Vector2(160,185))
		var clear_center=true
		var surroundings: Array=[game.chrome,game.target_panel,game.chart_mini,game.quest_panel,game.interact]
		surroundings.append_array(controls)
		for control: Control in surroundings:
			clear_center=clear_center and not control.get_global_rect().intersects(center_water)
		check(clear_center,"HUD reserves clear water around the centered player at "+str(dimensions))
		check(game.target_portrait.texture!=null,"selected NPC shows its actual ship portrait")
		var hub: Vector2=game.attack.get_global_rect().get_center()
		var ring=true
		for orb: Control in [game.ammo_selector,game.repair,game.supply_buttons.powder,game.supply_buttons.repair_kit,game.supply_buttons.shield_charge,game.supply_buttons.plates]:
			var offset: Vector2=orb.get_global_rect().get_center()-hub
			ring=ring and offset.length()<game.attack.get_global_rect().size.x*1.65
		check(game.attack.get_global_rect().position.x>dimensions.x*.7 and ring,"cannon stays bottom-right with ammunition and repair within thumb reach")
		check(game.loadout_button.get_global_rect().end.x<game.ammo_selector.get_global_rect().position.x and is_equal_approx(game.loadout_button.get_global_rect().position.y,game.ammo_selector.get_global_rect().position.y),"utility slots continue the bottom row left of the cannon")
		check(str(game.attack.get("art").resource_path).ends_with("cannon_action.png") and game.attack.get("hero"),"fire control uses the dedicated cannon graphic")
		check(game.player_hp.get_parent()==game.chrome and game.player_xp.get_parent()==game.chrome and game.player_shield.get_parent()==game.chrome,"captain experience, hull and shield meters sit in the top bar")
		check(game.player_shield.get_global_rect().position.y>=game.player_hp.get_global_rect().end.y-1 and game.player_shield.get_global_rect().end.y<=game.chrome.get_global_rect().end.y+1,"shield meter stacks below hull inside the top bar at "+str(dimensions))
		check(game.supply_buttons.values().all(func(item):return item.visible),"all supplies stay directly available beside the single ammunition selector")
		check(game.chart_mini.get_global_rect().encloses(Rect2(game.zoom_in.get_global_rect().get_center(),Vector2.ONE)) and game.chart_mini.get_global_rect().encloses(Rect2(game.settings_button.get_global_rect().get_center(),Vector2.ONE)),"map controls sit on the chart frame corners")
		var details=game.target_numbers.get_rect()
		var card=game.target_panel.size
		check(details.position.x>=-1 and details.position.y>=-1 and details.end.x<=card.x+1 and details.end.y<=card.y+1,"target details stay inside the target card")
		if dimensions.y<560:check(not game.status.get_global_rect().intersects(center_water),"status stays off the centered ship on short displays")
		game.loadout_button.pressed.emit()
		check(game.modal_kind=="Bewaffnung" and game.modal.visible,"quick weapons control opens real ammunition and cannon information")
		game.modal.hide()
		game._open_modal("Werft")
		await process_frame
		check(game.modal_scroll.size.y>100 and game.modal_scroll.get_v_scroll_bar().max_value>game.modal_scroll.size.y,"shipyard uses actual scrollable content")
		var yard:=0
		for button in game.modal_body.find_children("*","Button",true,false):
			if "AUSRÜSTEN" in button.text or "AKTIV" in button.text:yard+=1
		check(yard==30,"shipyard shows one card for each original and new test design")
		game.modal.hide()
	root.size=Vector2i(1280,720)
	await process_frame
	game._layout();game._open_modal("Hafen")
	check(game.modal_scroll.position.x>=18 and game.modal_scroll.get_rect().end.y<=game.modal.size.y-18,"menu has an inset safe scroll area")
	game.sim.player.pos=game.sim.portals[0].pos
	check(not game._landmark_label_visible(game.sim.player.pos),"actual portal suppresses overlapping caption beneath captain name")
	game.sim.player.pos=game.sim.START
	var hp=int(game.sim.player.hp)
	var gold=int(game.sim.player.gold)
	var position: Vector2=game.sim.player.pos
	game._equip(8)
	check(int(game.sim.player.skin)==8 and int(game.sim.player.hp)==hp and int(game.sim.player.gold)==gold and game.sim.player.pos==position,"equipping design preserves position, hull and wallet")
	game.modal.hide()
	game.sim.select(2)
	game._toggle_fire()
	check(game.sim.firing,"fire control changes actual simulation state")
	check(label_fits(game.attack),"active fire stop action is fully readable at compact size")
	game.sim.player.hp=1000;game.sim.player.last_hit=-100
	game.repair.pressed.emit();game._refresh_ui()
	check(label_fits(game.repair),"active repair stop action is fully readable at compact size")
	game.repair.pressed.emit();game._refresh_ui()
	game._open_modal("Munition");game.ammo_rows[1].pressed.emit()
	check(game.sim.ammo_mode==1,"ammo UI selects actual chain ammunition")
	game._refresh_ui()
	check("Kettenkugeln" in game.ammo_selector.text and str(game.ammo_selector.get("quantity"))==str(game.sim.player.ammo[1]),"selected ammunition has a visible type label and selection marker")
	game.sim.player.gold=543
	game._save_progress()
	game.sim.player.gold=0
	game._load_progress()
	check(int(game.sim.player.gold)==543 and int(game.sim.player.skin)==8,"guest save reloads wallet and ship design")
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,405)]:
		root.size=dimensions
		await process_frame
		game._layout()
		for kind in ["Hafen","Logbuch","Seekarten","Kessel","Bonuskarten","Gilde","Kastelle","Decks","Schiff","Munition"]:
			game._open_modal(kind)
			if kind in ["Hafen","Kessel","Gilde"]:await process_frame
			check(game.modal.visible and game.modal_scroll.size.y>100,"new gameplay panel opens at %s: %s"%[dimensions,kind])
			check(game.modal.get_global_rect().position.x>=0 and game.modal.get_global_rect().position.y>=0 and game.modal.get_global_rect().end.x<=dimensions.x+1 and game.modal.get_global_rect().end.y<=dimensions.y+1,"panel stays inside viewport: "+kind)
			check(game.modal_close.get_global_rect().end.x<=game.modal.get_global_rect().end.x,"close control stays inside panel: "+kind)
	game.modal.hide()
	game.sim.player.pos=game.sim.harbor
	game.sim.player.last_hit=-100
	game._interact()
	check(game.sim.docked and game.modal_kind=="Hafen","harbor interaction opens actual docked equipment")
	game.sim.player.gold=1000
	game._open_modal("Hafen")
	var castles_link=false
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text.begins_with("KASTELLE"):button.pressed.emit();castles_link=true;break
	check(castles_link and game.modal_kind=="Kastelle","harbor links to the castle yard")
	var purchases=game.modal_body.find_children("*","Button",true,false)
	var upgraded=false
	for button: Button in purchases:
		if button.text=="VERBESSERN · 150 Gold":
			button.pressed.emit()
			upgraded=true
			break
	check(upgraded and int(game.sim.upgrades.cannon)==1 and int(game.sim.player.gold)==850,"castle UI purchases real Bugkastell upgrade")
	game._open_modal("Hafen")
	var stocked=false
	var powder_before=int(game.sim.supplies.powder)
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text.begins_with("10× Schwarzpulver"):button.pressed.emit();stocked=true;break
	check(stocked and int(game.sim.supplies.powder)==powder_before+10 and int(game.sim.player.gold)==790,"harbor UI buys a real pack of black powder")
	game.sim.essence=6;game.kessel_log.clear()
	game._open_modal("Kessel")
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text=="×5":button.pressed.emit();break
	check(game.sim.essence==1 and game.kessel_log.size()>=5 and game.modal_kind=="Kessel","cauldron UI throws five essence and logs every result")
	var throw_one: Button=null
	game.sim.essence=0;game._open_modal("Kessel")
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text=="×1":throw_one=button
	check(throw_one!=null and throw_one.disabled,"cauldron throw stays disabled without essence")
	game._interact()
	check(not game.sim.docked and not game.modal.visible,"departure interaction closes harbor and resumes sea")
	game.sim.kills=3
	game._open_modal("Logbuch")
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text=="BELOHNUNG ABHOLEN":
			button.pressed.emit()
			break
	check(game.sim.quest_index==1 and game.sim.level>=2,"logbook claim advances quest and actual captain level")
	game.sim.player.pos=game.sim.portals[0].pos
	game.sim.player.last_hit=-100
	game._navigate_region(1)
	check(game.sim.map_id==1 and game.camera.position==game.sim.player.pos,"map UI switches simulation, recenters camera and saves")
	game._advance_loading(5.0)
	game._load_progress()
	check(game.sim.map_id==1 and game.sim.upgrades.cannon==1,"new map and equipment survive UI save reload")
	game._open_modal("Werft")
	await process_frame;await process_frame
	game.modal_scroll.scroll_vertical=300
	await process_frame
	game._open_modal("Werft")
	await process_frame;await process_frame
	check(game.modal_scroll.scroll_vertical>=299,"refreshing visible shipyard preserves the current scroll position")
	game.modal.hide();game._open_modal("Werft")
	await process_frame;await process_frame
	check(game.modal_scroll.scroll_vertical==0,"reopening a closed menu starts at its beginning")
	game.modal_scroll.scroll_vertical=300
	game._open_modal("Logbuch")
	await process_frame;await process_frame
	check(game.modal_scroll.scroll_vertical==0,"changing menus resets scroll instead of opening half-way down")
	root.size=Vector2i(720,405)
	await process_frame
	game._layout();game._open_modal("Bewaffnung")
	await process_frame;await process_frame
	root.size=Vector2i(1280,720)
	await process_frame
	game._layout();game._open_modal("Hafen")
	await process_frame;await process_frame
	check(game.modal_scroll.get_rect().end.x<=game.modal.size.x-18,"compact-to-wide menu transition keeps content inside the frame")
	var menu_bounds=true
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		menu_bounds=menu_bounds and button.get_global_rect().end.x<=game.modal_scroll.get_global_rect().end.x+1
	check(menu_bounds,"actual harbor buttons stay inside the scroll viewport after resize")
	game.modal.hide();game.ammo_selector.pressed.emit()
	await process_frame;await process_frame
	check(game.modal_kind=="Munition" and game.modal.visible,"round ammo selector opens the live contextual ammunition list")
	game.sim.set_ammo(0);game._open_modal("Munition")
	var loaded=false
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.has_meta("ammo_index") and int(button.get_meta("ammo_index"))==1:button.pressed.emit();loaded=true;break
	check(loaded and game.sim.ammo_mode==1 and not game.modal.visible,"ammunition popup loads actual chain stock and closes")
	game._refresh_ui();game.quest_open.pressed.emit()
	var logged=false
	for label: Label in game.modal_body.find_children("*","Label",true,false):logged=logged or game.sim.message in label.text
	check(game.modal_kind=="Logbuch" and logged,"quest bar opens the logbook with the latest real game message")
	game._open_modal("Rangliste")
	var ranked=false
	for label: Label in game.modal_body.find_children("*","Label",true,false):ranked=ranked or ("Versenkte Schiffe %d" % game.sim.kills) in label.text
	check(ranked,"ranking shows the captain's actual record")
	game.modal.hide()
	check(MINI.row_name(0)=="A" and MINI.row_name(26*MINI.SQUARE)=="AA" and MINI.column_name(0)=="1","chart rulers name rows by letters and columns by numbers")
	game.sim.configure_map(0);game.previous_region=0;game.sim.level=4;game.sim.player.hp=game.sim.player.max_hp;game.sim.player.last_hit=-100;game.sim.docked=false
	game.sim.npcs.clear();game.sim.player.pos=game.sim.portals[0].pos-Vector2(220,0)
	game.sim.player.path=[]
	var hud_down=InputEventScreenTouch.new();hud_down.index=7;hud_down.position=game.player_hp.get_global_rect().get_center();hud_down.pressed=true
	var hud_up=InputEventScreenTouch.new();hud_up.index=7;hud_up.position=hud_down.position;hud_up.pressed=false
	game._unhandled_input(hud_down);game._unhandled_input(hud_up)
	check(game.sim.player.path.is_empty() and game.sim.pending_portal==-1,"touching HUD health does not leak a movement or portal command into the sea")
	game.suppress_tap_until=0
	game.camera.position=game.sim.portals[0].pos;game.camera.force_update_scroll()
	var screen: Vector2=game.get_canvas_transform()*game.sim.portals[0].pos
	var down=InputEventScreenTouch.new();down.index=0;down.position=screen;down.pressed=true
	var up=InputEventScreenTouch.new();up.index=0;up.position=screen;up.pressed=false
	game._unhandled_input(down);game._unhandled_input(up)
	check(game.sim.pending_portal==1 and not game.sim.player.path.is_empty(),"touching the rendered portal queues a real crossing")
	for _i in 120:
		game.sim.step(1.0/30.0)
		if game.sim.map_id!=0:break
	game._process(0)
	check(game.sim.map_id==1 and game.camera.position==game.sim.player.pos and game.previous_region==1,"touch-to-arrival crossing switches region, recenters camera and synchronizes scene")
	check(game.loading.visible and "Nordmeer" in str(game.loading.region) and not str(game.loading.tip).is_empty(),"region change shows the chart loading screen with destination and tip")
	var path_before: Array=game.sim.player.path.duplicate()
	game._tap(game.get_viewport_rect().size*.5)
	check(game.sim.player.path==path_before,"taps during the loading screen do not set a course")
	game._advance_loading(5.0)
	check(not game.loading.visible and is_equal_approx(game.loading.progress,1.0),"loading screen completes and reveals the new sea")
	game._load_progress()
	check(game.sim.map_id==1,"automatic portal arrival is saved to the captain file")
	# Exercise preferences through the actual settings callbacks at every supported size.
	# Buff timers and shield regeneration advance with sea time, so the sea pauses while only display options change.
	game.set_process(false)
	var captain_before: Dictionary=game.sim.export_save()
	for dimensions in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(844,390),Vector2i(720,405)]:
		root.size=dimensions
		await process_frame
		for preset in 3:
			game._set_display(preset,true)
			await process_frame;await process_frame
			check(game.modal_kind=="Anzeige" and game.modal.visible,"display settings remain usable after changing scale")
			check(game.modal.get_global_rect().position.x>=0 and game.modal.get_global_rect().end.x<=dimensions.x+1 and game.modal.get_global_rect().end.y<=dimensions.y+1,"scaled settings panel fits %s preset %d" % [dimensions,preset])
			check(game.modal_scroll.get_global_rect().end.x<=game.modal.get_global_rect().end.x-10,"scaled scroll container stays inside the menu frame")
			for button: Button in game.modal_body.find_children("*","Button",true,false):
				check(button.get_global_rect().end.x<=game.modal_scroll.get_global_rect().end.x+1,"display option stays inside the scaled scroll viewport")
			game.modal.hide()
			var touch: Array=[game.attack,game.repair,game.ammo_selector,game.center_button,game.settings_button,game.zoom_in,game.zoom_out,game.loadout_button,game.camera_pad,game.target_cycle,game.supply_buttons.powder]
			for item: Button in game.supply_buttons.values():
				if item not in touch:touch.append(item)
			for control: Control in touch:
				var bounds=control.get_global_rect()
				check(bounds.position.x>=0 and bounds.position.y>=0 and bounds.end.x<=dimensions.x+1 and bounds.end.y<=dimensions.y+1,"scaled touch target remains inside viewport")
			for i in touch.size():
				for j in range(i+1,touch.size()):check(not touch[i].get_global_rect().intersects(touch[j].get_global_rect()),"scaled touch targets remain independent")
			check(game.water.size==Vector2(dimensions),"HUD scaling does not resize ocean or world coordinates")
			check(game._hud_contains(game.player_hp.get_global_rect().get_center()),"scaled HP hit testing uses viewport coordinates")
	game._set_display(2,false)
	game.hud_size=0;game.journal_visible=true;game._load_display();game._layout()
	check(game.hud_size==2 and not game.quest_panel.visible,"HUD size and journal visibility survive reload")
	check(game.sim.export_save()==captain_before,"display choices preserve all captain progress")
	game.set_process(true)
	game._set_display(1,true);game.modal.hide()
	root.size=Vector2i(1560,720);await process_frame;game._layout()
	check(game.attack.get_global_rect().size.x>=140,"comfortable wide-phone layout has a larger primary attack button")
	check(game.attack.get_global_rect().size.x>game.ammo_selector.get_global_rect().size.x*2,"cannon dominates the combat corner on wide phones")
	check(str(game.ammo_selector.get("quantity"))==game._thousands(int(game.sim.player.ammo[game.sim.ammo_mode])),"single ammunition selector shows the actual selected stock")
	game.sim.configure_map(0);game.sim.islands.clear();game.sim.docked=false;game.sim.player.hp=2400
	game.sim.player.pos=Vector2(2100,2000);game.sim.player.reload=0;game.sim.ammo_mode=0;game.sim.player.ammo[0]=30
	game.sim.player.path=[]
	game.sim.npcs.clear();game.sim.npcs.append(game.sim.base_npcs[0].duplicate(true))
	var victim: Dictionary=game.sim.npcs[0];victim.pos=game.sim.player.pos+Vector2(200,0);victim.hp=victim.max_hp
	game.sim.select(victim.id);game._refresh_ui()
	check(str(game.attack.get("state_label"))=="BEREIT","fire button reports a real reachable ship with loaded cannon ammunition")
	var stock: int=game.sim.player.ammo[0]
	game._refresh_ui();game._refresh_ui()
	check(int(game.sim.player.ammo[0])==stock,"refreshing readiness never consumes ammunition")
	victim.pos=game.sim.player.pos+Vector2(700,0);game._refresh_ui()
	check(str(game.attack.get("state_label"))=="ZU WEIT" and game.sim.player.path.is_empty(),"range warning does not issue an automatic pursuit course")
	victim.pos=game.sim.player.pos+Vector2(200,0);game.sim.set_ammo(2);game._refresh_ui()
	check(str(game.attack.get("state_label"))=="WAFFE WECHSELN","ship selected with harpoons gives a weapon warning before firing")
	game.sim.set_ammo(0);game.sim.player.ammo[0]=2;game._refresh_ui()
	check(str(game.attack.get("state_label"))=="MUNITION LEER","cannon readiness requires stock for all three shots in a volley")
	game.sim.player.ammo[0]=30;game.sim._fire_player();game._refresh_ui()
	check(int(game.sim.player.ammo[0])==27 and str(game.attack.get("state_label")).begins_with("LÄDT"),"actual volley consumes three rounds and drives the reload display")
	game.sim.docked=true;game._refresh_ui()
	check(game.attack.disabled and str(game.attack.get("state_label"))=="IM HAFEN","docked state is visible on the disabled attack control")
	# Actual joystick touch ownership, cancellation and camera-only movement.
	game.sim.docked=false;game.sim.player.path=[];game.modal.hide()
	game._recenter_camera()
	var before_pos: Vector2=game.sim.player.pos
	var before_stock: Array=game.sim.player.ammo.duplicate()
	var pad_down=InputEventScreenTouch.new();pad_down.index=31;pad_down.pressed=true;pad_down.position=game.camera_pad.size*.5+Vector2(30,0)
	game.camera_pad._gui_input(pad_down)
	check(game.camera_pad.value.x>.9,"owning touch moves the camera pad to the right")
	var second=InputEventScreenTouch.new();second.index=32;second.pressed=true;second.position=Vector2.ZERO
	game.camera_pad._gui_input(second);second.pressed=false;game.camera_pad._gui_input(second)
	check(game.camera_pad.touch_id==31 and game.camera_pad.value.x>.9,"another finger cannot steal or release the camera pad")
	game._pan_camera(game.camera_pad.value,.25)
	check(game.pan.x>0 and game.sim.player.pos==before_pos and game.sim.player.path.is_empty() and game.sim.player.ammo==before_stock,"camera pan leaves ship position, course and ammunition untouched")
	check(game._hud_contains(game.camera_pad.get_global_rect().get_center()),"joystick area is protected from tap-to-sail")
	pad_down.pressed=false;game.camera_pad._gui_input(pad_down)
	check(game.camera_pad.value==Vector2.ZERO and game.camera_pad.touch_id==-1,"owning finger release returns the joystick to neutral")
	pad_down.pressed=true;game.camera_pad._gui_input(pad_down);game._open_modal("Anzeige")
	check(game.camera_pad.value==Vector2.ZERO,"opening a menu releases a held camera control")
	game.modal.hide()
	pad_down.pressed=true;game.camera_pad._gui_input(pad_down)
	game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(game.camera_pad.value==Vector2.ZERO,"losing window focus releases held joystick input")
	game.center_button.pressed.emit()
	check(game.pan==Vector2.ZERO and game.camera_locked,"recenter button restores ship following and releases joystick")
	game._pan_camera(Vector2(1,1),100)
	var destination: Vector2=game.sim.player.pos+game.pan
	check(destination.x>=0 and destination.y>=0 and destination.x<=game.sim.WORLD.x and destination.y<=game.sim.WORLD.y,"camera pad clamps its destination to the chart")
	game._recenter_camera()
	game._pan_camera(Vector2.RIGHT,.2);game.camera_pad.release()
	var view_anchor: Vector2=game.sim.player.pos+game.pan
	game.camera.position=view_anchor;game.sim.player.pos+=Vector2(100,0);game.sim.firing=false;game.previous_region=game.sim.map_id
	game._process(.1)
	check(game.camera.position.distance_to(view_anchor)<.01,"released camera remains on the inspected chart location while the ship changes position")
	game.sim.player.pos=before_pos;game._recenter_camera()
	game.camera_pad_visible=false;game._set_display(1,true)
	game.camera_pad_visible=true;game._load_display();game._layout()
	check(not game.camera_pad.visible,"camera joystick preference survives reload")
	game.camera_pad_visible=true;game._set_display(1,true);game.modal.hide()
	# Cycle through visible, living targets without arming a volley or altering a course.
	game.camera.position=game.sim.player.pos;game.camera.force_update_scroll()
	game.sim.npcs.clear()
	for i in 4:
		var npc: Dictionary=game.sim.base_npcs[i].duplicate(true)
		npc.pos=game.sim.player.pos+Vector2(-150+i*100,-40);npc.hp=npc.max_hp
		if i==2:npc.hp=0
		if i==3:npc.pos=game.get_canvas_transform().affine_inverse()*game.quest_panel.get_global_rect().get_center()
		game.sim.npcs.append(npc)
	game.sim.target=-1;game.sim.firing=true
	var first_id: int=game.sim.npcs[0].id
	var second_id: int=game.sim.npcs[1].id
	game.target_cycle.pressed.emit()
	check(game.sim.target==first_id and not game.sim.firing,"cycle selects first visible live ship and stops ongoing fire")
	game.target_cycle.pressed.emit();check(game.sim.target==second_id,"cycle advances to the next visible ship")
	game.target_cycle.pressed.emit();check(game.sim.target==first_id,"cycle wraps and skips sunk ships and targets behind HUD")
	check(game.sim.player.pos==before_pos and game.sim.player.ammo==before_stock and game.sim.player.path.is_empty(),"target cycling consumes no ammunition and starts no pursuit")
	game.sim.npcs.clear();game.target_cycle.pressed.emit()
	check(game.sim.message=="Kein Ziel im sichtbaren Bereich","empty view gives clear feedback without a fake target")
	root.size=Vector2i(720,405);await process_frame;game._layout()
	check(game.quest_panel.visible and game.camera_pad.visible and not game.quest_panel.get_global_rect().intersects(game.camera_pad.get_global_rect()),"short phone layout keeps the quest bar top-left and the joystick bottom-left")
	check(game.camera_pad.get("steering")==null and not game.has_method("_steer"),"design lock: the joystick has no ship-steering mode")
	# Quick-bar items act on the real simulation.
	game.modal.hide();game.sim.docked=false;game.sim.player.hp=1200;game.sim.player.last_hit=-100;game.sim.powder_on=false
	game.sim.supplies.powder=4;game._refresh_ui()
	game.supply_buttons.powder.pressed.emit()
	check(game.sim.powder_on and int(game.sim.supplies.powder)==4 and game.supply_buttons.powder.get("latched"),"powder orb toggles black powder without spending it")
	game.supply_buttons.powder.pressed.emit()
	check(not game.sim.powder_on,"powder orb switches black powder off again")
	check(game.supply_buttons.repair_kit.visible and game.ammo_selector.visible,"emergency repair and ammunition remain directly available")
	var kits=int(game.sim.supplies.repair_kit)
	game.supply_buttons.repair_kit.pressed.emit()
	check(int(game.sim.supplies.repair_kit)==kits-1 and int(game.sim.player.hp)>1200 and float(game.sim.cooldowns.repair_kit)>0 and game.supply_buttons.repair_kit.get("cooldown")>0,"emergency repair heals once and shows its own cooldown")
	game.repair.pressed.emit()
	check(int(game.sim.supplies.repair_kit)==kits-1,"basic repair never consumes an emergency item")
	game.sim.repairing=false
	check(game.ammo_selector.visible and game.supply_buttons.repair_kit.visible,"using supplies does not hide the ammunition selector")
	# Guild founding and the bonus map run entirely through the menus.
	game.sim.player.gold=1000;game._open_modal("Gilde")
	game.guild_name_input.text="Sturmkrone";game.guild_tag_input.text="skr"
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text.begins_with("GILDE GRÜNDEN"):button.pressed.emit();break
	check(str(game.sim.guild.get("tag",""))=="SKR" and int(game.sim.player.gold)==700 and game.modal_kind=="Gilde","guild UI founds a local guild with a validated tag")
	var labelled=false
	for label: Label in game.modal_body.find_children("*","Label",true,false):labelled=labelled or "lokal" in label.text
	check(labelled,"guild panel labels the preview as local, not online")
	game.sim.configure_map(0);game.previous_region=0;game.sim.player.pos=game.sim.START;game.sim.level=4;game.sim.scrolls=[1,0,0];game.sim.bonus={}
	game._open_modal("Bonuskarten")
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text=="STARTEN" and not button.disabled:button.pressed.emit();break
	check(game.sim.map_id==3 and game.previous_region==3 and int(game.sim.scrolls[0])==0,"bonus UI spends a scroll and opens Bronzeriff")
	game._advance_loading(5.0);game._refresh_ui()
	check(game.interact.visible and game.interact.text=="BONUSKARTE VERLASSEN" and "WELLE 1/5" in game.quest_text.text and not game.sim.has_harbor(),"bonus map shows its wave tracker and an exit instead of a harbor")
	game._interact()
	check(game.sim.map_id==0 and game.previous_region==0 and not game.sim.bonus.is_empty(),"leaving a bonus map returns to the origin and keeps the checkpoint")
	game._advance_loading(5.0)
	# Dispatch through the viewport, including release outside the joystick hit box.
	game.camera_pad_visible=true;game.modal.hide();root.size=Vector2i(1280,720)
	await process_frame;game._layout();game.sim.player.path=[]
	var routed=InputEventScreenTouch.new();routed.index=55;routed.pressed=true;routed.position=game.camera_pad.get_global_rect().get_center()
	root.push_input(routed,true);await process_frame
	check(game.camera_pad.touch_id==55,"viewport routes actual screen touch into the scaled joystick")
	var routed_drag=InputEventScreenDrag.new();routed_drag.index=55;routed_drag.position=routed.position+Vector2(180,0);routed_drag.relative=Vector2(180,0)
	root.push_input(routed_drag,true);await process_frame
	check(game.camera_pad.value.x>.9,"owning finger remains captured when dragged outside the joystick")
	routed.pressed=false;routed.position=routed_drag.position;root.push_input(routed,true);await process_frame
	check(game.camera_pad.value==Vector2.ZERO and game.sim.player.path.is_empty(),"outside release stops camera input without leaking a sailing command")
	# A finger drag that starts on a shipyard button scrolls the list and never equips the design.
	root.size=Vector2i(1280,720);await process_frame;game._layout();game.modal.hide()
	game._open_modal("Werft");await process_frame;await process_frame
	var skin_before: int=int(game.sim.player.skin)
	var yard_button: Button=null
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if "AUSRÜSTEN" in button.text and not button.disabled:yard_button=button;break
	check(yard_button!=null,"shipyard still offers a design that is not equipped")
	if yard_button!=null:
		var origin: Vector2=yard_button.get_global_rect().get_center()
		var emulated=InputEventMouseButton.new();emulated.device=-1;emulated.button_index=MOUSE_BUTTON_LEFT;emulated.pressed=true;emulated.position=origin
		var finger=InputEventScreenTouch.new();finger.index=9;finger.pressed=true;finger.position=origin
		root.push_input(emulated,true);root.push_input(finger,true);await process_frame
		var slide=InputEventScreenDrag.new();slide.index=9;slide.position=origin+Vector2(0,-90);slide.relative=Vector2(0,-90)
		root.push_input(slide,true);await process_frame;await process_frame
		finger.pressed=false;finger.position=slide.position;root.push_input(finger,true)
		emulated.pressed=false;emulated.position=slide.position;root.push_input(emulated,true);await process_frame
		check(game.modal_scroll.scroll_vertical>0 and int(game.sim.player.skin)==skin_before,"dragging across a shipyard button scrolls and does not equip")
		game.modal.hide();game._open_modal("Werft");await process_frame;await process_frame
		for button: Button in game.modal_body.find_children("*","Button",true,false):
			if "AUSRÜSTEN" in button.text and not button.disabled:
				game.modal_scroll.ensure_control_visible(button)
				await process_frame
				var tap_at: Vector2=button.get_global_rect().get_center()
				var tap_mouse=InputEventMouseButton.new();tap_mouse.device=-1;tap_mouse.button_index=MOUSE_BUTTON_LEFT;tap_mouse.pressed=true;tap_mouse.position=tap_at
				var tap_finger=InputEventScreenTouch.new();tap_finger.index=9;tap_finger.pressed=true;tap_finger.position=tap_at
				root.push_input(tap_mouse,true);root.push_input(tap_finger,true);await process_frame
				tap_finger.pressed=false;root.push_input(tap_finger,true)
				tap_mouse.pressed=false;root.push_input(tap_mouse,true);await process_frame;await process_frame
				break
		check(int(game.sim.player.skin)!=skin_before,"a tap without movement still equips the shipyard design")
	# Staff tools, the world chart and the chart guide.
	var map_before: int=game.sim.map_id
	game.modal.hide();game._open_modal("Staff");await process_frame
	check(not game.sim.staff.active() and game.staff_code_input!=null and not game.modal_tabs.visible,"staff window opens on the local sign-in form")
	game.staff_code_input.text="ADMIN-3060"
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text=="ANMELDEN":button.pressed.emit();break
	await process_frame
	check(game.sim.staff.active() and game.sim.staff.role=="ADMIN" and game.modal_tabs.visible and game.modal_tabs.get_child_count()==7,"admin code opens the staff tools and their tabs")
	for tab: Button in game.modal_tabs.get_children():
		if tab.text=="TELEPORT":tab.pressed.emit();break
	await process_frame
	var jumped=false
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text.begins_with("2-1") and not button.disabled:button.pressed.emit();jumped=true;break
	await process_frame
	check(jumped and game.sim.map_id==1,"staff teleport changes the sea from the map list")
	game._advance_loading(5.0)
	game.modal_tab["Staff"]="ÜBERSICHT"
	game._open_modal("Staff");await process_frame
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text.begins_with("ABMELDEN · ZURÜCKSETZEN"):button.pressed.emit();break
	await process_frame
	check(not game.sim.staff.active() and game.sim.map_id==map_before,"signing out with restore returns the sea to the state before the staff session")
	game._advance_loading(5.0);game.modal.hide()
	game._open_modal("Seekarten");await process_frame;await process_frame
	var chart=game.modal_body.get_node_or_null("WorldChart")
	check(chart!=null and chart.sim==game.sim and chart.parchment!=null,"world chart is drawn from the live simulation and the parchment")
	for tab: Button in game.modal_tabs.get_children():
		if tab.text=="ANLEITUNG":tab.pressed.emit();break
	await process_frame;await process_frame
	var guide_modes: Array[String]=[]
	for child in game.modal_body.get_children():
		if child.get_script()==load("res://chart_guide.gd"):guide_modes.append(str(child.mode))
	check(guide_modes==["grid","colors","legend"],"chart guide draws the square grid, name colours and minimap legend")
	game.modal.hide()
	var result={"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)

