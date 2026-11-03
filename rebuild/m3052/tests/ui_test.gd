extends SceneTree
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
	check(game.skins.size()==27,"all 27 ship designs including Small Starter are selectable")
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
		for nav: Button in game.nav_buttons:check(label_fits(nav),"navigation caption fits without clipping: "+nav.text+" at "+str(dimensions))
		var controls: Array=[game.attack,game.repair,game.zoom_in,game.zoom_out,game.center_button,game.interact,game.loadout_button,game.ammo_selector]
		controls.append_array(game.ammo_buttons)
		for control: Control in controls:
			var rect=control.get_global_rect()
			check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=dimensions.x+1 and rect.end.y<=dimensions.y+1,"touch control inside viewport %s"%dimensions)
		for i in controls.size():
			for j in range(i+1,controls.size()):
				check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()),"independent touch targets %s / %s at %s"%[controls[i].name,controls[j].name,dimensions])
		check(not game.player_panel.get_global_rect().intersects(game.target_panel.get_global_rect()),"player and target cards do not overlap")
		var center_water=Rect2(Vector2(dimensions)*.5-Vector2(80,120),Vector2(160,185))
		var clear_center=true
		for control: Control in [game.player_panel,game.target_panel,game.chart_mini,game.combat_dock,game.attack,game.repair,game.ammo_selector,game.quest_panel,game.interact]:
			clear_center=clear_center and not control.get_global_rect().intersects(center_water)
		check(clear_center,"HUD reserves clear water around the centered player at "+str(dimensions))
		check(game.player_portrait.texture!=null and game.target_portrait.texture!=null,"player and selected NPC show actual ship portraits")
		check(game.attack.get_global_rect().position.x>dimensions.x*.7 and game.combat_dock.get_global_rect().encloses(game.ammo_buttons[0].get_global_rect()),"round fire control stays on the right and quick ammunition stays in the lower deck")
		game.loadout_button.pressed.emit()
		check(game.modal_kind=="Bewaffnung" and game.modal.visible,"quick weapons control opens real ammunition and cannon information")
		game.modal.hide()
		game._open_modal("Werft")
		await process_frame
		check(game.modal_scroll.size.y>100 and game.modal_scroll.get_v_scroll_bar().max_value>game.modal_scroll.size.y,"shipyard uses actual scrollable content")
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
	game.ammo_buttons[1].pressed.emit()
	check(game.sim.ammo_mode==1,"ammo UI selects actual chain ammunition")
	game._refresh_ui()
	check("Kettenkugeln" in game.ammo_buttons[1].text and "✓" in game.ammo_buttons[1].text,"selected ammunition has a visible type label and selection marker")
	game.sim.player.gold=543
	game._save_progress()
	game.sim.player.gold=0
	game._load_progress()
	check(int(game.sim.player.gold)==543 and int(game.sim.player.skin)==8,"guest save reloads wallet and ship design")
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,405)]:
		root.size=dimensions
		await process_frame
		game._layout()
		for kind in ["Hafen","Logbuch","Seekarten"]:
			game._open_modal(kind)
			await process_frame
			check(game.modal.visible and game.modal_scroll.size.y>100,"new gameplay panel opens at %s: %s"%[dimensions,kind])
			check(game.modal.get_global_rect().end.x<=dimensions.x+1 and game.modal.get_global_rect().end.y<=dimensions.y+1,"panel stays inside viewport: "+kind)
			check(game.modal_close.get_global_rect().end.x<=game.modal.get_global_rect().end.x,"close control stays inside panel: "+kind)
	game.modal.hide()
	game.sim.player.pos=game.sim.harbor
	game.sim.player.last_hit=-100
	game._interact()
	check(game.sim.docked and game.modal_kind=="Hafen","harbor interaction opens actual docked equipment")
	game.sim.player.gold=1000
	game._open_modal("Hafen")
	var purchases=game.modal_body.find_children("*","Button",true,false)
	var upgraded=false
	for button: Button in purchases:
		if button.text=="VERBESSERN · 150 Gold":
			button.pressed.emit()
			upgraded=true
			break
	check(upgraded and int(game.sim.upgrades.cannon)==1 and int(game.sim.player.gold)==850,"equipment UI purchases real cannon upgrade")
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
		if button.text=="LADEN" and not button.disabled:button.pressed.emit();loaded=true;break
	check(loaded and game.sim.ammo_mode==1 and not game.modal.visible,"ammunition popup loads actual chain stock and closes")
	game.system_tab.pressed.emit()
	check(game.system_label.visible and not game.quest_text.visible,"system tab displays actual game messages")
	game.quest_tab.pressed.emit()
	check(game.quest_text.visible and not game.system_label.visible,"quest tab restores the live quest tracker")
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
	game._load_progress()
	check(game.sim.map_id==1,"automatic portal arrival is saved to the captain file")
	# Exercise preferences through the actual settings callbacks at every supported size.
	var captain_before: Dictionary=game.sim.export_save()
	for dimensions in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(844,390),Vector2i(720,405)]:
		root.size=dimensions
		await process_frame
		for preset in 3:
			game._set_display(preset,true)
			await process_frame;await process_frame
			check(game.modal_kind=="Anzeige" and game.modal.visible,"display settings remain usable after changing scale")
			check(game.modal.get_global_rect().position.x>=0 and game.modal.get_global_rect().end.x<=dimensions.x+1 and game.modal.get_global_rect().end.y<=dimensions.y+1,"scaled settings panel fits %s preset %d" % [dimensions,preset])
			game.modal.hide()
			var touch: Array=[game.attack,game.repair,game.ammo_selector,game.center_button,game.zoom_in,game.zoom_out,game.loadout_button]
			touch.append_array(game.ammo_buttons)
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
	game._set_display(1,true);game.modal.hide()
	root.size=Vector2i(1560,720);await process_frame;game._layout()
	check(game.attack.get_global_rect().size.x>=140,"comfortable wide-phone layout has a larger primary attack button")
	var result={"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
