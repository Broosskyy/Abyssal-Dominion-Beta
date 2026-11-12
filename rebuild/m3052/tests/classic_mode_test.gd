extends SceneTree
const SIM=preload("res://simulation.gd")
const VISUALS=preload("res://ship_visuals.gd")
const NAV=preload("res://navigation.gd")
var checks:=0
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	# The four historical Classic facings use the diagonal frames from the
	# eight baked 2D sprites. Each frame follows a true diagonal leg.
	for heading: Vector2 in [Vector2(1,-1),Vector2(-1,-1),Vector2(-1,1),Vector2(1,1)]:
		var expected: int=[1,7,5,3][[Vector2(1,-1),Vector2(-1,-1),Vector2(-1,1),Vector2(1,1)].find(heading)]
		check(VISUALS.heading_four(heading)==expected,"four-way Classic graphic selects correct baked diagonal "+str(heading))
	for heading: Vector2 in [Vector2.RIGHT,Vector2.UP,Vector2.LEFT,Vector2.DOWN,Vector2(5,2),Vector2(-8,1)]:
		check(VISUALS.heading_four(heading) in [1,3,5,7],"every ordinary captain heading chooses exactly one of the four Classic frames")
	# Four rendered directions are derived from actual 45-degree travel legs.
	for heading: Vector2 in [Vector2.RIGHT,Vector2.UP,Vector2.LEFT,Vector2.DOWN]:
		check(VISUALS.heading_four(heading) in [1,3,5,7],"cardinal lookups have a safe static fallback")
	var compass: Array[Vector2]=NAV.classic_compass_leg(Vector2(500,500),Vector2(1200,500),SIM.CLASSIC_MAX_CROSS_OFFSET)
	check(compass.size()>=6 and compass.back()==Vector2(1200,500),"short real diagonal legs connect a horizontal tap to its exact destination")
	var cursor: Vector2=Vector2(500,500)
	var diagonals: Dictionary={}
	var peak_offset: float=0.0
	for waypoint: Vector2 in compass:
		var delta: Vector2=waypoint-cursor
		check(absf(absf(delta.x)-absf(delta.y))<0.02,"every ordinary Classic leg moves exactly 45 degrees")
		diagonals[VISUALS.heading_four(delta)]=true
		peak_offset=maxf(peak_offset,absf(waypoint.y-500.0))
		cursor=waypoint
	check(diagonals.has(1) and diagonals.has(3),"Classic alternates real NE and SE travel rather than faking a sprite flip")
	check(peak_offset<=SIM.CLASSIC_MAX_CROSS_OFFSET+0.01 and peak_offset>=SIM.CLASSIC_MAX_CROSS_OFFSET-0.01,"physical deviation stays bounded around the tapped course")
	# Comparison with user's 208797 reference: ~0.20 s repeated swaps
	# mixed with 1+ second stable oblique voyages. This emerges from
	# spatial correction to the tapped course, NOT a frame clock pattern.
	var horizontal_interior_leg: Vector2=compass[2]-compass[1]
	var horizontal_dwell: float=horizontal_interior_leg.length()/SIM.PLAYER_SPEED
	check(absf(horizontal_dwell-0.206)<0.025,"horizontal Classic heading changes about every 0.2 seconds at the captain's nominal sailing speed")
	var slanted: Array[Vector2]=NAV.classic_compass_leg(Vector2(500,500),Vector2(1000,925),SIM.CLASSIC_MAX_CROSS_OFFSET)
	var last: Vector2=Vector2(500,500)
	var short_duration: float=10000.0
	var long_duration: float=0.0
	for target_point: Vector2 in slanted:
		var leg_seconds: float=(target_point-last).length()/SIM.PLAYER_SPEED
		short_duration=minf(short_duration,leg_seconds)
		long_duration=maxf(long_duration,leg_seconds)
		last=target_point
	check(slanted.back()==Vector2(1000,925) and short_duration<0.2 and long_duration>1.0,"angled courses produce quick corrections and long steady facings without a fixed pose timer")
	for diagonal: Vector2 in [Vector2(1,-1),Vector2(1,1),Vector2(-1,1),Vector2(-1,-1)]:
		var direct_diagonal: Array[Vector2]=NAV.classic_compass_leg(Vector2(500,500),Vector2(500,500)+diagonal*350,SIM.CLASSIC_MAX_CROSS_OFFSET)
		check(direct_diagonal.size()==1,"an exactly diagonal course keeps one facing without fake turns")
	var sim=SIM.new();sim.npcs.clear();sim.player.pos=Vector2(500,500)
	var goal:=Vector2(1200,500)
	check(not sim.classic_steering,"native default uses direct navigation")
	check(sim.course(goal),"water tap creates a course")
	check(sim.player.path.size()==1 and sim.player.path[0]==goal,"native open water follows one direct line")
	var initial_pos: Vector2=sim.player.pos
	sim.set_classic_steering(true)
	check(sim.classic_steering and sim.player.pos==initial_pos,"switching to Classic never teleports the captain")
	check(sim.player.path.size()>4 and sim.player.path.back()==goal,"Classic replans as real short diagonal sailing legs")
	var stock: Array=sim.player.ammo.duplicate()
	var seen_headings: Dictionary={}
	var maximum_drift: float=0.0
	for step in 900:
		sim._move(sim.player,1.0/60.0)
		if not sim.player.path.is_empty():
			var heading: Vector2=sim.player.heading
			check(absf(absf(heading.x)-absf(heading.y))<0.01,"a real Classic captain moves along a diagonal heading")
			seen_headings[VISUALS.heading_four(heading)]=true
		maximum_drift=maxf(maximum_drift,absf(float(sim.player.pos.y)-500.0))
		if sim.player.path.is_empty():break
	check(seen_headings.has(1) and seen_headings.has(3),"real Classic sailing faces NE and SE during a horizontal trip")
	check(maximum_drift>5 and maximum_drift<=SIM.CLASSIC_MAX_CROSS_OFFSET+0.02,"physical course actually changes diagonally but remains close to the tapped line")
	check(sim.player.pos.distance_to(goal)<0.01 and sim.player.ammo==stock,"Classic reaches precise destination without using ammunition")
	var diagonal_goal:=Vector2(1600,850)
	check(sim.course(diagonal_goal) and sim.player.path.back()==diagonal_goal and sim.player.path.size()>1,"Classic preserves arbitrary diagonal target while using only four real diagonal headings")
	sim._move(sim.player,0.25)
	var corner: Vector2=sim.player.pos
	check(sim.course(Vector2(300,850)) and sim.player.path.back()==Vector2(300,850),"new tap immediately replaces the course")
	sim._move(sim.player,.01)
	check(sim.player.heading.x<0 and sim.player.pos.distance_to(corner)<2,"retap takes effect without turn circle or teleport")
	var changing_route: Array=sim.player.path.duplicate()
	var switch_origin: Vector2=sim.player.pos
	sim.set_classic_steering(false)
	check(not sim.classic_steering and sim.player.pos==switch_origin and sim.player.path.back()==changing_route.back() and sim.player.path==sim.plan_path(switch_origin,changing_route.back()),"returning to 3D replans DIRECT movement without moving the captain")
	var npc_body: Dictionary={"pos":Vector2(500,500),"heading":Vector2.RIGHT,"kind":"ship"}
	var npc_direct: Array[Vector2]=sim.plan_actor_path(npc_body,Vector2(1200,500))
	check(npc_direct.size()==1 and npc_direct[0]==Vector2(1200,500),"native NPC patrol ship follows direct courses")
	sim.set_classic_steering(true)
	var npc_classic: Array[Vector2]=sim.plan_actor_path(npc_body,Vector2(1200,500))
	check(npc_classic.size()>3 and npc_classic.back()==npc_direct.back(),"Classic NPC ships follow real diagonal legs to the same final goal")
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
	check(game.sim.classic_steering and game.sim.player.path.back()==destination and game.sim.player.path!=course and game.sim.player.pos==Vector2(before.position[0],before.position[1]),"Classic 2D replans real four-heading legs without teleporting the player")
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
	# Verify ACTUAL leg headings drive the atlas. No timer, no fake sway.
	var compass_probe: Array[Vector2]=NAV.classic_compass_leg(Vector2(500,500),Vector2(1200,500),SIM.CLASSIC_MAX_CROSS_OFFSET)
	var motion_probe: Dictionary={"id":9318,"pos":Vector2(500,500),"speed":100.0,"heading":Vector2.RIGHT}
	var shown: Dictionary={}
	var original_route: Array=game.sim.player.path.duplicate()
	var original_pos: Vector2=game.sim.player.pos
	var previous_point: Vector2=motion_probe.pos
	for point: Vector2 in compass_probe:
		motion_probe.heading=(point-previous_point).normalized()
		motion_probe.pos=point
		shown[game._classic_frame_for_actor(motion_probe)]=true
		previous_point=point
	check(shown.has(1) and shown.has(3),"renderer displays correct NE/SE for genuinely changing course")
	check(game.sim.player.path==original_route and game.sim.player.pos==original_pos,"rendering never alters physical world coordinates or navigation path")
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
