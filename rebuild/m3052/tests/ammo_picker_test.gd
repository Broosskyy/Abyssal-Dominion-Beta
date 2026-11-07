extends SceneTree
const SIM=preload("res://simulation.gd")
var checks:=0
var failures: Array[String]=[]
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false);game.elapsed=2.0
	var sim=game.sim
	sim.player.path=[];sim.player.ammo=[100,100,100,100,100,100,100]
	var stock: Array=sim.player.ammo.duplicate();var wallet=int(sim.player.gold)
	check(game.find_children("SpecialAmmo*","Button",true,false).is_empty(),"four separate special-ammunition buttons are absent")
	check(game.find_children("Ammo0","Button",true,false).is_empty() and game.find_children("PageButton","Button",true,false).is_empty(),"one selector replaces the old quick slots and page control")
	for dimensions in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(844,390),Vector2i(720,405),Vector2i(2340,1080)]:
		root.size=dimensions;await process_frame
		for profile in 3:
			game.hud_size=profile;game._layout();game._refresh_ui()
			game.ammo_selector.pressed.emit()
			for _i in 4:await process_frame
			var rect=game.modal.get_global_rect()
			check(game.modal.visible and game.modal.plain and game.ammo_rows.size()==7,"selector opens a plain seven-sort list at %s / %d" % [dimensions,profile])
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(rect) and rect.position.y>=game.chrome.get_global_rect().end.y,"ammunition list fits below the header on %s / %d" % [dimensions,profile])
			check(rect.end.y<game.ammo_selector.get_global_rect().position.y and game.modal_backdrop.color.a==0,"list is anchored above the button without darkening the sea")
			var controls: Array=[game.attack,game.repair,game.ammo_selector,game.target_cycle,game.loadout_button,game.chart_mini,game.camera_pad]
			controls.append_array(game.supply_buttons.values())
			var clear=true
			for i in controls.size():
				for j in range(i+1,controls.size()):clear=clear and not controls[i].get_global_rect().intersects(controls[j].get_global_rect())
			check(clear,"single-selector combat layout has independent controls at %s / %d" % [dimensions,profile])
			game._close_ammo()
	for index in 7:
		game.ammo_selector.pressed.emit()
		check(game.ammo_rows[index].get_meta("ammo_index")==index,"list includes ammunition sort %d" % index)
		game.ammo_rows[index].pressed.emit()
		check(sim.ammo_mode==index and not game.modal.visible,"choosing sort %d activates it and closes the list" % index)
		check(game.ammo_selector.get("art")==game._ammo_texture(index) and str(game.ammo_selector.get("quantity"))=="100","active button shows the chosen icon and stock %d" % index)
		game.ammo_selector.pressed.emit();await process_frame
		check(game.ammo_rows[index].get("loaded"),"reopening highlights the actual selected sort %d" % index)
		game._close_ammo()
	check(sim.player.ammo==stock and int(sim.player.gold)==wallet and sim.player.path.is_empty(),"selection never spends stock/gold or issues a course")
	sim.player.ammo[6]=0;game._choose_ammo(6)
	check(sim.ammo_mode==6 and str(game.ammo_selector.get("quantity"))=="0","empty stock remains truthful on the selected button")
	var fresh=SIM.new()
	check(fresh.restore_save(sim.export_save()) and fresh.ammo_mode==6,"active ammunition survives a save and reload")
	# A real volley uses the chosen special rounds and refreshes the one stock counter.
	sim.docked=false;sim.player.hp=sim.player.max_hp;sim.player.pos=Vector2(500,500);sim.player.reload=0
	var victim=sim.base_npcs[0].duplicate(true);victim.pos=Vector2(700,500);victim.home=victim.pos
	sim.npcs.clear();sim.npcs.append(victim);sim.select(victim.id)
	game._choose_ammo(3);sim._fire_player();game._refresh_ui()
	check(sim.player.ammo[3]==99 and str(game.ammo_selector.get("quantity"))=="99" and sim.shots.size()==1,"actual special shot consumes one round and updates the selector")
	var reload: float=sim.player.reload
	game.ammo_selector.pressed.emit();game.ammo_rows[4].pressed.emit()
	check(sim.ammo_mode==4 and sim.player.reload==reload,"switching ammunition does not bypass a real reload")
	check(game.suppress_tap_until>Time.get_ticks_msec() and sim.player.path.is_empty(),"closing the list guards against touch-release sailing")
	check(ThemeDB.fallback_font.multichannel_signed_distance_field,"scaled HUD and world text use a distance-field font")
	check(game.FINAL_SHIP_PREVIEW.get_image().has_mipmaps(),"final shipyard preview exports as filtered texture")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
