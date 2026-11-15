extends SceneTree
## M365: old 2D Classic may visibly step, but must never leave the
## authoritative 3D route for a wide loop/curve, even diagonally.
const VIS=preload("res://ship_visuals.gd")
var checks: int=0
var errors: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:errors.append(label)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var origin: Vector2=Vector2(600,600)
	for target: Vector2 in [Vector2(1300,600),Vector2(1300,100),Vector2(1300,1400),
		Vector2(-200,600),Vector2(-200,100),Vector2(600,1500),
		Vector2(600,-300),Vector2(1100,270)]:
		var axis: Vector2=(target-origin).normalized()
		var side: Vector2=Vector2(-axis.y,axis.x)
		var previous_progress: float=-1.0
		var max_offset: float=0.0
		var max_side: float=0.0
		var bad: bool=false
		var backwards: bool=false
		for i in 301:
			var world: Vector2=origin.lerp(target,float(i)/300.0)
			var frame: Dictionary=VIS.classic_tethered_raster(origin,target,world)
			var rendered: Vector2=Vector2(frame.pos)
			var diff: Vector2=rendered-world
			var course_progress: float=(rendered-origin).dot(axis)
			var cross: float=absf((rendered-world).dot(side))
			max_offset=maxf(max_offset,diff.length())
			max_side=maxf(max_side,cross)
			if diff.length()>10.01 or cross>10.01:bad=true
			if course_progress<previous_progress-0.05:backwards=true
			if Vector2(frame.heading).dot(axis)<0.82:bad=true
			previous_progress=course_progress
		check(not bad and not backwards,"2D remains <=10 world px off actual straight course without backward curves: "+str(target))
		var cardinality: float=absf(absf(axis.x)-absf(axis.y))
		if cardinality<0.12:
			check(max_side>0.7 and max_side<=2.1,"diagonal 2D pixel rhythm stays <=2.1 world px from 3D line: "+str(target))
		elif cardinality>0.98:
			check(max_side>=7.0 and max_side<=9.1,"cardinal Classic course retains the authentic wider NE/SE pixel rhythm: "+str(target))
		else:
			check(max_side>0.8 and max_side<=9.1,"oblique raster smoothly scales its jitter without visual turns: "+str(target))
		check(origin.distance_to(Vector2(VIS.classic_tethered_raster(origin,target,origin).pos))<0.0001,"starting any diagonal course is seamless")
		check(target.distance_to(Vector2(VIS.classic_tethered_raster(origin,target,target).pos))<0.0001,"finishing any diagonal course reaches exactly the 3D target")
	# Real scene, real navigation and real 2D renderer; compare identical
	# diagonal player coordinates against native 3D view every frame.
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false)
	game.sim.islands.clear()
	game.sim.player.pos=Vector2(600,600)
	game.sim._clear_classic_raster_state(game.sim.player)
	game.browser_classic=true
	game.classic_raster_visuals.clear()
	var clicked_goal: Vector2=Vector2(1100,120)
	check(game.sim.course(clicked_goal,true),"upper-right direct course accepted")
	# A real 2D tap selects a 48x32 diamond CENTRE, not the unsnapped
	# input pixel. Compare the visible movement against that exact
	# authoritative destination (the same one 3D and online receive).
	var goal: Vector2=Vector2(game.sim.player.path.back())
	var world_start: Vector2=game.sim.player.pos
	var course_dir: Vector2=(goal-world_start).normalized()
	check(game.sim.player.get("_iso_route",[]).size()==1,"upper-right test uses one genuine free-water course")
	var track_ok: bool=true
	var path_untouched: Array=game.sim.player.path.duplicate(true)
	var max_travel_error: float=0.0
	var frame_switches: int=0
	var old_frame: int=-1
	for i in 170:
		if game.sim.player.path.is_empty():break
		game.sim._move(game.sim.player,1.0/30.0)
		var original: Vector2=game.sim.player.pos
		var drawn: Vector2=game._classic_actor_render_pos(game.sim.player)
		var error: float=drawn.distance_to(original)
		max_travel_error=maxf(max_travel_error,error)
		if error>11.5 or absf((original-world_start).cross(course_dir))>0.01:track_ok=false
		var frame_id: int=game._classic_frame_for_actor(game.sim.player)
		if old_frame>=0 and frame_id!=old_frame:frame_switches+=1
		old_frame=frame_id
	check(track_ok and max_travel_error>0.5 and max_travel_error<=3.0,"2D upper-right raster is visible but strictly stays within 3 world px of the real 3D course")
	check(game.sim.player.path==path_untouched and game.sim.player.heading.dot(course_dir)>0.99,"2D drawing did not add any waypoint or bend to the 3D world course")
	var real_pos: Vector2=game.sim.player.pos
	game.browser_classic=false
	check(game._classic_actor_render_pos(game.sim.player).distance_to(real_pos)<0.001,"3D view is literally unchanged by Classic-only raster")
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if errors.is_empty() else "FAIL","checks":checks,"failures":errors}))
	quit(0 if errors.is_empty() else 1)
