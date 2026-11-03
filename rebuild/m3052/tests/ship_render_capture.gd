extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var output="user://ship-render"
	var page=0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
		if arg.begins_with("--page="):page=int(arg.trim_prefix("--page="))
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,900 if page in [3,4] else (2120 if page==0 else 1720))
	var game=load("res://sea_map.tscn").instantiate()
	game.gallery_page=page
	root.add_child(game)
	current_scene=game
	await process_frame
	game.camera.enabled=false
	game.ui.hide()
	game.water.material=null
	game.water.color=Color("102b38")
	game.modal_backdrop.hide()
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	var error=root.get_texture().get_image().save_png(output+"/ships_page_%d.png"%page)
	if error!=OK:push_error("Ship gallery capture failed");quit(1);return
	root.get_texture().get_image().save_jpg(output+"/ships_page_%d.jpg"%page,0.92)
	print(JSON.stringify({"status":"CAPTURED","page":page,"renderer":"sea_map._draw_actor","waterline_markers":true}))
	quit()
