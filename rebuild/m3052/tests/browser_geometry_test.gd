extends SceneTree
const VISUALS=preload("res://ship_visuals.gd")
var failures: Array[String]=[]
var count:=0
func check(ok: bool,message: String) -> void:
	count+=1
	if not ok:failures.append(message)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var path="res://assets/classic_baked/manifest.json"
	if not FileAccess.file_exists(path):
		print("FAIL: run tools/bake_web_fleet.gd first")
		quit(1)
		return
	var metadata: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	check(metadata.atlases.size()==23,"23 source hull/finish atlases")
	for entry: Dictionary in metadata.atlases:
		var reference: float=float(entry.reference_extent)
		var pivot: Vector2=Vector2.ZERO
		for index in 8:
			var frame: Dictionary=entry.frames[index]
			var spec: Dictionary=VISUALS.geometry(frame,180.0)
			var rect: Array=frame.rect
			var absolute_pivot=Vector2(float(frame.pivot[0])+float(rect[0])-index*256,float(frame.pivot[1])+float(rect[1]))
			if index==0:pivot=absolute_pivot
			check(pivot.distance_to(absolute_pivot)<.01,entry.name+" keeps water pivot across heading "+str(index))
			check(is_equal_approx(spec.scale,180.0/reference),entry.name+" shares a fixed scale across heading "+str(index))
			check(spec.destination.end.y<=float(entry.stable_bottom)*spec.scale+.01,entry.name+" hull clears its stable caption baseline")
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate()
	game.browser_classic=true
	root.add_child(game)
	current_scene=game
	await process_frame
	check(game.mesh_layer==null,"browser fleet uses no 3D runtime")
	check(game.classic_geometry.size()==23,"browser loads geometry metadata")
	for zoom in [.5,1.0,1.8]:
		game.camera.zoom=Vector2.ONE*zoom
		game.camera.force_update_scroll()
		for skin in [0,1,2,11,12,13]:
			game.sim.player.skin=skin
			var actor: Dictionary=game.sim.player
			var entry: Dictionary=game.classic_geometry[game._classic_atlas_key(actor)]
			var p: Vector2=game.get_canvas_transform()*game._visual_actor_pos(actor)
			var bottom: float=p.y+float(entry.stable_bottom)*game._actor_visual_length(actor)/float(entry.reference_extent)*zoom
			var anchor: Vector2=game._plate_screen_anchor(actor)
			check(is_equal_approx(anchor.y-bottom,22.0*game._plate_pixels()),"captain caption clears the baked hull at each zoom")
			for direction in 8:
				actor.heading=Vector2.UP.rotated(direction*PI*.25)
				check(anchor.distance_to(game._plate_screen_anchor(actor))<.01,"caption stays stable while the ship turns")
	check(float(game.classic_monster_bottoms.tiamat)<40.0,"monster caption uses visible atlas bounds instead of the old 72-unit gap")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
