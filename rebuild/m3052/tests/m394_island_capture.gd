extends SceneTree
## M394 render proof: actual A01 user-reference PNG as used inside the game.
## No mockup, no external image lookup, no Vercel deployment.
const CONTENT=preload("res://content.gd")
var folder:String="/tmp/m394-a01"
func _initialize()->void:
	call_deferred("_run")
func capture(name:String)->void:
	for _i in 5:await process_frame
	await RenderingServer.frame_post_draw
	var result:Error=root.get_texture().get_image().save_png(folder+"/"+name+".png")
	if result!=OK:
		push_error("A01 screenshot failed: "+name)
		quit(1)

func _run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):folder=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1440,900)
	var scene=load("res://sea_map.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.sim.level=20
	scene.sim.configure_map(CONTENT.realm_map_id(1))
	scene._sync_region()
	var island:Dictionary={}
	for current:Dictionary in scene.sim.islands:
		if str(current.get("m392_asset_id",""))=="A01" and int(current.get("realm_island_half",-1))==0:
			island=current
			break
	if island.is_empty() or str(island.art)!="m392_a01":
		push_error("A01 island is not gameplay-rendered")
		quit(1)
		return
	scene.modal.hide()
	scene.modal_backdrop.hide()
	var point:Vector2=Vector2(island.pos)
	scene.sim.player.pos=point+Vector2(float(island.width)*.8,float(island.width)*.5)
	if scene.sim.blocked(scene.sim.player.pos):scene.sim.player.pos=scene.sim._free_water(scene.sim.player.pos)
	scene.camera.position=point
	scene.camera.zoom=Vector2(1.0,1.0)
	scene.camera.force_update_scroll()
	scene._sync_plate_overlay()
	scene.queue_redraw()
	await capture("a01_island_landscape_in_game")
	root.size=Vector2i(844,390)
	scene.camera.zoom=Vector2(.85,.85)
	scene.camera.force_update_scroll()
	scene.queue_redraw()
	await capture("a01_island_mobile_in_game")
	print(JSON.stringify({"status":"CAPTURED","asset":"A01","map":scene.sim.map_id,"files":2,"texture":str(island.get("m392_texture_path",""))}))
	scene.queue_free()
	quit(0)
