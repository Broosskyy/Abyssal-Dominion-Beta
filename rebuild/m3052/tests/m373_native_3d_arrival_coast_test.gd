extends SceneTree
## M373: the calm 3D hull may be visually eased, but MUST join the
## authoritative 2D/3D raster pose BEFORE arrival, not jump onto it.
## Straight projection must NEVER cut through coastal collision geometry.
const SIM=preload("res://simulation.gd")
const NAV=preload("res://navigation.gd")
var checks: int=0
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	game.browser_classic=false
	game.sim.npcs.clear()
	game.sim.islands.clear()
	game.visual_before.clear()
	game.visual_after.clear()
	var origin: Vector2=NAV.classic_tile_center(Vector2i(70,40))
	var targets: Array[Vector2]=[
		origin+Vector2(576,0),origin+Vector2(480,-320),
		origin+Vector2(-480,320),origin+Vector2(0,-384)]
	for goal: Vector2 in targets:
		game.sim.player.pos=origin
		game.sim.player.path=[]
		game.sim._clear_classic_raster_state(game.sim.player)
		game.native_course_poses.clear()
		game.elapsed=0.0
		check(game.sim.course(goal,true),"same physical grid click accepted "+str(goal))
		var before_goal: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
		var last_visual: Vector2=origin
		var start_stop_distance: float=0.0
		var largest_offset: float=0.0
		var maximum_step: float=0.0
		var reached: bool=false
		for tick in 650:
			if game.sim.player.path.is_empty():break
			game.sim._move(game.sim.player,1.0/30.0)
			game.elapsed+=1.0/30.0
			var pose: Dictionary=game._native_visual_pose(game.sim.player)
			var shown: Vector2=Vector2(pose.pos)
			var actual: Vector2=game.sim.player.pos
			var offset: float=shown.distance_to(actual)
			largest_offset=maxf(largest_offset,offset)
			maximum_step=maxf(maximum_step,shown.distance_to(last_visual))
			last_visual=shown
			if game.sim.player.path.is_empty():
				start_stop_distance=offset
				reached=true
				break
		check(reached and game.sim.player.pos.distance_to(goal)<0.001,"physics reaches exact 48x32 tile "+str(goal))
		check(start_stop_distance<1.2,"3D hull has ALREADY joined physical tile on final movement frame "+str(goal))
		check(largest_offset<=20.01,"3D never floats >20px away from its true physical route "+str(goal))
		check(maximum_step<6.0,"3D hull does not jump on the last sailing leg "+str(goal))
		check(game.sim.player.get("_iso_route",[])==[],"authoritative grid route clears naturally after arrival "+str(goal))
		var after: Dictionary=game._native_visual_pose(game.sim.player)
		check(Vector2(after.pos).distance_to(last_visual)<1.0,"stopped 3D mesh stays exactly where final sailing pose was drawn "+str(goal))
	# A sailing course can stop unexpectedly from a collision or cancel:
	# smooth the 3D display into the REAL stopped hull, do not snap.
	game.sim.islands.clear()
	game.sim.player.pos=origin
	game.sim.player.path.clear()
	game.sim._clear_classic_raster_state(game.sim.player)
	game.native_course_poses.clear()
	check(game.sim.course(origin+Vector2(576,0),true),"sudden-stop regression sets course")
	var visible_before: Vector2=origin
	var stop_world: Vector2=origin
	var sizable_offset: bool=false
	for step in 220:
		game.sim._move(game.sim.player,1.0/30.0)
		game.elapsed+=1.0/30.0
		visible_before=Vector2(game._native_visual_pose(game.sim.player).pos)
		stop_world=game.sim.player.pos
		if visible_before.distance_to(stop_world)>7.0:
			sizable_offset=true
			break
	check(sizable_offset,"stop test catches a real microstep offset")
	game.sim.player.path.clear()
	var initial_rest: Vector2=Vector2(game._native_visual_pose(game.sim.player).pos)
	check(initial_rest.distance_to(visible_before)<0.001,"interrupted voyage does not snap 3D ship on first stopped frame")
	game.elapsed+=0.11
	var halfway: Vector2=Vector2(game._native_visual_pose(game.sim.player).pos)
	check(halfway.distance_to(stop_world)<initial_rest.distance_to(stop_world),"3D display settles continuously to physics on unexpected stop")
	game.elapsed+=0.15
	var at_rest: Vector2=Vector2(game._native_visual_pose(game.sim.player).pos)
	check(at_rest.distance_to(stop_world)<0.001,"3D hull converges to actual hitbox even if cancelled mid-tile")
	# Coast: a straight display interpolation is not permitted when real
	# A* grid routing deliberately takes the ship around an island.
	game.native_course_poses.clear()
	game.sim.player.pos=origin
	game.sim._clear_classic_raster_state(game.sim.player)
	var rect: Rect2=Rect2(origin+Vector2(240,-40),Vector2(96,80))
	game.sim.islands.append({"bounds":rect,"outline":PackedVector2Array([
		rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])})
	var coast_goal: Vector2=origin+Vector2(576,0)
	check(not game.sim.segment_free(origin,coast_goal,2.0),"test coastline really blocks direct water line")
	check(game.sim.course(coast_goal,true),"isometric A* can plot around test island")
	var coast_route: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
	check(coast_route.size()>10 and coast_route.back()==coast_goal,"coastal physics still owns complete tile itinerary")
	var avoided: bool=true
	var never_blocked: bool=true
	for tick in 750:
		if game.sim.player.path.is_empty():break
		game.sim._move(game.sim.player,1.0/30.0)
		game.elapsed+=1.0/30.0
		var physical: Vector2=game.sim.player.pos
		var coast_display: Vector2=Vector2(game._native_visual_pose(game.sim.player).pos)
		avoided=avoided and coast_display.distance_to(physical)<0.001
		never_blocked=never_blocked and not game.sim.blocked(coast_display,2.0)
	check(avoided,"3D visible hull stays exactly on real A* collision-safe grid steps")
	check(never_blocked,"coastal 3D displayed hull never enters island collision geometry")
	check(game.sim.player.pos.distance_to(coast_goal)<0.001,"coastal 3D physically arrives at clicked tile")
	# Regression: a stationary NPC that is moved/respawned must not keep
	# its previous resting 3D pose. Otherwise Android touches miss.
	game.sim.npcs.clear()
	var idle: Dictionary=game.sim.base_npcs[0].duplicate(true)
	idle.pos=origin
	idle.path=[origin+Vector2(576,0)]
	game.native_course_poses.clear()
	game.sim.npcs.append(idle)
	game._native_visual_pose(idle)
	idle.path=[]
	game._native_visual_pose(idle)
	idle.pos=origin+Vector2(155,80)
	var relocated: Dictionary=game._native_visual_pose(idle)
	check(Vector2(relocated.pos).distance_to(idle.pos)<0.001,"idle NPC respawn clears stale 3D rest pose instead of leaving artwork at old world position")
	game.camera.position=idle.pos
	game.camera.force_update_scroll()
	var touch_point: Vector2=game.get_canvas_transform()*(idle.pos-Vector2(0,25))
	check(game._enemy_at_screen(touch_point)==int(idle.id),"Android single tap selects visible respawned 3D ship, not its old position")
	game.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
