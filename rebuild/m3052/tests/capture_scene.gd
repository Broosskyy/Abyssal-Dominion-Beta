extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var output="user://captures"
	var dimensions=Vector2i(1280,720)
	var combat=false
	var yard=false
	var demo=false
	var harbor=false
	var maps=false
	var north=false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
		if arg=="--mobile":dimensions=Vector2i(844,390)
		if arg=="--combat":combat=true
		if arg=="--yard":yard=true
		if arg=="--demo":demo=true
		if arg=="--harbor":harbor=true
		if arg=="--maps":maps=true
		if arg=="--north":north=true
	root.content_scale_size=Vector2i.ZERO
	root.size=dimensions
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game._layout()
	if combat:
		game.sim.select(2)
		game.sim.firing=true
	if yard:game._open_modal("Werft")
	if north:
		game.sim.configure_map(1)
		game.sim.level=3
	if harbor:
		game.sim.player.pos=game.sim.harbor
		game.camera.position=game.sim.player.pos
		game.sim.player.gold=1200
		game.sim.dock()
		game._open_modal("Hafen")
	if maps:game._open_modal("Seekarten")
	game._refresh_ui()
	DirAccess.make_dir_recursive_absolute(output)
	for i in (420 if demo else 180):
		await process_frame
		if demo and i==230:
			game.sim.course(game.sim.npcs[1].pos)
		if demo and i==350:
			game.sim.select(100)
			game.sim.set_ammo(2)
			game.sim.firing=true
		if i in [20,60,100,140,179]:
			await RenderingServer.frame_post_draw
			var error=root.get_texture().get_image().save_png(output+"/frame_%03d.png"%i)
			if error!=OK:push_error("Capture save failed")
	print(JSON.stringify({"status":"CAPTURED","output":output,"size":[dimensions.x,dimensions.y],"visible_projectiles":game.drawn_shots,"kills":game.sim.kills,"gold":game.sim.player.gold}))
	quit()
