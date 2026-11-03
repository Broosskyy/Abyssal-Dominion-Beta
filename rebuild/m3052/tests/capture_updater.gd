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
		scene.updater.set_status(state,text)
		for i in 3:await process_frame
		await RenderingServer.frame_post_draw
		for control: Control in [scene.action,scene.play]:
			if not control.visible:continue
			var rect=control.get_global_rect()
			if rect.size.x<100 or rect.size.y<44 or rect.position.x<0 or rect.position.y<0 or rect.end.x>844 or rect.end.y>390:
				push_error("Updater action outside capture: "+str(rect));quit(1);return
		print(JSON.stringify({"fixture":state,"panel":str(scene.panel.get_global_rect()),"play":str(scene.play.get_global_rect())}))
		var error=root.get_texture().get_image().save_png(output+"/"+state+".png")
		if error!=OK:quit(1);return
	print(JSON.stringify({"status":"CAPTURED","scene":"updater/launcher.tscn","fixture_states":true,"network":"simulated"}))
	quit()
