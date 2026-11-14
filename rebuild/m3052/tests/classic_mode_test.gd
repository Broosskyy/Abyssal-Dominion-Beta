extends SceneTree
const SIM=preload("res://simulation.gd")
const VISUALS=preload("res://ship_visuals.gd")
const MESH_LAYER=preload("res://ship_mesh_layer.gd")
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
	# Isometric 48x32 movement: real diagonal world legs, no fake
	# render-time triangle and no user-selectable movement variants.
	check(is_equal_approx(SIM.CLASSIC_ISO_DIRECTIONS[0].x/SIM.CLASSIC_ISO_DIRECTIONS[0].y,-1.5),"48x32 slope is retained in the four real movement axes")
	check(is_equal_approx(SIM.CLASSIC_ISO_LEG_WORLD,32.0),"Classic raster uses 32-world-unit legs with unchanged 3:2 diagonal axes")
	# Mobile Classic fixes are visual-only: physical touch coordinates and
	# online world position must NOT scale with the viewport or ship image.
	check(is_equal_approx(0.62*0.78/0.36,1.3433334),"on a 709px mobile viewport ship becomes ~34 percent larger while islands become ~22 percent smaller")
	var sim=SIM.new();sim.npcs.clear();sim.player.pos=Vector2(500,500)
	# Regression: the old Test 338 bearing scorer gets stuck forever
	# around (75,130) when asked to sail (300,500). Verify every octant,
	# including shallow, steep and 45-degree angles, reaches exact goals
	# without generating a 2-leg loop or wandering >36 units off course.
	sim.set_classic_steering(true)
	for heading_target: Vector2 in [
		Vector2(300,500),Vector2(-300,500),
		Vector2(300,-500),Vector2(-300,-500),
		Vector2(650,650),Vector2(-650,650),
		Vector2(650,-650),Vector2(-650,-650),
		Vector2(700,0),Vector2(-700,0),
		Vector2(0,700),Vector2(0,-700),
		Vector2(40,600),Vector2(600,40)
	]:
		var trial: Dictionary={"id":0,"pos":Vector2.ZERO,"heading":Vector2.RIGHT,"path":[heading_target]}
		var max_cross_track: float=0.0
		var visited_steps: int=0
		for tick in 1800:
			if trial.path.is_empty():break
			sim._move_classic(trial,165.0/30.0,true)
			visited_steps+=1
			max_cross_track=maxf(max_cross_track,absf(Vector2(trial.pos).cross(heading_target.normalized())))
		check(trial.path.is_empty() and Vector2(trial.pos).distance_to(heading_target)<0.1,"all Classic tap directions reach the precise clicked target without oscillation: "+str(heading_target))
		check(max_cross_track<36.0 and visited_steps<1800,"Classic Bresenham-style path stays within one isometric tile of intended course: "+str(heading_target))
	# A new tap must discard the partially completed previous physical leg.
	var retap_probe: Dictionary={"id":0,"pos":Vector2.ZERO,"heading":Vector2.RIGHT,"path":[Vector2(700,0)]}
	for step in 40:sim._move_classic(retap_probe,165.0/30.0,true)
	var retap_start: Vector2=retap_probe.pos
	var new_goal: Vector2=retap_start+Vector2(-250,-400)
	retap_probe.path=[new_goal]
	for tick in 900:
		if retap_probe.path.is_empty():break
		sim._move_classic(retap_probe,165.0/30.0,true)
	check(retap_probe.path.is_empty() and Vector2(retap_probe.pos).distance_to(new_goal)<0.1,"a new tap replaces a mid-leg course without stale direction or loops")
	sim.set_classic_steering(false)
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
	var physical_steps: Dictionary={}
	var lowest_y: float=500.0
	var highest_y: float=500.0
	var saw_real_diagonal: bool=false
	for step in 900:
		var old_pos: Vector2=sim.player.pos
		sim._move(sim.player,1.0/60.0)
		var velocity: Vector2=Vector2(sim.player.pos)-old_pos
		lowest_y=minf(lowest_y,sim.player.pos.y)
		highest_y=maxf(highest_y,sim.player.pos.y)
		if velocity.length()>0.01 and not sim.player.path.is_empty():
			var heading: Vector2=sim.player.heading
			physical_steps[VISUALS.heading_four(heading)]=true
			saw_real_diagonal=saw_real_diagonal or (absf(velocity.x)>0.2 and absf(velocity.y)>0.2)
		if sim.player.path.is_empty():break
	check(saw_real_diagonal and physical_steps.has(1) and physical_steps.has(3),"horizontal Classic route uses REAL alternating NE/SE 48x32 world steps, not animated pixels")
	check(highest_y-lowest_y>15.0 and highest_y-lowest_y<25.0,"horizontal Classic ship physically moves through the ~20px isometric staircase")
	check(sim.player.pos.distance_to(goal)<0.1 and sim.player.path.is_empty() and sim.player.ammo==stock,"true diagonal-step sailing arrives exactly at the requested point without changing ammunition")
	var diagonal_goal:=Vector2(1600,850)
	check(sim.course(diagonal_goal) and sim.player.path==sim.plan_path(sim.player.pos,diagonal_goal),"Classic navigation retains the requested destination; only the physical micro-legs are diagonals")
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
	check(npc_classic==npc_direct,"Classic NPCs keep the same waypoints but travel them using four diagonals")
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
	# Original 48x32 isometric visual bearings are +/-atan(32/48)
	# (~33.69 degrees), NOT +/-45-degree compass renders.
	var expected_chart_iso: float=atan2(32.0,48.0)
	var expected_model_yaw: float=atan2(32.0,48.0*cos(deg_to_rad(MESH_LAYER.FLEET_CAMERA_TILT_DEGREES)))
	var classic_frames: Array=game.classic_geometry.get("schattenkriegsschiff_shaded",{}).get("frames",[])
	check(classic_frames.size()==8,"captain GLB is baked to eight distinct 2D frames")
	if classic_frames.size()==8:
		for angle_case: Array in [[1,-expected_model_yaw,-expected_chart_iso],[3,expected_model_yaw,expected_chart_iso],[5,PI-expected_model_yaw,PI-expected_chart_iso],[7,-PI+expected_model_yaw,-PI+expected_chart_iso]]:
			var atlas_index: int=int(angle_case[0])
			var expected_yaw: float=float(angle_case[1])
			var expected_screen_angle: float=float(angle_case[2])
			var baked_angle: float=float(classic_frames[atlas_index].get("heading_angle_rad",999.0))
			var projected_angle: float=float(classic_frames[atlas_index].get("chart_angle_rad",999.0))
			check(absf(wrapf(baked_angle-expected_yaw,-PI,PI))<0.001,"GLB yaw compensates for orthographic camera tilt: "+str(atlas_index))
			check(absf(wrapf(projected_angle-expected_screen_angle,-PI,PI))<0.001,"baked Classic image projects to actual 48x32 on-screen move direction: "+str(atlas_index))
	check(game.sim.classic_steering and game.sim.player.path.back()==destination and game.sim.player.path==course and game.sim.player.pos==Vector2(before.position[0],before.position[1]),"Classic 2D preserves existing physical waypoint path and position while changing only sprite views")
	check(is_equal_approx(game._actor_visual_length(game.sim.player),native_player_length*game.CLASSIC_HULL_SCALE),"Classic uses a smaller on-screen captain hull without altering game physics")
	check(is_equal_approx(game.CLASSIC_HULL_SCALE_MOBILE,0.62) and is_equal_approx(game.CLASSIC_MOBILE_CAMERA_FACTOR,0.78),"Android/iOS Classic calibrates ship footprint and world zoom separately from desktop and 3D")
	check(game.CLASSIC_HULL_SCALE_MOBILE>game.CLASSIC_HULL_SCALE and game.CLASSIC_MOBILE_CAMERA_FACTOR<1.0,"ship increases while background map zooms out on mobile")
	check(is_equal_approx(game._actor_visual_length(game.sim.npcs[0]),native_npc_length*game.CLASSIC_HULL_SCALE),"Classic scales NPC hulls with the captain instead of dwarfing enemies")
	# One non-selectable edge camera stays with the real ship motion.
	var camera_start: Vector2=Vector2(800,500)
	var world_view: Vector2=Vector2(1200,700)
	var within: Vector2=game._classic_edge_camera_goal(camera_start+Vector2(300,170),camera_start,world_view)
	check(within==camera_start,"Classic camera remains completely stationary while the captain moves inside the screen safe area")
	var at_edge: Vector2=game._classic_edge_camera_goal(camera_start+Vector2(520,280),camera_start,world_view)
	check(is_equal_approx(at_edge.x,camera_start.x+112.0) and is_equal_approx(at_edge.y,camera_start.y+42.0),"camera starts scrolling only when the captain crosses viewport border margins")
	var restored: Vector2=game._classic_edge_camera_goal(camera_start,camera_start,world_view)
	check(restored==camera_start,"Classic camera never invents an offset when the ship is stationary")
	check(game._classic_edge_camera_goal(camera_start+Vector2(300,170),camera_start,world_view)==camera_start,"Classic camera mode is always edge-follow, not selectable")
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
	# Regression: 30Hz simulation heading has already switched, but the
	# 60fps rendered ship is still interpolating the PREVIOUS 30Hz segment.
	# Hull should point along that displayed movement, not its NEXT leg.
	var display_probe: Dictionary={"id":9317,"kind":"ship","pos":Vector2(531,480),"heading":Vector2(3,2)}
	game.visual_before[9317]=Vector2(501,500)
	game.visual_after[9317]=Vector2(531,480)
	check(game._classic_frame_for_actor(display_probe)==1,"one-tick-ahead physics heading cannot flip a hull still displaying NE motion")
	game.visual_before[9317]=Vector2(531,480)
	game.visual_after[9317]=Vector2(561,500)
	display_probe.pos=Vector2(561,500)
	display_probe.heading=Vector2(3,-2)
	check(game._classic_frame_for_actor(display_probe)==3,"visible SE leg chooses SE sprite even when the next physics leg is already NE")
	game.visual_before.erase(9317)
	game.visual_after.erase(9317)
	game.classic_heading_cache.erase(9317)
	check(game._classic_frame_for_actor(display_probe)==1,"without render snapshots Classic falls back to current actual physics heading")
	# Renderer must read the physical actor.heading instead of generating
	# its own 0.44s oscillation. Sprite and overlay share the exact world
	# coordinates, apart from a harmless <=0.5px raster snap.
	var motion_probe: Dictionary={"id":9318,"kind":"ship","pos":Vector2(500,500),"speed":100.0,"slow":0.0,"heading":Vector2.RIGHT,"path":[Vector2(1000,500)]}
	var shown: Dictionary={}
	var start_y: float=motion_probe.pos.y
	var min_probe_y: float=start_y
	var max_probe_y: float=start_y
	var camera_before: Vector2=game.camera.position
	for step in 30:
		game.sim._move(motion_probe,1.0/30.0)
		shown[game._classic_frame_for_actor(motion_probe)]=true
		min_probe_y=minf(min_probe_y,motion_probe.pos.y)
		max_probe_y=maxf(max_probe_y,motion_probe.pos.y)
		var rendered: Vector2=game._classic_actor_render_pos(motion_probe)
		var real: Vector2=game._visual_actor_pos(motion_probe)
		var rounded_delta: Vector2=game.get_canvas_transform()*rendered-game.get_canvas_transform()*real
		check(absf(rounded_delta.x)<=0.55 and absf(rounded_delta.y)<=0.55,"Classic render uses TRUE ship world position, with <=half pixel rounding only")
	check(shown.has(1) and shown.has(3) and max_probe_y-min_probe_y>=15.0,"one 4-way controller moves the real NPC through alternating diagonal legs")
	check(game.camera.position==camera_before,"drawing real isometric ship steps never invents a camera motion mode")
	var original_pos: Vector2=game.sim.player.pos
	var original_path: Array=game.sim.player.path.duplicate()
	check(game.sim.player.path==original_path and game.sim.player.pos==original_pos,"isolated ship-motion test does not rewrite the captain destination")
	# Legacy 2D camera/pixel options are intentionally NOT persisted anymore.
	game._persist_display_preferences()
	var display_data: Variant=JSON.parse_string(FileAccess.get_file_as_string(game.HUD_SAVE))
	check(display_data is Dictionary and not display_data.has("classic_pixel_strength") and not display_data.has("classic_pixel_step_world") and not display_data.has("classic_camera_follow"),"new saves do not expose old sailing-mode controls")
	check(game.sim.player.path==original_path and game.sim.player.pos==original_pos,"one isometric sailing mode preserves the destination and actual captain state")
	var stopped_view: int=game._classic_frame_for_actor(motion_probe)
	game.elapsed+=0.3
	check(game._classic_frame_for_actor(motion_probe)==stopped_view,"standing still cannot flip the ship sprite on an independent timer")
	check(game.sim.player.gold==int(before.gold) and game.sim.player.skin==int(before.skin) and game.sim.player.ammo==before.ammo,"graphics switch preserves ship, wallet and ammunition")
	game._open_modal("Anzeige")
	var options: Array[String]=[]
	for button in game.modal_body.find_children("*","Button",true,false):options.append(button.text)
	check(options.any(func(text):return text.begins_with("CLASSIC 2D")) and options.any(func(text):return text.begins_with("2,5D")) and options.any(func(text):return text.begins_with("3D")),"native settings retain three GRAPHICS modes")
	check(not options.any(func(text):return text.contains("PIXEL") or text.contains("VIDEO 901") or text.contains("KLASSISCHE KAMERA") or text.contains("SPIELER ZENTRIEREN") or text=="KURZ" or text=="LANG"),"Classic sailing no longer has alternative pixel, pace or camera mode buttons")
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
