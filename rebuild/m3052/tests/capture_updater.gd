extends SceneTree
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var output="user://updater-captures"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(844,390)
	var scene=load("res://updater/launcher.tscn").instantiate();scene.autostart=false;root.add_child(scene)
	await process_frame
	DirAccess.make_dir_recursive_absolute(output)
	for state in ["checking","downloading","permission"]:
		scene.updater.progress=0.42
		var text="Neue Version wird gesucht …" if state=="checking" else ("Update lädt · 42 %" if state=="downloading" else "Updates für diese App in Android erlauben, dann hier fortsetzen.")
		scene.updater._set(state,text)
		for i in 3:await process_frame
		await RenderingServer.frame_post_draw
		var error=root.get_texture().get_image().save_png(output+"/"+state+".png")
		if error!=OK:quit(1);return
	print(JSON.stringify({"status":"CAPTURED","scene":"updater/launcher.tscn","fixture_states":true,"network":"simulated"}))
	quit()
