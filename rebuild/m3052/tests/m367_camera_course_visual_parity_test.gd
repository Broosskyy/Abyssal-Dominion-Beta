extends SceneTree
## Mode contract: only course and physical sailing coordinates must match.
## Classic 2D may use independent camera framing and sprite raster animation
## while 3D remains centered on the vessel.
const VIS=preload("res://ship_visuals.gd")
var checks: int=0
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	game.sim.npcs.clear()
	game.sim.islands.clear()
	var world: Vector2=Vector2(1800,1800)
	game.sim.player.pos=world
	game.sim.player.path=[]
	game.visual_before.clear()
	game.visual_after.clear()
	for dims: Vector2i in [Vector2i(844,390),Vector2i(1280,720),Vector2i(2340,1080)]:
		root.size=dims
		await process_frame
		game._layout()
		var parity_zoom: float=game._sharp_zoom()
		var parity_hull: float=game._actor_visual_length(game.sim.player)
		for classic: bool in [false,true,false]:
			game.browser_classic=classic
			game.camera_locked=true
			var before_camera: Vector2=world+Vector2(330,-240)
			game.camera.position=before_camera
			game.camera.zoom=Vector2.ONE*parity_zoom
			var expected: Vector2=game._classic_edge_camera_goal(world,before_camera,Vector2(dims)/parity_zoom) if classic else world
			game._process(0.0)
			check(game.camera.position.distance_to(expected)<0.001,"Classic retains independent edge framing, native 3D centers captain on %s" % dims)
			if not classic:
				var screen_pos: Vector2=game.get_canvas_transform()*world
				check(screen_pos.distance_to(Vector2(dims)*0.5)<1.2,"3D keeps captain centered on %s" % dims)
			else:
				check(game.camera.position.distance_to(world)>1.0,"2D Classic camera no longer forced to follow 3D framing on %s" % dims)
			check(is_equal_approx(game._sharp_zoom(),parity_zoom) and is_equal_approx(game._actor_visual_length(game.sim.player),parity_hull),"shared current zoom and ship size preferences not changed by camera split on %s" % dims)
	# Leave manual camera-joystick exploration working in either mode.
	game.browser_classic=true
	game._recenter_camera()
	game._shift_camera(Vector2(190,70))
	check(not game.camera_locked,"2D camera joystick unlocks automatic following")
	var panned: Vector2=game.camera_anchor
	game._process(0.0)
	check(game.camera_anchor==panned and not game.camera_locked,"manually panned camera does not relock itself")
	game._recenter_camera()
	check(game.camera_locked,"recenter button restores automatic following")
	# The source 3D heading (NE) is always the 2D hull facing for a
	# steady diagonal, even as the sprite takes tiny raster steps.
	game.browser_classic=true
	var start: Vector2=Vector2(800,900)
	for destination: Vector2 in [Vector2(1400,350),Vector2(200,350),Vector2(1400,1450),Vector2(200,1450)]:
		var direction: Vector2=(destination-start).normalized()
		var actor: Dictionary={"id":9771,"kind":"ship","pos":start,"heading":direction,"path":[destination],"speed":76.0}
		game.classic_raster_visuals.erase(9771)
		game.classic_heading_cache.erase(9771)
		var real_frame: int=VIS.heading_eight(direction)
		var no_fake_turn: bool=true
		var max_offset: float=0.0
		for step in 241:
			actor.pos=start.lerp(destination,float(step)/241.0)
			var sample: Dictionary=game._classic_raster_visual(actor)
			if sample.is_empty():continue
			var deviation: float=Vector2(sample.pos).distance_to(actor.pos)
			max_offset=maxf(max_offset,deviation)
			if game._classic_frame_for_actor(actor)!=real_frame or Vector2(sample.heading).dot(direction)<0.999:no_fake_turn=false
		check(no_fake_turn,"2D diagonals NEVER change bow orientation away from 3D heading on "+str(destination))
		check(max_offset<=2.2 and max_offset>=0.5,"2D diagonal keeps subtle raster steps <=2.2 world px, no wide curves on "+str(destination))
	# Cardinal travel should still visibly switch between original
	# diagonal Classic frames NE/SE, as the user specifically requests.
	var east: Dictionary={"id":9772,"kind":"ship","pos":start,"heading":Vector2.RIGHT,"path":[start+Vector2(576,0)]}
	game.classic_raster_visuals.erase(9772)
	game.classic_heading_cache.erase(9772)
	var seen: Dictionary={}
	for step in 220:
		east.pos=start+Vector2(float(step)*2.5,0)
		seen[game._classic_frame_for_actor(east)]=true
	check(seen.has(1) and seen.has(3),"eastward Classic keeps familiar alternating NE/SE raster images")
	# Switching from a wide cardinal step to upper-right MUST NOT carry
	# the full old ±9px offset into the new diagonal target as a curve.
	east.pos=start+Vector2(540,0)
	game._classic_raster_visual(east)
	var new_target: Vector2=Vector2(east.pos)+Vector2(460,-460)
	east.heading=(new_target-Vector2(east.pos)).normalized()
	east.path=[new_target]
	var retap: Dictionary=game._classic_raster_visual(east)
	check(not retap.is_empty() and Vector2(retap.pos).distance_to(east.pos)<=2.2,"horizontal->upper-right retap cannot create visible curved settling")
	check(game._classic_frame_for_actor(east)==1,"upper-right retap points the hull NE immediately, not through fake SE/SW corners")
	game.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
