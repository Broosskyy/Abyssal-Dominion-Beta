extends SceneTree
## M373: 3D visuals must occupy exactly the authoritative 48x32
## position while macro-heading stays calm across real microsteps.
## No independent mesh/camera path, arrival snap or island shortcut.
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
	for delta: Vector2 in [Vector2(576,0),Vector2(480,-320),Vector2(-480,320),Vector2(0,-384)]:
		game.sim.player.pos=origin
		game.sim.player.path=[]
		game.sim._clear_classic_raster_state(game.sim.player)
		game.native_course_poses.clear()
		var goal: Vector2=origin+delta
		check(game.sim.course(goal,true),"shared click works "+str(goal))
		var physical: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
		check(physical.size()>4 and physical.back()==goal,"shared real 48x32 microstep route remains "+str(goal))
		var no_drifts: bool=true
		var stable_heading: bool=true
		var max_jump: float=0.0
		var last_display: Vector2=origin
		for tick in 750:
			if game.sim.player.path.is_empty():break
			game.sim._move(game.sim.player,1.0/30.0)
			var pose: Dictionary=game._native_visual_pose(game.sim.player)
			var displayed: Vector2=Vector2(pose.pos)
			var expected: Vector2=game._visual_actor_pos(game.sim.player)
			var screen_mesh_anchor: Vector2=game._classic_actor_render_pos(game.sim.player)
			no_drifts=no_drifts and displayed.distance_to(expected)<0.001 and screen_mesh_anchor.distance_to(expected)<0.001
			stable_heading=stable_heading and Vector2(pose.heading).dot(delta.normalized())>0.995
			max_jump=maxf(max_jump,displayed.distance_to(last_display))
			last_display=displayed
		check(no_drifts,"3D camera, mesh and HUD all share the precise physical raster position "+str(goal))
		check(stable_heading,"3D nose does not alternate at each 24x16 raster step "+str(goal))
		check(max_jump<6.0,"no 3D positional jump during physical raster sailing "+str(goal))
		check(game.sim.player.pos.distance_to(goal)<0.001 and game.sim.player.path.is_empty(),"true physical and visible ship arrive at clicked tile "+str(goal))
		check(Vector2(game._native_visual_pose(game.sim.player).pos).distance_to(goal)<0.001,"3D hull cannot snap when stopping at destination "+str(goal))
	# Stopping in the middle of a raster microstep is also not allowed to
	# jump a separate projected mesh back to the hitbox.
	game.sim.player.pos=origin
	game.sim.player.path.clear()
	game.sim._clear_classic_raster_state(game.sim.player)
	game.native_course_poses.clear()
	check(game.sim.course(origin+Vector2(576,0),true),"interrupted voyage accepted")
	for tick in 35:game.sim._move(game.sim.player,1.0/30.0)
	var prior: Vector2=Vector2(game._native_visual_pose(game.sim.player).pos)
	game.sim.player.path.clear()
	var after: Vector2=Vector2(game._native_visual_pose(game.sim.player).pos)
	check(prior.distance_to(after)<0.001 and after.distance_to(game.sim.player.pos)<0.001,"3D ship and hitbox never separate at sudden stop")
	# Real raster A* coast detour: mesh may not shortcut through an island.
	game.native_course_poses.clear()
	game.sim.player.pos=origin
	game.sim._clear_classic_raster_state(game.sim.player)
	var rect: Rect2=Rect2(origin+Vector2(240,-40),Vector2(96,80))
	game.sim.islands.append({"bounds":rect,"outline":PackedVector2Array([
		rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])})
	var coast_goal: Vector2=origin+Vector2(576,0)
	check(not game.sim.segment_free(origin,coast_goal,2.0),"coastline blocks the physical direct segment")
	check(game.sim.course(coast_goal,true),"real coastal grid A* course accepted")
	var coast_route: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
	check(coast_route.size()>10 and coast_route.back()==coast_goal,"coast route preserves complete physical raster steps")
	var coastal_match: bool=true
	var safe: bool=true
	for tick in 850:
		if game.sim.player.path.is_empty():break
		game.sim._move(game.sim.player,1.0/30.0)
		var visible: Vector2=Vector2(game._native_visual_pose(game.sim.player).pos)
		coastal_match=coastal_match and visible.distance_to(game.sim.player.pos)<0.001
		safe=safe and not game.sim.blocked(visible,2.0)
	check(coastal_match,"3D mesh and collision position stay together during island detour")
	check(safe,"3D mesh never takes a separate path through island geometry")
	check(game.sim.player.pos.distance_to(coast_goal)<0.001,"shared 2D/3D physical course reaches coastal target")
	# Camera follow is centered on the SAME physical pose as the mesh.
	game.sim.islands.clear()
	game.sim.player.pos=origin
	game.sim.player.path.clear()
	game.sim._clear_classic_raster_state(game.sim.player)
	game.native_course_poses.clear()
	game.camera_locked=true
	game.loading_left=0.0
	game.camera.position=origin+Vector2(80,80)
	game._process(0.0)
	check(game.camera.position.distance_to(game._native_visual_pose(game.sim.player).pos)<0.001,"3D camera follows exact physical/visible mesh position")
	# Switching views never changes route or world position.
	check(game.sim.course(origin+Vector2(480,-320),true),"graphics-toggle real course accepted")
	for tick in 10:game.sim._move(game.sim.player,1.0/30.0)
	var state_pos: Vector2=game.sim.player.pos
	var state_route: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
	game.browser_classic=true
	check(game.sim.player.pos==state_pos and game.sim.player.get("_iso_route",[])==state_route,"switch to 2D preserves physical raster route")
	game.browser_classic=false
	check(game.sim.player.pos==state_pos and game.sim.player.get("_iso_route",[])==state_route and Vector2(game._native_visual_pose(game.sim.player).pos)==state_pos,"3D return preserves exact physical route and has zero visual position offset")
	game.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
