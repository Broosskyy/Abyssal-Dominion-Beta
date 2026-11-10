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
	# Pick the rendered frame, including upper sails, at phone zoom levels.
	var originals: Array[Dictionary]=game.sim.npcs.duplicate(true)
	var water_cases: int=0
	for ship: Dictionary in originals:
		if str(ship.get("kind",""))!="ship":continue
		game.sim.npcs.clear()
		game.sim.npcs.append(ship)
		ship.pos=game.sim.player.pos+Vector2(250,0)
		for zoom in [.5,1.0,1.8]:
			game.camera.zoom=Vector2.ONE*zoom
			game.camera.force_update_scroll()
			for direction in 8:
				ship.heading=Vector2.UP.rotated(direction*PI*.25)
				var rect: Rect2=game._browser_ship_screen_rect(ship)
				check(rect.has_area(),"NPC has baked pick bounds: "+str(ship.visual_key))
				if not rect.has_area():continue
				check(game._enemy_at_screen(rect.get_center())==int(ship.id),"visible ship center selects at each heading and zoom")
				check(game._enemy_at_screen(Vector2(rect.get_center().x,rect.position.y+2))==int(ship.id),"upper sail area is selectable")
				var padding: Rect2=game._browser_ship_touch_rect(rect)
				check(padding.size.x>=68 and padding.size.y>=68,"small ships retain a phone-sized touch target")
				var outside: Vector2=Vector2(padding.end.x+3,padding.get_center().y)
				check(game._enemy_at_screen(outside)==-1,"water beside the frame is not captured by an oversized circle")
				var old_center: Vector2=game.get_canvas_transform()*(ship.pos-Vector2(0,25))
				if outside.distance_to(old_center)<clampf(game._actor_visual_length(ship)*zoom*.57,78.0,116.0):water_cases+=1
	check(water_cases>0,"regression covers water that the old hit circle incorrectly selected")
	game.sim.npcs=originals
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,405)]:
		root.size=dimensions
		await process_frame
		game._layout()
		game._refresh_ui()
		check(absf(game.captain_meters.get_global_rect().get_center().x-float(dimensions.x)*.5)<1.0,"browser captain HUD stays centered at "+str(dimensions))
		var meters: Array=[game.player_hp,game.player_shield,game.player_xp,game.player_bp]
		for index in meters.size():
			var rect: Rect2=meters[index].get_global_rect()
			check(meters[index].is_visible_in_tree() and rect.position.x>=0 and rect.end.x<=dimensions.x and rect.end.y<game.nav_scroll.get_global_rect().position.y,"browser progress meter remains visible above navigation")
			for other in range(index+1,meters.size()):check(not rect.intersects(meters[other].get_global_rect()),"browser progress bars never overlap")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
