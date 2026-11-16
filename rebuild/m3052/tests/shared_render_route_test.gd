extends SceneTree
## Regression for user requirement: 2D and 3D are graphics modes ONLY.
## Both clients, starting at the same position and clicking the same
## coordinate, MUST sail the same direct/coast world path on every tick.
## The 48x32 diamond grid resolves click targets, never physical zigzag.
const SIM=preload("res://simulation.gd")
const NAV=preload("res://navigation.gd")
var checks: int=0
var failures: Array[String]=[]

class CapturingConnection:
	extends Node
	var calls: Array[Dictionary]=[]
	func send_course(point: Vector2,route: Array=[],navigation_mode: String="",raster_preexpanded: bool=false) -> void:
		calls.append({"goal":point,"route":route.duplicate(true),"mode":navigation_mode,"preexpanded":raster_preexpanded})

func check(condition: bool,description: String) -> void:
	checks+=1
	if not condition:failures.append(description)

func _initialize() -> void:
	call_deferred("_run")

func _reset(game: Node,origin: Vector2) -> void:
	game.sim.player.pos=origin
	game.sim.player.path.clear()
	game.sim._clear_classic_raster_state(game.sim.player)
	game.sim.player.heading=Vector2.RIGHT

func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false)
	var start: Vector2=Vector2(500,500)
	var target: Vector2=Vector2(1152,500)
	var destination: Vector2=game.sim._classic_clicked_target(target)
	_reset(game,start)
	game._set_render_mode("classic")
	check(game.render_mode=="classic" and game.sim.classic_steering and game.mesh_layer==null,"native Classic 2D loads without 3D and shares physical movement")
	check(game.sim.course(target,true),"Classic water click creates a single direct water course")
	var course_2d: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
	check(course_2d.size()==1 and course_2d.back()==destination,"2D open-water route contains one direct waypoint at the selected diamond centre")
	var baseline=SIM.new()
	baseline.npcs.clear()
	baseline.player.pos=start
	baseline.player.speed=game.sim.player.speed
	check(baseline.classic_steering and baseline.course(target,true),"independent second vessel plans the same direct course without graphics")
	check(baseline.player.get("_iso_route",[])==course_2d,"2D and native 3D share byte-identical direct route for the same world coordinates")

	# Switch modes while mid-voyage. This catches any unexpected course
	# reset, world heading change or coordinate jump on graphics toggle.
	var switched_inflight: bool=false
	var same_track: bool=true
	var lateral_error: float=0.0
	var course_direction: Vector2=(destination-start).normalized()
	for tick in 330:
		if tick==6:
			var old_pos: Vector2=game.sim.player.pos
			var old_heading: Vector2=game.sim.player.heading
			var old_path: Array=game.sim.player.path.duplicate(true)
			var old_route: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
			var old_index: int=int(game.sim.player.get("_iso_route_index",-1))
			game._set_render_mode("3d")
			switched_inflight=true
			check(game.render_mode=="3d" and not game.browser_classic and game.mesh_layer!=null and game.sim.classic_steering,"real 3D GLB graphics keep the shared navigation engine enabled")
			check(game.sim.player.pos==old_pos and game.sim.player.heading==old_heading and game.sim.player.path==old_path,"switch to 3D never teleports, turns or replaces active destination")
			check(game.sim.player.get("_iso_route",[])==old_route and int(game.sim.player.get("_iso_route_index",-1))==old_index,"switch to 3D preserves the active direct waypoint and route index")
		if tick==110:
			game._set_render_mode("classic")
			check(game.render_mode=="classic" and game.sim.classic_steering and game.mesh_layer==null,"returning to 2D also preserves shared world physics")
		game.sim._move(game.sim.player,1.0/30.0)
		baseline._move(baseline.player,1.0/30.0)
		lateral_error=maxf(lateral_error,absf((Vector2(game.sim.player.pos)-start).cross(course_direction)))
		if Vector2(game.sim.player.pos).distance_to(Vector2(baseline.player.pos))>0.001:
			same_track=false
			break
		if game.sim.player.path.is_empty() and baseline.player.path.is_empty():break
	check(switched_inflight and same_track,"switching between 2D/3D MID-VOYAGE yields EXACT SAME positions at every 30Hz tick")
	check(lateral_error<0.01,"both renderers sail a truly straight world course without physical raster wobble")
	check(game.sim.player.path.is_empty() and game.sim.player.pos.distance_to(destination)<0.001,"both views arrive on same clicked tile, not just approximate coordinates")

	# Two captains issuing the SAME course in the SAME world must send
	# matching protocol payloads; 3D previously advertised 'direct'.
	var transport=CapturingConnection.new()
	game.add_child(transport)
	game.online_client=transport
	game.online_connected=true
	_reset(game,start)
	game._set_render_mode("classic")
	check(game.sim.course(target,true),"2D multiplayer course accepted")
	game._send_online_course(target)
	var packet2d: Dictionary=transport.calls.back().duplicate(true)
	_reset(game,start)
	game._set_render_mode("3d")
	check(game.sim.course(target,true),"3D multiplayer course accepted")
	game._send_online_course(target)
	var packet3d: Dictionary=transport.calls.back().duplicate(true)
	check(packet2d==packet3d,"2D and 3D send bit-identical route, target, mode and preexpanded flag")
	check(str(packet2d.get("mode",""))=="classic_48x32" and bool(packet2d.get("preexpanded",false)),"3D does not use the server's old 165px/s direct navigation")
	check(packet2d.get("route",[]).size()==1 and packet2d.get("route",[]).back()==destination and packet2d.get("route",[])==course_2d,"2D/3D online payload transmits the same single direct destination, without old physical microsteps")
	# The wire protocol retains its original Classic speed profile
	# (76 world px/s), but raster_preexpanded now means 'use EXACT
	# client-validated waypoints', not 'recreate physical zigzag tiles'.
	var wire_steps: Array=packet2d.get("route",[])
	var collision_safe: bool=true
	var cursor: Vector2=start
	for waypoint: Vector2 in wire_steps:
		collision_safe=collision_safe and game.sim.segment_free(cursor,waypoint,2.0)
		cursor=waypoint
	check(collision_safe,"online direct-course legs remain coastline-safe at the same 2px precision as physics")
	# Legacy save or direct API request must not make a third mode.
	game._set_render_mode("hybrid")
	check(game.render_mode=="3d" and game.sim.classic_steering,"obsolete Hybrid request migrates to true 3D without changing shared navigation")

	game.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
