extends SceneTree
## Mobile-first HUD polish must improve touch sizes without changing
## navigation, saved courses, rendering mode, or the working 2D raster.
var checks: int=0
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false)
	var course: Array=game.sim.player.path.duplicate(true)
	var origin: Vector2=game.sim.player.pos
	var mode: String=game.render_mode
	var expected_zoom: float=game.desired_zoom
	for screen in [Vector2i(720,405),Vector2i(844,390),Vector2i(1280,720)]:
		root.size=screen
		await process_frame
		game._layout()
		await process_frame
		var m: bool=game._is_mobile_hud(Vector2(screen),true)
		game.quick_bar.mobile_first=m
		game.quick_bar._layout()
		for i in 3:
			check(game.quick_bar.tabs[i].size.x>=44.0 and game.quick_bar.tabs[i].size.y>=44.0,"page button remains at least 44 logical px on "+str(screen))
		check(game.quick_bar.edit.size.x>=44.0 and game.quick_bar.edit.size.y>=44.0,"configure button expanded from 28px to 44px on "+str(screen))
		for i in 3:
			check(not game.quick_bar.tabs[i].get_rect().intersects(game.quick_bar.edit.get_rect()),"page tabs cannot overlap configure control on "+str(screen))
		for control: Control in [game.zoom_in,game.zoom_out,game.center_button,game.settings_button,game.render_toggle]:
			check(control.size.y>=44.0 and control.size.x>=40.0,"corner/graphics touch control is >=44px high on "+str(screen)+": "+control.name)
			check(control.get_global_rect().position.x>=0 and control.get_global_rect().end.x<=screen.x+1 and control.get_global_rect().position.y>=0 and control.get_global_rect().end.y<=screen.y+1,"corner/graphics target remains inside screen "+str(screen)+": "+control.name)
		game.sim.select(2)
		game._refresh_ui()
		check(game.target_clear.size.x>=44.0 and game.target_clear.size.y>=44.0,"target cancel is independently finger-sized on "+str(screen))
		check(not game.target_clear.get_rect().intersects(game.target_portrait.get_rect()),"cancel cannot cover target portrait on "+str(screen))
		for kind in ["Menü","Markt","Decks","Munition","Verbrauch"]:
			game._open_modal(kind)
			check(game.modal_close.size.x>=44.0 and game.modal_close.size.y>=44.0,"visible modal close button is >=44px for "+kind+" "+str(screen))
			check(game.modal_back.size.y>=44.0,"modal back button is >=44px for "+kind+" "+str(screen))
			check(not game.modal_close.get_global_rect().intersects(game.modal_title.get_global_rect()),"modal title does not overlap close button for "+kind+" "+str(screen))
			check(not game.modal_back.get_global_rect().intersects(game.modal_title.get_global_rect()),"modal title does not overlap back button for "+kind+" "+str(screen))
			check(game.modal_scroll.size.y>90.0,"scrollable item content preserved for "+kind+" "+str(screen))
		game._close_modal()
	check(game.sim.player.pos==origin and game.sim.player.path==course and game.render_mode==mode and is_equal_approx(game.desired_zoom,expected_zoom),"polishing doesn't alter movement, render mode or zoom")
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
