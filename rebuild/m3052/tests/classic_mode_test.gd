extends SceneTree
const SIM=preload("res://simulation.gd")
const VISUALS=preload("res://ship_visuals.gd")
const NAV=preload("res://navigation.gd")
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
	# The 2013 original-era clone documented a 48x32 STAGGERED tile
	# grid. Four screen facings follow real +/-24,+/-16 tile steps.
	check(is_equal_approx(NAV.ISO_TILE_WIDTH,48.0) and is_equal_approx(NAV.ISO_TILE_HEIGHT,32.0),"historical Classic raster tile is precisely 48x32")
	# Euclidean-nearest centre is NOT the same as the diamond that owns
	# the screen click. This formerly selected a neighbour near the tips.
	check(NAV.classic_tile_center(NAV.classic_world_to_tile(Vector2(15,4)))==Vector2.ZERO,"diamond-corner click belongs to its actual 48x32 tile, not Euclidean-nearest neighbour")
	check(NAV.classic_tile_center(Vector2i.ZERO)==Vector2(24,16) and NAV.classic_tile_center(Vector2i(1,0))==Vector2(48,32) and NAV.classic_tile_center(Vector2i(0,1))==Vector2(0,32),"fixed staggered chart grid alternates even/odd rows exactly like public Sea-Bandits source")
	for tile_coord in [Vector2i(-20,0),Vector2i(0,0),Vector2i(27,-18),Vector2i(70,40)]:
		check(NAV.classic_world_to_tile(NAV.classic_tile_center(tile_coord))==tile_coord,"world-to-tile roundtrip preserves global lattice "+str(tile_coord))
	check(NAV.classic_iso_route(Vector2(500,500),Vector2(950,500))[0]!=NAV.classic_iso_route(Vector2(510,500),Vector2(950,500))[0] or NAV.classic_world_to_tile(Vector2(500,500))==NAV.classic_world_to_tile(Vector2(510,500)),"raster remains anchored to world, not reset to each starting pixel")
	for raster_goal: Vector2 in [Vector2(700,0),Vector2(-700,0),Vector2(0,700),Vector2(0,-700),Vector2(600,40),Vector2(-250,-400)]:
		var micro_path: Array[Vector2]=NAV.classic_iso_route(Vector2.ZERO,raster_goal)
		check(not micro_path.is_empty() and micro_path.back().distance_to(raster_goal)<0.001,"48x32 path reaches its clicked endpoint: "+str(raster_goal))
		var from: Vector2=Vector2.ZERO
		var step_ok: bool=true
		for index in micro_path.size()-1:
			var shift: Vector2=micro_path[index]-from
			step_ok=step_ok and is_equal_approx(absf(shift.x),24.0) and is_equal_approx(absf(shift.y),16.0)
			from=micro_path[index]
		check(step_ok,"every actual intermediate step lands on a 24x16 iso tile neighbour: "+str(raster_goal))
		check((raster_goal-from).dot(raster_goal.normalized())>=-0.001,"final short correction never reverses beyond clicked goal: "+str(raster_goal))
	# Mobile Classic fixes must affect only camera/ship presentation.
	check(is_equal_approx(0.60*0.94/0.45,1.2533333),"Classic touch/desktop framing is explicitly recalibrated for larger ships and closer zoom")
	var sim=SIM.new();sim.npcs.clear();sim.player.pos=Vector2(500,500)
	sim.set_classic_steering(true)
	# Motion speed is measured by actual path length, not straight-line
	# displacement. Exactly 1s of baseline sailing should traverse ~76
	# physical pixels regardless of how many diagonals are crossed.
	check(is_equal_approx(SIM.CLASSIC_TILE_SAIL_SPEED,76.0),"Classic baseline equals calibrated slow tile cadence")
	var pace_start: Vector2=NAV.classic_tile_center(NAV.classic_world_to_tile(Vector2(500,500)))
	var pace_probe: Dictionary={"id":0,"kind":"ship","pos":pace_start,"heading":Vector2.RIGHT,"speed":SIM.PLAYER_SPEED,"slow":0.0,"path":[pace_start+Vector2(800,0)]}
	var travel_distance: float=0.0
	for frame in 30:
		var before: Vector2=pace_probe.pos
		sim._move(pace_probe,1.0/30.0)
		travel_distance+=before.distance_to(Vector2(pace_probe.pos))
	check(absf(travel_distance-SIM.CLASSIC_TILE_SAIL_SPEED)<2.0,"one second of Classic sailing advances 76px along real tile legs (not 165+ 2x speed multiplier)")
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
			sim._advance_world_course(trial,165.0/30.0,true)
			visited_steps+=1
			max_cross_track=maxf(max_cross_track,absf(Vector2(trial.pos).cross(heading_target.normalized())))
			if not trial.path.is_empty() and Vector2(trial.pos).distance_to(heading_target)>32.0:
				check(VISUALS.heading_four(trial.heading) in [1,3,5,7],"physical heading uses an actual four-way tile step "+str(heading_target))
		check(trial.path.is_empty() and Vector2(trial.pos).distance_to(heading_target)<0.1,"all Classic tap directions reach exact clicked target "+str(heading_target))
		check(max_cross_track<29.0 and visited_steps<1800,"isometric raster remains within one half-tile of the requested world line "+str(heading_target))
	# A new target changes the real course immediately with no compulsory
	# 24x16 detour to an old tile centre or sudden teleport.
	var retap_probe: Dictionary={"id":0,"pos":Vector2.ZERO,"heading":Vector2.RIGHT,"path":[Vector2(700,0)]}
	for step in 40:sim._advance_world_course(retap_probe,165.0/30.0,true)
	var retap_start: Vector2=Vector2(retap_probe.pos)
	var new_goal: Vector2=retap_start+Vector2(-250,-400)
	retap_probe.path=[new_goal]
	sim._advance_world_course(retap_probe,1.0,true)
	check(not retap_probe.has("_iso_committed_step") and retap_probe.get("_iso_route",[]).back()==new_goal and retap_probe.pos.distance_to(retap_start)<=1.1,"retap rebuilds new grid destination immediately without jump or old tile lock")
	for tick in 900:
		if retap_probe.path.is_empty():break
		sim._advance_world_course(retap_probe,165.0/30.0,true)
	check(retap_probe.path.is_empty() and Vector2(retap_probe.pos).distance_to(new_goal)<0.1,"redirected direct course reaches exact destination")
	sim.set_classic_steering(false)
	var goal:=Vector2(1200,500)
	check(sim.classic_steering,"all ship renderers use one default 48x32 navigation")
	check(sim.course(goal),"water tap creates a course")
	check(sim.player.path.size()==1 and sim.player.path[0]==goal,"native 3D and 2D share the same clicked high-level destination")
	var initial_route: Array=sim.player.path.duplicate()
	var initial_pos: Vector2=sim.player.pos
	sim.set_classic_steering(true)
	check(sim.classic_steering and sim.player.path==initial_route and sim.player.pos==initial_pos,"switching to Classic never rewrites the physical route or teleports the captain")
	check(sim.player.path.size()==1 and sim.player.path[0]==goal,"shared high-level destination stays one click, while physical legs follow the isometric lattice")
	var stock: Array=sim.player.ammo.duplicate()
	var horizontal_facings: Dictionary={}
	var start_y: float=sim.player.pos.y
	var max_y_error: float=0.0
	for step in 900:
		sim._move(sim.player,1.0/60.0)
		max_y_error=maxf(max_y_error,absf(float(sim.player.pos.y)-start_y))
		if not sim.player.path.is_empty():horizontal_facings[VISUALS.heading_four(sim.player.heading)]=true
		if sim.player.path.is_empty():break
	check(max_y_error>=8.0 and max_y_error<35.0 and horizontal_facings.has(1) and horizontal_facings.has(3),"horizontal Classic physically alternates NE/SE raster steps rather than fake sprite motion")
	check(sim.player.pos.distance_to(goal)<0.1 and sim.player.path.is_empty() and sim.player.ammo==stock,"raster Classic sailing arrives exactly without changing ammunition")
	# Clicking a chart position selects one deterministic isometric tile.
	# Harbor/portal scripted routes continue accepting exact coordinates.
	var raw_click: Vector2=Vector2(1207,507)
	var snapped: Vector2=sim._classic_clicked_target(raw_click)
	check(snapped==NAV.classic_tile_center(NAV.classic_world_to_tile(raw_click)),"chart tap maps into nearest GLOBAL diamond-tile center")
	var interior_tile: Vector2=NAV.classic_tile_center(NAV.classic_world_to_tile(Vector2(4200,2900)))
	var corner_click: Vector2=interior_tile+Vector2(-9,-12)
	var actual_containing: Vector2=interior_tile-Vector2(24,16)
	check(NAV.classic_tile_center(NAV.classic_world_to_tile(corner_click))==actual_containing,"corner diamond point resolves to owning staggered water tile")
	check(sim._classic_clicked_target(corner_click)==actual_containing,"gameplay water tap keeps owning tile even when neighboring center is Euclidean closer")
	check(sim.course(raw_click,true) and sim.player.path.back()==snapped,"tap course destination is the exact selected tile rather than raw fractional pixels")
	var snapped_path: Array[Vector2]=NAV.classic_iso_route(sim.player.pos,snapped)
	check(not snapped_path.is_empty() and snapped_path.back()==snapped and NAV.classic_world_to_tile(snapped_path.back())==NAV.classic_world_to_tile(raw_click),"tile course has no non-isometric final tail")
	sim.player.path=[]
	var diagonal_goal:=Vector2(1600,850)
	check(sim.course(diagonal_goal) and sim.player.path==sim.plan_path(sim.player.pos,diagonal_goal),"Classic keeps exact clicked destinations while physical route traverses diamond steps")
	sim._move(sim.player,0.25)
	var corner: Vector2=sim.player.pos
	check(sim.course(Vector2(300,850)) and sim.player.path.back()==Vector2(300,850),"new tap immediately replaces the course")
	check(not sim.player.has("_iso_committed_step"),"new click never locks old raster microstep")
	sim._move(sim.player,.01)
	check(sim.player.pos.distance_to(corner)<2.0 and not sim.player.get("_iso_route",[]).is_empty() and Vector2(sim.player.get("_iso_route",[]).back())==Vector2(300,850),"retap immediately selects a new authentic 48x32 path, without a teleport")
	var changing_route: Array=sim.player.path.duplicate()
	var switch_origin: Vector2=sim.player.pos
	sim.set_classic_steering(false)
	check(sim.classic_steering and sim.player.pos==switch_origin and sim.player.path==changing_route,"native 3D cannot disable 48x32 grid steering or change current course")
	var npc_body: Dictionary={"pos":Vector2(500,500),"heading":Vector2.RIGHT,"kind":"ship"}
	var npc_direct: Array[Vector2]=sim.plan_actor_path(npc_body,Vector2(1200,500))
	check(npc_direct.size()==1 and npc_direct[0]==Vector2(1200,500),"native NPC stores a single patrol destination; real movement still uses shared diamond route")
	sim.set_classic_steering(true)
	var npc_classic: Array[Vector2]=sim.plan_actor_path(npc_body,Vector2(1200,500))
	check(npc_classic==npc_direct,"Classic NPCs keep the same high-level waypoints, then execute tile raster locally")
	var monster: Dictionary={"pos":Vector2(500,500),"heading":Vector2.RIGHT,"kind":"monster"}
	check(sim.plan_actor_path(monster,Vector2(1200,500))==npc_direct,"sea monsters keep direct navigation in every mode")
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame;game.set_process(false)
	var before: Dictionary=game.sim.export_save()
	game._set_render_mode("3d");await process_frame
	check(game.sim.classic_steering and game.render_mode=="3d","native 3D uses identical raster steering")
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
	check(game.sim.classic_steering and game.sim.player.path.back()==destination and game.sim.player.path==course and game.sim.player.pos==Vector2(before.position[0],before.position[1]),"2D/3D render switch preserves raster path and captain position")
	check(is_equal_approx(game._actor_visual_length(game.sim.player),native_player_length),"Classic captain has SAME world-length as real 3D GLB")
	check(is_equal_approx(game.CLASSIC_HULL_SCALE_MOBILE,1.0) and is_equal_approx(game.CLASSIC_MOBILE_CAMERA_FACTOR,1.0),"Android/iOS Classic uses SAME baseline ship size and zoom as 3D")
	check(is_equal_approx(game.CLASSIC_HULL_SCALE_MOBILE,game.CLASSIC_HULL_SCALE),"desktop and mobile Classic hull have no hidden size differential")
	check(is_equal_approx(game._actor_visual_length(game.sim.npcs[0]),native_npc_length),"Classic and 3D NPC hulls use identical physical sizes")
	# M368: Only the authoritative course and world coordinates are
	# shared. The Classic 2D camera deliberately uses edge-follow while
	# native 3D is centered on the captain. Never assert matching cameras.
	var camera_start: Vector2=game._visual_actor_pos(game.sim.player)
	game.browser_classic=true
	game.camera_locked=true
	game.loading_left=0.0
	game.camera.position=camera_start+Vector2(300,170)
	var expected_first: Vector2=game._classic_edge_camera_goal(camera_start,game.camera.position,game.get_viewport_rect().size/maxf(game.camera.zoom.x,0.05))
	game._process(0.0)
	check(game.camera.position.distance_to(expected_first)<0.001,"2D Classic camera retains independent edge framing inside the safe area")
	game.camera.position=camera_start+Vector2(-520,-280)
	var expected_second: Vector2=game._classic_edge_camera_goal(camera_start,game.camera.position,game.get_viewport_rect().size/maxf(game.camera.zoom.x,0.05))
	game._process(0.0)
	check(game.camera.position.distance_to(expected_second)<0.001,"2D Classic camera only scrolls as needed at a viewport edge")
	game.camera_anchor=game.sim.player.pos
	game._shift_camera(Vector2(180,90))
	check(not game.camera_locked,"manual Classic camera-pad inspection still unlocks captain following")
	game._recenter_camera()
	check(game.camera_locked and game.camera.position.distance_to(game.sim.player.pos)<0.001,"recenter resumes Classic player view without rewriting the physical sailing course")
	var path_before_framing: Array=game.sim.player.path.duplicate()
	var saved_position: Vector2=game.sim.player.pos
	for viewport_size: Vector2i in [Vector2i(844,390),Vector2i(2340,1080)]:
		root.size=viewport_size
		await process_frame
		var expected_boost: float=clampf(float(viewport_size.y)/720.0,1.0,game.CLASSIC_VIEWPORT_ZOOM_BOOST_MAX)
		check(is_equal_approx(game._sharp_zoom(),game.desired_zoom*expected_boost),"Classic no longer magnifies ships by desktop-density viewport scaling at "+str(viewport_size))
		game.camera.position=game.sim.player.pos
		var preserved_zoom: float=game.desired_zoom
		game._layout()
		check(is_equal_approx(game.desired_zoom,preserved_zoom) and preserved_zoom>1.0,"compact phone HUD never forces the old 0.78 zoom")
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
	# Validate eight-view headings on a PARKED ship. An actively sailing
	# Classic draws the exact 24x16 physical microleg, with the four
	# original diagonal atlased hull views (both 2D and 3D sail this path).
	var parked_heading_probe: Dictionary={"id":9371,"kind":"ship","pos":game.sim.player.pos,
		"heading":Vector2(1,-1),"path":[]}
	check(game._classic_frame_for_actor(parked_heading_probe)==1,"parked Classic renderer selects the true NE atlas frame")
	parked_heading_probe.heading=Vector2(1,1)
	check(game._classic_frame_for_actor(parked_heading_probe)==3,"parked Classic renderer changes facing without changing world coordinates")
	game.classic_heading_cache.erase(9371)
	# Tick crosses an EXACT (24,-16) NE tile and a (24,+16) SE tile.
	# Interpolation and facing must preserve the actual two corners.
	var two_steps: Array[Dictionary]=[
		{"start":Vector2(500,500),"end":Vector2(524,484),"heading":Vector2(24,-16).normalized(),"distance":sqrt(832.0)},
		{"start":Vector2(524,484),"end":Vector2(548,500),"heading":Vector2(24,16).normalized(),"distance":sqrt(832.0)}
	]
	var frame_probe: Dictionary={"id":9316,"kind":"ship","pos":Vector2(548,500),"heading":Vector2.RIGHT,"_iso_tick_segments":two_steps}
	game.visual_before[9316]=Vector2(500,500)
	game.visual_after[9316]=Vector2(548,500)
	var saved_fraction: float=game.accumulator
	game.accumulator=game.SIMULATION_TICK*0.25
	var first_position: Vector2=game._visual_actor_pos(frame_probe)
	var first_frame: int=game._classic_frame_for_actor(frame_probe)
	game.accumulator=game.SIMULATION_TICK*0.75
	var second_position: Vector2=game._visual_actor_pos(frame_probe)
	var second_frame: int=game._classic_frame_for_actor(frame_probe)
	check(first_position.distance_to(Vector2(512,492))<0.01 and second_position.distance_to(Vector2(536,492))<0.01,"render interpolation follows physical tile corners without cutting through world")
	check(first_frame==1 and second_frame==3,"NE and SE raster tiles select their exact 2D hull images within same physics tick")
	game.accumulator=saved_fraction
	game.visual_before.erase(9316);game.visual_after.erase(9316)
	game.classic_heading_cache.erase(9316)
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
	# Draw the real 48x32 raster line and verify plate rounding is <=0.5px.
	var motion_probe: Dictionary={"id":9318,"kind":"ship","pos":Vector2(500,500),"speed":100.0,"slow":0.0,"heading":Vector2.RIGHT,"path":[Vector2(1000,500)]}
	var shown: Dictionary={}
	var start_y_motion: float=motion_probe.pos.y
	var max_y_motion: float=0.0
	var max_visual_raster_y: float=0.0
	var camera_before: Vector2=game.camera.position
	for step in 120:
		var before_motion: Vector2=motion_probe.pos
		game.sim._move(motion_probe,1.0/30.0)
		game.visual_before[9318]=before_motion
		game.visual_after[9318]=motion_probe.pos
		game.accumulator=game.SIMULATION_TICK*0.5
		shown[game._classic_frame_for_actor(motion_probe)]=true
		var rendered: Vector2=game._classic_actor_render_pos(motion_probe)
		var raster: Dictionary=game._classic_raster_visual(motion_probe)
		var expected: Vector2=Vector2(raster.pos) if not raster.is_empty() else game._visual_actor_pos(motion_probe)
		var rounded_delta: Vector2=game.get_canvas_transform()*rendered-game.get_canvas_transform()*expected
		check(absf(rounded_delta.x)<=0.55 and absf(rounded_delta.y)<=0.55,"Classic snaps displayed RASTER position to <=0.5 screen pixels")
		max_y_motion=maxf(max_y_motion,absf(float(motion_probe.pos.y)-start_y_motion))
		max_visual_raster_y=maxf(max_visual_raster_y,absf(rendered.y-start_y_motion))
	check(max_y_motion>=8.0 and max_visual_raster_y>=8.0 and shown.has(1) and shown.has(3),"Classic 2D visibly follows the same real NE/SE tile steps as 3D")
	game.visual_before.erase(9318);game.visual_after.erase(9318)
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
	check(options.any(func(text):return text.begins_with("CLASSIC 2D")) and options.any(func(text):return text.begins_with("ECHTES 3D")) and not options.any(func(text):return text.contains("2,5D") or text.contains("HYBRID")),"native settings offer ONLY Classic 2D and real 3D")
	check(not options.any(func(text):return text.contains("PIXEL") or text.contains("VIDEO 901") or text.contains("KLASSISCHE KAMERA") or text.contains("SPIELER ZENTRIEREN") or text=="KURZ" or text=="LANG"),"Classic sailing no longer has alternative pixel, pace or camera mode buttons")
	game.queue_free();await process_frame
	var reloaded=load("res://sea_map.tscn").instantiate();root.add_child(reloaded);current_scene=reloaded
	await process_frame;reloaded.set_process(false)
	check(reloaded.browser_classic and reloaded.render_mode=="classic" and reloaded.mesh_layer==null,"saved Classic preference starts natively without constructing 3D")
	reloaded._set_render_mode("3d");await process_frame
	check(not reloaded.browser_classic and reloaded.sim.classic_steering and reloaded.mesh_layer!=null and reloaded.mesh_layer.has_complete_fleet() and reloaded.render_mode=="3d","3D uses the same global raster with complete GLB fleet")
	check(is_equal_approx(reloaded._actor_visual_length(reloaded.sim.player),native_player_length),"3D captain hull size remains exactly unchanged")
	reloaded._set_render_mode("classic");await process_frame
	reloaded._set_render_mode("hybrid");await process_frame
	check(not reloaded.browser_classic and reloaded.sim.classic_steering and reloaded.render_mode=="3d" and reloaded.mesh_layer!=null,"legacy 2.5D requests migrate to real 3D without changing sea navigation")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
