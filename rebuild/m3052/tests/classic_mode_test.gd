extends SceneTree
const SIM=preload("res://simulation.gd")
const VISUALS=preload("res://ship_visuals.gd")
var checks:=0
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	# The four historical Classic facings use the diagonal frames from the
	# eight baked 2D sprites. Four views change only visual orientation.
	for heading: Vector2 in [Vector2(1,-1),Vector2(-1,-1),Vector2(-1,1),Vector2(1,1)]:
		var expected: int=[1,7,5,3][[Vector2(1,-1),Vector2(-1,-1),Vector2(-1,1),Vector2(1,1)].find(heading)]
		check(VISUALS.heading_four(heading)==expected,"four-way Classic graphic selects correct baked diagonal "+str(heading))
	for heading: Vector2 in [Vector2.RIGHT,Vector2.UP,Vector2.LEFT,Vector2.DOWN,Vector2(5,2),Vector2(-8,1)]:
		check(VISUALS.heading_four(heading) in [1,3,5,7],"every ordinary captain heading chooses exactly one of the four Classic frames")
	var east_frame: int=VISUALS.heading_four(Vector2.RIGHT)
	check(VISUALS.heading_four(Vector2(1,-0.07),east_frame)==east_frame and VISUALS.heading_four(Vector2(1,0.07),east_frame)==east_frame,"Classic sprite hysteresis prevents flickering when sailing nearly east")
	# The user showed that Seafight wiggles the HULL in screen pixels,
	# NOT the real course, camera or world coordinates.
	# Pixel-error diffusion alternates adjacent facings while a cardinal
	# course is simulated as a perfectly direct navigation line.
	var right_start: Dictionary=VISUALS.classic_pixel_pose(Vector2.RIGHT,0.0)
	var right_next: Dictionary=VISUALS.classic_pixel_pose(Vector2.RIGHT,VISUALS.CLASSIC_PIXEL_STEP_WORLD)
	check(int(right_start.frame)!=int(right_next.frame) and int(right_start.frame) in [1,3] and int(right_next.frame) in [1,3],"a horizontal course alternates visible NE/SE facings on short pixel legs")
	var left_start: Dictionary=VISUALS.classic_pixel_pose(Vector2.LEFT,0.0)
	var left_next: Dictionary=VISUALS.classic_pixel_pose(Vector2.LEFT,VISUALS.CLASSIC_PIXEL_STEP_WORLD)
	check(int(left_start.frame)!=int(left_next.frame) and int(left_start.frame) in [5,7] and int(left_next.frame) in [5,7],"a westbound course alternates only visible SW/NW facings")
	var pixel_values: Dictionary={}
	for sample_index in 65:
		var sample: Dictionary=VISUALS.classic_pixel_pose(Vector2.RIGHT,float(sample_index))
		var px: float=float(sample.pixel_x)
		check(absf(px)<=VISUALS.CLASSIC_HULL_DRIFT_PX+0.01 and is_equal_approx(px,float(roundi(px))),"visual hull movement never exceeds three full screen pixels")
		pixel_values[px]=true
	check(pixel_values.size()>2,"the visible ship moves in several discrete one-pixel steps instead of an instantaneous image flip")
	var low_drift: Dictionary=VISUALS.classic_pixel_pose(Vector2.RIGHT,0.0,32.0,2.0)
	var high_drift: Dictionary=VISUALS.classic_pixel_pose(Vector2.RIGHT,0.0,32.0,5.0)
	check(absf(float(low_drift.pixel_x))<absf(float(high_drift.pixel_x)),"pixel strength actually scales the moving ship instead of merely limiting it")
	var fast_dwell: Dictionary=VISUALS.classic_pixel_pose(Vector2.RIGHT,24.0,20.0,3.0)
	var slow_dwell: Dictionary=VISUALS.classic_pixel_pose(Vector2.RIGHT,24.0,48.0,3.0)
	check(int(fast_dwell.frame)!=int(slow_dwell.frame),"pixel speed setting changes the actual four-view timing")

	for diagonal: Vector2 in [Vector2(1,-1),Vector2(1,1),Vector2(-1,1),Vector2(-1,-1)]:
		var pose_one: Dictionary=VISUALS.classic_pixel_pose(diagonal,5.0)
		var pose_two: Dictionary=VISUALS.classic_pixel_pose(diagonal,135.0)
		check(int(pose_one.frame)==int(pose_two.frame) and float(pose_one.pixel_x)==0.0 and float(pose_two.pixel_x)==0.0,"exact diagonals keep their pose and have zero fake hull drift")
	var shallow: Vector2=Vector2(8.0,-5.0)
	var shallow_holds: bool=false
	var last_frame: int=-1
	var hold_count: int=0
	for interval in 30:
		var image: int=int(VISUALS.classic_pixel_pose(shallow,float(interval)*VISUALS.CLASSIC_PIXEL_STEP_WORLD).frame)
		if image==last_frame:hold_count+=1
		else:hold_count=0
		if hold_count>=2:shallow_holds=true
		last_frame=image
	check(shallow_holds,"oblique courses naturally hold one ship pose for multiple steps without an animation timer")
	var sim=SIM.new();sim.npcs.clear();sim.player.pos=Vector2(500,500)
	var goal:=Vector2(1200,500)
	check(not sim.classic_steering,"native default uses direct navigation")
	check(sim.course(goal),"water tap creates a course")
	check(sim.player.path.size()==1 and sim.player.path[0]==goal,"native open water follows one direct line")
	var initial_route: Array=sim.player.path.duplicate()
	var initial_pos: Vector2=sim.player.pos
	sim.set_classic_steering(true)
	check(sim.classic_steering and sim.player.path==initial_route and sim.player.pos==initial_pos,"switching to Classic never rewrites the physical route or teleports the captain")
	check(sim.player.path.size()==1 and sim.player.path[0]==goal,"Classic horizontal sailing has no synthetic diagonal zigzags")
	var stock: Array=sim.player.ammo.duplicate()
	var horizontal_track: bool=true
	for step in 900:
		sim._move(sim.player,1.0/60.0)
		horizontal_track=horizontal_track and absf(float(sim.player.pos.y)-500.0)<0.01
		if sim.player.path.is_empty():break
	check(horizontal_track and sim.player.pos.distance_to(goal)<.01 and sim.player.ammo==stock,"Classic physically sails dead straight toward a horizontal click, without spending ammo")
	var diagonal_goal:=Vector2(1600,850)
	check(sim.course(diagonal_goal) and sim.player.path==sim.plan_path(sim.player.pos,diagonal_goal),"Classic follows a direct diagonal tap using ordinary simulation physics")
	sim._move(sim.player,0.25)
	var corner: Vector2=sim.player.pos
	check(sim.course(Vector2(300,850)) and sim.player.path.back()==Vector2(300,850),"new tap immediately replaces the course")
	sim._move(sim.player,.01)
	check(sim.player.heading.x<0 and sim.player.pos.distance_to(corner)<2,"retap takes effect without turn circle or teleport")
	var changing_route: Array=sim.player.path.duplicate()
	var switch_origin: Vector2=sim.player.pos
	sim.set_classic_steering(false)
	check(not sim.classic_steering and sim.player.pos==switch_origin and sim.player.path==changing_route,"returning to 3D leaves the exact active course and location intact")
	var npc_body: Dictionary={"pos":Vector2(500,500),"heading":Vector2.RIGHT,"kind":"ship"}
	var npc_direct: Array[Vector2]=sim.plan_actor_path(npc_body,Vector2(1200,500))
	check(npc_direct.size()==1 and npc_direct[0]==Vector2(1200,500),"native NPC patrol ship follows direct courses")
	sim.set_classic_steering(true)
	var npc_classic: Array[Vector2]=sim.plan_actor_path(npc_body,Vector2(1200,500))
	check(npc_classic==npc_direct,"Classic NPC sprites follow exact same physical paths as native NPCs")
	var monster: Dictionary={"pos":Vector2(500,500),"heading":Vector2.RIGHT,"kind":"monster"}
	check(sim.plan_actor_path(monster,Vector2(1200,500))==npc_direct,"sea monsters keep direct navigation in every mode")
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame;game.set_process(false)
	var before: Dictionary=game.sim.export_save()
	game._set_render_mode("hybrid");await process_frame
	check(not game.sim.classic_steering and game.render_mode=="hybrid","native 2.5D uses direct steering")
	var native_player_length: float=game._actor_visual_length(game.sim.player)
	var native_npc_length: float=game._actor_visual_length(game.sim.npcs[0])
	game.sim.course(game.sim.player.pos+Vector2(600,0))
	var destination: Vector2=game.sim.player.path.back()
	var course: Array=game.sim.player.path.duplicate()
	game._set_render_mode("classic");await process_frame
	check(game.browser_classic and game.render_mode=="classic" and game.mesh_layer==null,"native Classic disables and removes the 3D fleet viewport")
	check(game._classic_fleet_ready(),"native 2D loads all 23 ship and paint atlases")
	check(game.sim.classic_steering and game.sim.player.path.back()==destination and game.sim.player.path==course and game.sim.player.pos==Vector2(before.position[0],before.position[1]),"Classic 2D preserves existing physical waypoint path and position while changing only sprite views")
	check(is_equal_approx(game._actor_visual_length(game.sim.player),native_player_length*game.CLASSIC_HULL_SCALE),"Classic uses a smaller on-screen captain hull without altering game physics")
	check(is_equal_approx(game._actor_visual_length(game.sim.npcs[0]),native_npc_length*game.CLASSIC_HULL_SCALE),"Classic scales NPC hulls with the captain instead of dwarfing enemies")
	var path_before_framing: Array=game.sim.player.path.duplicate()
	var saved_position: Vector2=game.sim.player.pos
	for viewport_size: Vector2i in [Vector2i(844,390),Vector2i(2340,1080)]:
		root.size=viewport_size
		await process_frame
		var expected_boost: float=clampf(float(viewport_size.y)/720.0,1.0,game.CLASSIC_VIEWPORT_ZOOM_BOOST_MAX)
		check(is_equal_approx(game._sharp_zoom(),game.desired_zoom*expected_boost),"Classic no longer magnifies ships by desktop-density viewport scaling at "+str(viewport_size))
		game.camera.position=game.sim.player.pos
		game.camera.zoom=Vector2.ONE*game._sharp_zoom()
		game.camera.force_update_scroll()
		var center: Vector2=game.get_canvas_transform()*game._visual_actor_pos(game.sim.player)
		check(center.distance_to(game.get_viewport_rect().size*.5)<1.0,"Classic locked follow keeps captain centered at "+str(viewport_size))
		var atlas_meta: Dictionary=game.classic_geometry.get(game._classic_atlas_key(game.sim.player),{})
		check(not atlas_meta.is_empty(),"Classic retains stable baked hull metadata at "+str(viewport_size))
		if not atlas_meta.is_empty():
			var expected_drop: float=float(atlas_meta.stable_bottom)*game._actor_visual_length(game.sim.player)/float(atlas_meta.reference_extent)*game.camera.zoom.x+game.CLASSIC_LABEL_CLEARANCE_PX*game._plate_pixels()
			var actual_drop: float=game._plate_screen_anchor(game.sim.player).y-center.y
			check(absf(actual_drop-expected_drop)<1.1,"Classic labels are close and anchored to the scaled hull at "+str(viewport_size))
	check(game.sim.player.path==path_before_framing and game.sim.player.pos==saved_position,"framing changes cannot alter current course or game world coordinates")
	root.size=Vector2i(1280,720)
	await process_frame
	game.camera.zoom=Vector2.ONE*game._sharp_zoom()
	game.camera.position=game.sim.player.pos
	game.camera.force_update_scroll()
	game.sim.player.heading=Vector2(1,-1)
	check(game._classic_frame_for_actor(game.sim.player)==1,"Classic renderer draws the expected NE atlas frame from the preserved eight-view collection")
	game.sim.player.heading=Vector2(1,1)
	check(game._classic_frame_for_actor(game.sim.player)==3,"Classic renderer changes facing without changing simulated world coordinates")
	# Exercise the real ship sprite resolver, not only the pure helper:
	# moved WORLD position drives the facing pendulum, not a zigzag path.
	var motion_probe: Dictionary={"id":9318,"pos":Vector2(500,500),"speed":100.0,"heading":Vector2.RIGHT}
	game._classic_frame_for_actor(motion_probe)
	var shown: Dictionary={}
	var pixel_offsets: Dictionary={}
	var actual_route: Array=game.sim.player.path.duplicate()
	var actual_position: Vector2=game.sim.player.pos
	var untouched_world_y: bool=true
	for step in 13:
		motion_probe.pos+=Vector2(12,0)
		shown[game._classic_frame_for_actor(motion_probe)]=true
		var screen_px: float=game._classic_hull_pixel_offset(motion_probe).x*game.get_canvas_transform().x.length()
		pixel_offsets[roundi(screen_px)]=true
		untouched_world_y=untouched_world_y and is_equal_approx(motion_probe.pos.y,500.0)
		check(absf(screen_px)<=VISUALS.CLASSIC_HULL_DRIFT_PX+0.01,"only graphic moves within maximum three SCREEN pixels")
	check(shown.has(1) and shown.has(3) and pixel_offsets.size()>1,"the rendered ship turns left/right and advances in tiny pixel steps")
	check(untouched_world_y and game.sim.player.path==actual_route and game.sim.player.pos==actual_position,"pixel steps never change actual ship Y, gameplay waypoints or camera center")
	var user_course: Array=game.sim.player.path.duplicate()
	var user_world: Vector2=game.sim.player.pos
	game._set_classic_pixel_motion(20.0,5.0)
	check(is_equal_approx(game.classic_pixel_step_world,20.0) and is_equal_approx(game.classic_pixel_strength,5.0),"classic pixel movement can be tuned live from Grafik settings")
	check(game.sim.player.path==user_course and game.sim.player.pos==user_world,"tuning Classic ship animation does not rewrite the real course or world coordinates")
	game._set_classic_pixel_motion(32.0,3.0)

	var stopped_view: int=game._classic_frame_for_actor(motion_probe)
	game.elapsed+=0.3
	check(game._classic_frame_for_actor(motion_probe)==stopped_view,"standing still freezes the last left/right sailing sprite")
	check(game.sim.player.gold==int(before.gold) and game.sim.player.skin==int(before.skin) and game.sim.player.ammo==before.ammo,"graphics switch preserves ship, wallet and ammunition")
	game._open_modal("Anzeige")
	var options: Array[String]=[]
	for button in game.modal_body.find_children("*","Button",true,false):options.append(button.text)
	check(options.any(func(text):return text.begins_with("CLASSIC 2D")) and options.any(func(text):return text.begins_with("2,5D")) and options.any(func(text):return text.begins_with("3D")),"native settings keep all three modes reachable from Classic")
	game.queue_free();await process_frame
	var reloaded=load("res://sea_map.tscn").instantiate();root.add_child(reloaded);current_scene=reloaded
	await process_frame;reloaded.set_process(false)
	check(reloaded.browser_classic and reloaded.render_mode=="classic" and reloaded.mesh_layer==null,"saved Classic preference starts natively without constructing 3D")
	reloaded._set_render_mode("3d");await process_frame
	check(not reloaded.browser_classic and not reloaded.sim.classic_steering and reloaded.mesh_layer!=null and reloaded.mesh_layer.has_complete_fleet() and reloaded.render_mode=="3d","3D restores original direct steering and complete native fleet")
	check(is_equal_approx(reloaded._actor_visual_length(reloaded.sim.player),native_player_length),"3D captain hull size remains exactly unchanged")
	reloaded._set_render_mode("classic");await process_frame
	reloaded._set_render_mode("hybrid");await process_frame
	check(not reloaded.browser_classic and not reloaded.sim.classic_steering and reloaded.render_mode=="hybrid" and reloaded.mesh_layer!=null,"2.5D restores direct steering and one working renderer")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
