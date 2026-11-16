extends SceneTree
## M376: historical 48x32 utilities retain tile-coordinate tests,
## but the gameplay ship follows the same direct/coastal course in 2D and 3D.
const NAV=preload("res://navigation.gd")
const SIM=preload("res://simulation.gd")
var checks: int=0
var failed: Array[String]=[]
var barrier: Rect2=Rect2(4060,2865,130,80)

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failed.append(label)

func _clear_test_barrier(a: Vector2,b: Vector2) -> bool:
	var steps: int=maxi(1,ceili(a.distance_to(b)/2.0))
	for i in range(steps+1):
		if barrier.has_point(a.lerp(b,float(i)/float(steps))):return false
	return true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var start: Vector2=NAV.classic_tile_center(Vector2i(170,10))
	var goal: Vector2=NAV.classic_tile_center(Vector2i(182,-2))
	var direct: Array[Vector2]=NAV.classic_water_route(start,goal)
	check(direct.size()>5 and direct.back()==goal,"unobstructed water follows real global 48x32 tile neighbours")
	check(NAV.classic_safe_route(start,goal,func(_a,_b):return true)==direct,"safe planner uses identical physical raster legs when there are no obstacles")
	check(not _clear_test_barrier(start,goal),"test barrier genuinely crosses direct course")
	var detour: Array[Vector2]=NAV.classic_safe_route(start,goal,Callable(self,"_clear_test_barrier"))
	check(detour.size()>1 and detour.back()==goal,"blocked water plans a real coast detour")
	var previous: Vector2=start
	var safe: bool=true
	var length: float=0.0
	for waypoint: Vector2 in detour:
		safe=safe and _clear_test_barrier(previous,waypoint)
		length+=previous.distance_to(waypoint)
		previous=waypoint
	check(safe and length>start.distance_to(goal),"physical coastal A* tile itinerary avoids all land and shortcut segments")

	# Real simulation: the same direct line in all graphics.
	var sim=SIM.new()
	sim.npcs.clear()
	sim.islands.clear()
	var origin: Vector2=NAV.classic_tile_center(NAV.classic_world_to_tile(Vector2(500,500)))
	var target: Vector2=origin+Vector2(576,0)
	sim.player.pos=origin
	check(sim.course(target,true),"clear-water captain course accepted")
	var snapped: Vector2=sim._classic_clicked_target(target)
	var route: Array=sim.player.get("_iso_route",[])
	check(route.size()==1 and route.back()==snapped and sim.player.path==route,"click selects one tile endpoint; direct open-water movement inserts no physical diamonds")
	var max_cross: float=0.0
	var dist: float=0.0
	for frame in 650:
		if sim.player.path.is_empty():break
		sim._move(sim.player,1.0/30.0)
		# Sum real world segments, independent of sprite-facing animation.
		for leg: Dictionary in sim.player.get("_iso_tick_segments",[]):
			dist+=float(leg.get("distance",0.0))
		max_cross=maxf(max_cross,absf(sim.player.pos.y-origin.y))
	check(max_cross<0.01 and sim.player.pos.distance_to(snapped)<0.01 and sim.player.path.is_empty(),"physical ship travels a perfectly straight line without +/-16px zigzag")
	var expected_sailed: float=0.0
	var leg_start: Vector2=origin
	for next: Vector2 in route:
		expected_sailed+=leg_start.distance_to(next)
		leg_start=next
	check(absf(dist-expected_sailed)<0.1 and is_equal_approx(SIM.CLASSIC_TILE_SAIL_SPEED,76.0),"physical 2D/3D travel distance equals the direct route at unchanged sailing speed")

	# A mid-course retap redirects instantly with no leftover raster leg.
	sim.player.pos=origin
	check(sim.course(Vector2(1200,500),true),"initial retap test course accepted")
	for frame in 8:sim._move(sim.player,1.0/30.0)
	var mid: Vector2=sim.player.pos
	var new_target: Vector2=Vector2(300,750)
	check(sim.course(new_target,true),"redirected course accepted")
	check(not sim.player.has("_iso_committed_step") and sim.player.pos==mid,"retap does not restore obsolete tile lock or teleport")
	sim._move(sim.player,1.0/30.0)
	check(sim.player.get("_iso_route",[]).size()==1 and Vector2(sim.player.get("_iso_route",[]).back())==sim._classic_clicked_target(new_target) and sim.player.pos.distance_to(mid)<3.0,"retapped vessel immediately replans one direct waypoint without teleporting")

	# Coastline is validated against actual collision geometry, not merely
	# a decorative tile edge or an optimistic long obstacle sample.
	var polygon: PackedVector2Array=PackedVector2Array([barrier.position,barrier.position+Vector2(barrier.size.x,0),barrier.end,barrier.position+Vector2(0,barrier.size.y)])
	sim.islands.append({"bounds":barrier,"outline":polygon})
	sim.player.pos=start
	sim.player.path.clear()
	sim._clear_classic_raster_state(sim.player)
	check(sim.course(goal,true),"island-safe course accepted")
	var actual: Array=sim.player.path.duplicate()
	check(actual.size()>1 and actual.back()==goal,"live ship chooses an actual coastline A* detour")
	var p: Vector2=start
	var all_clear: bool=true
	for waypoint: Vector2 in actual:
		all_clear=all_clear and sim.segment_free(p,waypoint,2.0)
		p=waypoint
	check(all_clear,"every direct/coastal segment remains collision safe")
	var ticks: int=0
	while not sim.player.path.is_empty() and ticks<1800:
		sim._move(sim.player,1.0/30.0)
		ticks+=1
	check(ticks<1800 and sim.player.pos.distance_to(goal)<0.01,"coastal voyage reaches destination without being trapped")

	print(JSON.stringify({"status":"PASS" if failed.is_empty() else "FAIL","checks":checks,"failures":failed}))
	quit(0 if failed.is_empty() else 1)
