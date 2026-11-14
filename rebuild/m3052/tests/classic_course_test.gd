extends SceneTree
## The ship's 76px/s 48x32 movement is already approved. These tests change
## ONLY which tile route we choose for clicks near islands and mid-sail retaps.
const NAV=preload("res://navigation.gd")
const SIM=preload("res://simulation.gd")
var checks: int=0
var failed: Array[String]=[]
var barrier: Rect2=Rect2(4060,2865,130,80)

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failed.append(label)

func _clear_test_barrier(a: Vector2,b: Vector2) -> bool:
	var n: int=maxi(1,ceili(a.distance_to(b)/7.0))
	for i in range(n+1):
		if barrier.has_point(a.lerp(b,float(i)/float(n))):return false
	return true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# On a flat sea, the new safe route is BIT-FOR-BIT the previous
	# four-direction approved grid itinerary, not a redesigned animation.
	var start: Vector2=NAV.classic_tile_center(Vector2i(170,10))
	var goal: Vector2=NAV.classic_tile_center(Vector2i(182,-2))
	var old: Array[Vector2]=NAV.classic_iso_route(start,goal)
	var free: Array[Vector2]=NAV.classic_safe_route(start,goal,func(_a,_b):return true)
	check(free==old,"unobstructed courses preserve the exact validated Classic 344 tile sequence")
	# A solid vertical coastal obstacle crosses the DIRECT raster path.
	var crossing: bool=false
	var prior: Vector2=start
	for tile: Vector2 in old:
		if not _clear_test_barrier(prior,tile):crossing=true
		prior=tile
	check(crossing,"test island really intersects the old direct route")
	var detour: Array[Vector2]=NAV.classic_safe_route(start,goal,Callable(self,"_clear_test_barrier"))
	check(not detour.is_empty() and detour.back()==goal,"four-neighbour chart A* reaches requested clicked tile around island")
	var real_tile_steps: bool=true
	var all_clear: bool=true
	var max_bend: float=0.0
	prior=start
	for p: Vector2 in detour:
		var step: Vector2=p-prior
		real_tile_steps=real_tile_steps and is_equal_approx(absf(step.x),24.0) and is_equal_approx(absf(step.y),16.0)
		all_clear=all_clear and _clear_test_barrier(prior,p)
		max_bend=maxf(max_bend,absf(p.y-start.y))
		prior=p
	check(real_tile_steps,"every coastal detour leg still runs from true tile centre to 24x16 neighbour")
	check(all_clear,"coastal course never falls back to a forbidden straight line")
	check(max_bend>32.0,"coastal A* goes around obstacle rather than merely jittering through")

	# Integrate with live Simulation: plan before setting ship.path, keep
	# clicked destination visible, and verify physical sailing finishes.
	var sim=SIM.new()
	sim.npcs.clear()
	sim.set_classic_steering(true)
	var polygon: PackedVector2Array=PackedVector2Array([
		barrier.position,
		barrier.position+Vector2(barrier.size.x,0),
		barrier.end,
		barrier.position+Vector2(0,barrier.size.y)])
	sim.islands=[{"bounds":barrier,"outline":polygon}]
	sim.player.pos=start
	var underway: bool=sim.course(goal,true)
	check(underway and sim.player.path.size()==1 and Vector2(sim.player.path.back())==goal,"click plans a single terminal marker with precomputed safe raster itinerary")
	var planned: Array=sim.player.get("_iso_route",[])
	check(planned.size()>old.size() and planned.back()==goal,"course stores one global island-safe tile route, no square-grid intermediate destinations")
	prior=start
	var all_safe: bool=true
	for waypoint: Vector2 in planned:
		all_safe=all_safe and sim.segment_free(prior,waypoint)
		prior=waypoint
	check(all_safe,"actual simulation's coastline margin is checked for each preplanned raster segment")
	# Sim speed (76px/s), sprite bearing and arrival must not change.
	var count: int=0
	while not sim.player.path.is_empty() and count<1500:
		sim._move(sim.player,1.0/30.0)
		count+=1
	check(count<1500 and sim.player.pos.distance_to(goal)<0.1,"full simulated voyage safely reaches requested tile at normal approved speed")
	check(is_equal_approx(SIM.CLASSIC_TILE_SAIL_SPEED,76.0),"course fix leaves validated ship speed unchanged")

	# Mid-sail retap: plan from already committed NEXT tile centre, even
	# though the hull is still at a fractional point within that leg.
	sim.player.pos=start
	check(sim.course(goal,true),"first coastal course accepted")
	for frame in range(8):sim._move(sim.player,1.0/30.0)
	var next_tile: Vector2=Vector2(sim.player["_iso_route"][int(sim.player["_iso_route_index"])])
	var new_goal: Vector2=NAV.classic_tile_center(Vector2i(176,12))
	var new_course: bool=sim.course(new_goal,true)
	check(new_course and sim.player.has("_iso_committed_step") and Vector2(sim.player["_iso_committed_step"])==next_tile,"retap preserves the currently committed physical 24x16 step")
	var retap_path: Array=sim.player.get("_iso_route",[])
	var base_from_next: Array[Vector2]=NAV.classic_safe_route(next_tile,new_goal,Callable(sim,"segment_free"))
	check(retap_path==base_from_next,"retap route starts at NEXT tile centre, never mid-step pixel coordinates")
	count=0
	while not sim.player.path.is_empty() and count<1500:
		sim._move(sim.player,1.0/30.0)
		count+=1
	check(count<1500 and sim.player.pos.distance_to(new_goal)<0.1,"retapped island-safe course reaches its new tile centre")

	print(JSON.stringify({"status":"PASS" if failed.is_empty() else "FAIL","checks":checks,"failures":failed}))
	quit(0 if failed.is_empty() else 1)
