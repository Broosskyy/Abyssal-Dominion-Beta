extends SceneTree
## The ONLY mandatory equivalence of native 2D Classic and 3D is
## authoritative ship course and position. Cameras, raster sprite
## animation, visual frame choices and UI may differ freely.
const SIM=preload("res://simulation.gd")
var checks: int=0
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var two_d=SIM.new()
	var three_d=SIM.new()
	for world in [two_d,three_d]:
		world.islands.clear()
		world.npcs.clear()
		world.player.pos=Vector2(800,900)
		world._clear_classic_raster_state(world.player)
	# The old boolean is a compatibility argument; simulation steering
	# must not become renderer-specific again.
	two_d.set_classic_steering(true)
	three_d.set_classic_steering(false)
	check(two_d.classic_steering and three_d.classic_steering,"2D and 3D have identical physics regardless of visual mode")
	var destinations: Array[Vector2]=[
		Vector2(1600,300),Vector2(450,350),Vector2(1500,1400),
		Vector2(350,1200),Vector2(1500,900),Vector2(700,250)]
	for destination in destinations:
		var started_2d: bool=two_d.course(destination,true)
		var started_3d: bool=three_d.course(destination,true)
		check(started_2d and started_3d,"same tap accepted in 2D/3D: "+str(destination))
		check(two_d.player.path==three_d.player.path and two_d.player.get("_iso_route",[])==three_d.player.get("_iso_route",[]),"course and coast waypoints identical: "+str(destination))
		var same_track: bool=true
		var same_heading: bool=true
		for tick in 60:
			# Retap mid-sail and check both variants remain on the same
			# authoritative path, not their independent sprite microsteps.
			two_d._move(two_d.player,1.0/30.0)
			three_d._move(three_d.player,1.0/30.0)
			same_track=same_track and two_d.player.pos.distance_to(three_d.player.pos)<0.001
			same_heading=same_heading and two_d.player.heading.distance_to(three_d.player.heading)<0.001
		check(same_track and same_heading,"identical real per-tick coordinates and heading across modes: "+str(destination))
	# The renderer switch is not a sailing order and cannot touch
	# the route even during an active click-to-sail course.
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	game.sim.islands.clear()
	game.sim.player.pos=Vector2(700,900)
	game.sim._clear_classic_raster_state(game.sim.player)
	check(game.sim.course(Vector2(1200,550),true),"real captain course accepted")
	var before_pos: Vector2=game.sim.player.pos
	var before_path: Array=game.sim.player.path.duplicate(true)
	var before_route: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
	for classic: bool in [true,false,true,false]:
		game.browser_classic=classic
		game._classic_actor_render_pos(game.sim.player)
		game._classic_frame_for_actor(game.sim.player)
		check(game.sim.player.pos==before_pos and game.sim.player.path==before_path and game.sim.player.get("_iso_route",[])==before_route,"changing graphics or sampling 2D sprite cannot rewrite route, Classic="+str(classic))
	# Camera changes are pure presentation. 2D may scroll only near its
	# viewport edge while the 3D camera can follow the ship directly.
	game.browser_classic=true
	game.camera_locked=true
	game.loading_left=0.0
	game.camera.position=before_pos+Vector2(240,120)
	var before_camera_pos: Vector2=game.sim.player.pos
	game._process(0.0)
	check(game.sim.player.pos==before_camera_pos and game.sim.player.path==before_path,"independent Classic camera never moves the world")
	game.browser_classic=false
	game._process(0.0)
	check(game.sim.player.pos==before_camera_pos and game.sim.player.path==before_path,"native 3D camera never moves the world")
	game.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
