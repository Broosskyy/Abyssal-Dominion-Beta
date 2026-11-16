extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	var output="/tmp/abyssal-browser-captures"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):output=argument.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(output)
	var game=load("res://sea_map.tscn").instantiate()
	game.browser_classic=true
	root.add_child(game)
	current_scene=game
	game.set_process(false)
	game.sim.player.pos=Vector2(2400,1800)
	game.sim.player.path=[]
	game.camera.position=game.sim.player.pos
	game.camera.zoom=Vector2.ONE
	var retained: Array[Dictionary]=[]
	for actor: Dictionary in game.sim.npcs:
		if int(actor.id) in [1,100]:retained.append(actor)
	game.sim.npcs=retained
	game.sim.npcs[0].pos=game.sim.player.pos+Vector2(220,80)
	game.sim.npcs[1].pos=game.sim.player.pos+Vector2(-250,-30)
	game.sim.target=1
	for dimensions in [Vector2i(1280,720),Vector2i(852,393)]:
		root.size=dimensions
		await process_frame
		game._layout()
		for direction in [0,2,4]:
			game.sim.player.heading=Vector2.UP.rotated(float(direction)*PI*.25)
			game.sim.player.skin=0 if direction!=4 else 1
			game.camera.force_update_scroll()
			game._sync_plate_overlay()
			game._refresh_ui()
			game.queue_redraw()
			for frame in 3:await process_frame
			await RenderingServer.frame_post_draw
			var filename="%dx%d-heading%d.png" % [dimensions.x,dimensions.y,direction]
			root.get_texture().get_image().save_png(output+"/"+filename)
	# M383 UI visual proof: screenshot the SAME real game with (1) every
	# independently unlocked ornament and (2) ONLY the Mojo bone frame.
	# Test-only equipment fixture; no automatic gifts in player saves.
	root.size=Vector2i(852,393)
	await process_frame
	game._layout()
	game.sim.player.skin=0
	game.sim.player.heading=Vector2.RIGHT
	for key: String in game.sim.DECK_EXTENSION_KEYS:
		game.sim.deck_extensions[key]=true
	game.camera.force_update_scroll()
	game._sync_plate_overlay()
	game.queue_redraw()
	for frame in 3:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/852x393-modular-all.png")
	for key: String in game.sim.DECK_EXTENSION_KEYS:
		game.sim.deck_extensions[key]=key=="mojo_frame"
	game._sync_plate_overlay()
	game.queue_redraw()
	for frame in 3:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/852x393-mojo-only.png")
	# M384: photograph the ACTUAL interactive Decks/VORSCHAU menu with
	# all six individual SVG layers toggled, then the completely empty
	# preview. Neither state is saved or given to the player.
	for key: String in game.sim.DECK_EXTENSION_KEYS:
		game.sim.deck_extensions[key]=false
	game._open_modal("Decks")
	game._switch_tab("Decks","VORSCHAU")
	game._set_all_deck_previews(true)
	game._layout()
	game._sync_plate_overlay()
	for frame in 4:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/852x393-deck-preview-all.png")
	game._set_all_deck_previews(false)
	game._sync_plate_overlay()
	for frame in 4:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/852x393-deck-preview-none.png")
	game._close_modal()
	# The test fixture must not mutate actual persisted player equipment.
	var motion: Dictionary=await preload("res://tests/ocean_motion_probe.gd").run(self)
	print(JSON.stringify(motion))
	var monsters: Dictionary=await preload("res://tests/monster_motion_probe.gd").run(self)
	print(JSON.stringify(monsters))
	print("BROWSER_CAPTURES_READY "+output)
	quit(0 if motion.status=="PASS" and monsters.status=="PASS" else 1)
