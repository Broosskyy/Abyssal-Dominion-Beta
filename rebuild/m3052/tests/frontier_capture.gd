extends SceneTree
var output:="/tmp/abyssal-frontier-captures"
func _initialize() -> void:call_deferred("_run")
func shot(name: String) -> void:
	for _i in 4:await process_frame
	await RenderingServer.frame_post_draw
	var error: int=root.get_texture().get_image().save_png(output+"/"+name+".png")
	if error!=OK:push_error("Capture failed");quit(1)
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(2340,1080)
	var hub=load("res://start_hub.tscn").instantiate();root.add_child(hub);await process_frame
	await shot("01_welcome_landscape")
	hub._show("auth");await shot("02_login")
	hub._enter_home();await shot("03_home")
	hub._process(1.0);await shot("03b_home_water_motion")
	hub._show("rewards");await shot("04_rewards")
	root.size=Vector2i(844,390);await process_frame;hub._show("home");await shot("05_home_small_phone")
	root.size=Vector2i(1080,2340);await process_frame;hub._show("welcome");await shot("06_welcome_portrait")
	hub.queue_free();await process_frame
	root.size=Vector2i(2340,1080)
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);await process_frame
	game.set_process(false);game.sim.captain_name="Broosskyy";game.sim.guild={"name":"Tiefseewacht","tag":"TSW"};game.sim.level=20
	game.sim.player.pos=game.sim.harbor+Vector2(70,90);game._recenter_camera();game.camera.position=game.sim.harbor;game.camera.force_update_scroll();game._sync_plate_overlay();game.queue_redraw()
	await shot("07_harbor_and_profile")
	game._open_modal("Verbrauch");await shot("08_consumables")
	game._open_modal("Seekarten");await shot("09_maps_40")
	game.modal_tab["Anzeige"]="STEUERUNG";game._open_modal("Anzeige");await shot("10_settings")
	game.sim.configure_map(2);game.sim.fortress_hold=100;game.modal.hide();game.modal_backdrop.hide();game._refresh_ui();game.chart_mini.queue_redraw()
	game.camera.position=game.sim.fortress_island().bounds.get_center();game.camera.force_update_scroll();game._sync_plate_overlay();game.queue_redraw()
	await shot("11_guild_island")
	game.elapsed=1.0;game.queue_redraw();await shot("11b_guild_island_motion")
	game._open_modal("Gilde");await shot("12_tower_upgrades")
	root.size=Vector2i(844,390);await process_frame;game._open_modal("Verbrauch");await shot("13_consumables_small_phone")
	root.size=Vector2i(1080,2340);await process_frame;game._open_modal("Profil");await shot("14_profile_portrait")
	game.queue_free();await process_frame
	print(JSON.stringify({"status":"CAPTURED","count":16,"renderer":RenderingServer.get_video_adapter_name()}));quit()
