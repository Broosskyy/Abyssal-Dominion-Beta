extends SceneTree
## Update 372: identical physical 48x32 paths but calm GLB/camera display.
## Do not change the actual ship-world route, heading, speed or 2D sprites.
const NAV=preload("res://navigation.gd")
const SIM=preload("res://simulation.gd")
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
	game.browser_classic=false
	game.visual_before.clear()
	game.visual_after.clear()
	var origin: Vector2=NAV.classic_tile_center(Vector2i(60,25))
	for delta: Vector2 in [Vector2(576,0),Vector2(480,-320),Vector2(-480,-320),
		Vector2(0,384),Vector2(384,256),Vector2(-384,256)]:
		var target: Vector2=origin+delta
		game.sim.player.pos=origin
		game.sim.player.heading=Vector2.RIGHT
		game.sim._clear_classic_raster_state(game.sim.player)
		game.sim.player.path=[]
		game.native_course_poses.clear()
		check(game.sim.course(target,true),"shared physical raster click accepted for "+str(delta))
		var physical: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
		check(physical.size()>4 and physical.back()==target,"3D physical route retains full 24x16 tile itinerary "+str(delta))
		var direction: Vector2=delta.normalized()
		var max_world_side: float=0.0
		var max_visual_side: float=0.0
		var max_visual_gap: float=0.0
		var min_visual_progress: float=-1.0
		var stable: bool=true
		for step in 600:
			if game.sim.player.path.is_empty():break
			game.sim._move(game.sim.player,1.0/30.0)
			var world: Vector2=game.sim.player.pos
			var pose: Dictionary=game._native_visual_pose(game.sim.player)
			var display: Vector2=Vector2(pose.pos)
			var course_heading: Vector2=Vector2(pose.heading)
			max_world_side=maxf(max_world_side,absf((world-origin).cross(direction)))
			max_visual_side=maxf(max_visual_side,absf((display-origin).cross(direction)))
			max_visual_gap=maxf(max_visual_gap,display.distance_to(world))
			var progress: float=(display-origin).dot(direction)
			if progress<min_visual_progress-0.01:stable=false
			if course_heading.dot(direction)<0.9999:stable=false
			min_visual_progress=progress
		check(stable,"3D hull never turns NE/SE at individual physical raster crossings "+str(delta))
		check(max_visual_side<=1.5,"3D hull has a calm visual travel line without side-to-side wobble "+str(delta))
		check(max_visual_gap<=30.01,"3D visuals stay <=30 world px from authoritative grid physics "+str(delta))
		check(max_world_side>=5.0,"underlying 3D real world movement STILL follows original raster "+str(delta))
		check(game.sim.player.pos.distance_to(target)<0.01 and game.sim.player.path.is_empty(),"both modes physically reach exactly the same tile "+str(delta))
	# A mid-sail switch must not change the 3D course or progress.
	game.sim.player.pos=origin
	game.sim._clear_classic_raster_state(game.sim.player)
	game.native_course_poses.clear()
	game.browser_classic=false
	check(game.sim.course(origin+Vector2(576,0),true),"mid-sail mode toggle scenario sets tile course")
	for tick in 45:game.sim._move(game.sim.player,1.0/30.0)
	var actual_before: Vector2=game.sim.player.pos
	var route_before: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
	var pose_before: Dictionary=game._native_visual_pose(game.sim.player)
	game.browser_classic=true
	check(game._classic_actor_render_pos(game.sim.player).distance_to(actual_before)<=1.5,"Classic 2D continues drawing actual physical raster coordinates")
	check(game.sim.player.pos==actual_before and game.sim.player.get("_iso_route",[])==route_before,"switching to Classic does not touch 3D/2D physical shared route")
	game.browser_classic=false
	var pose_after: Dictionary=game._native_visual_pose(game.sim.player)
	check(Vector2(pose_after.pos).distance_to(Vector2(pose_before.pos))<0.001,"switching back to 3D does not jump the hull on its first frame")
	check(game.sim.player.pos==actual_before and game.sim.player.get("_iso_route",[])==route_before,"3D presentation never affects physical 48x32 route")
	# A completely different click must reset the visual course heading
	# without freezing or teleporting the physical vessel.
	var next_goal: Vector2=origin+Vector2(-480,-320)
	check(game.sim.course(next_goal,true),"retap to upper-left remains navigable")
	var redirected: Dictionary=game._native_visual_pose(game.sim.player)
	check(Vector2(redirected.pos).distance_to(Vector2(pose_after.pos))<0.01,"3D graphic retap starts from previous on-screen pose")
	check(game.sim.player.pos==actual_before and game.sim.player.get("_iso_route",[]).back()==game.sim._classic_clicked_target(next_goal),"retap only updates the real raster goal")
	game.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
