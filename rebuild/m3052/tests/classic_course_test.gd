extends SceneTree
## Update 359: the historical 48x32 diamond selects the destination, but
## must NOT force any physical zigzag in either 2D or 3D.
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
	check(direct.size()==1 and direct[0]==goal,"unobstructed water has one direct world-space segment")
	check(NAV.classic_safe_route(start,goal,func(_a,_b):return true)==direct,"safe planner returns the identical direct segment when water is clear")
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
	check(safe and length>start.distance_to(goal),"smoothed coast itinerary never clips land or takes forbidden shortcut")

	# Real simulation: the same direct and coastal itinerary in all graphics.
	var sim=SIM.new()
	sim.npcs.clear()
	sim.islands.clear()
	var origin: Vector2=NAV.classic_tile_center(NAV.classic_world_to_tile(Vector2(500,500)))
	var target: Vector2=origin+Vector2(576,0)
	sim.player.pos=origin
	check(sim.course(target,true),"clear-water captain course accepted")
	var snapped: Vector2=sim._classic_clicked_target(target)
	var route: Array=sim.player.get("_iso_route",[])
	check(route.size()==1 and route[0]==snapped,"clicked 48x32 tile stays selected, but sailing does not visit intermediate diamonds")
	var max_cross: float=0.0
	var dist: float=0.0
	for frame in 650:
		if sim.player.path.is_empty():break
		var before: Vector2=sim.player.pos
		sim._move(sim.player,1.0/30.0)
		dist+=before.distance_to(Vector2(sim.player.pos))
		max_cross=maxf(max_cross,absf(sim.player.pos.y-origin.y))
	check(max_cross<0.01 and sim.player.pos.distance_to(snapped)<0.01 and sim.player.path.is_empty(),"physical ship sails straight without alternating sideways offsets")
	check(absf(dist-origin.distance_to(snapped))<0.1 and is_equal_approx(SIM.CLASSIC_TILE_SAIL_SPEED,76.0),"direct course preserves real calibrated movement speed and path length")

	# A mid-course retap redirects instantly; it must NOT finish an old
	# 24x16 tile step, and it must not jump to a distant original target.
	sim.player.pos=origin
	check(sim.course(Vector2(1200,500),true),"initial retap test course accepted")
	for frame in 8:sim._move(sim.player,1.0/30.0)
	var mid: Vector2=sim.player.pos
	var new_target: Vector2=Vector2(300,750)
	check(sim.course(new_target,true),"redirected course accepted")
	check(not sim.player.has("_iso_committed_step") and sim.player.pos==mid,"retap does not restore obsolete tile lock or teleport")
	sim._move(sim.player,1.0/30.0)
	check(sim.player.heading.dot((sim._classic_clicked_target(new_target)-mid).normalized())>0.99,"retapped vessel immediately points along the new real course")

	# Coastline is validated against actual collision geometry, not merely
	# a decorative tile edge or an optimistic long obstacle sample.
	var polygon: PackedVector2Array=PackedVector2Array([barrier.position,barrier.position+Vector2(barrier.size.x,0),barrier.end,barrier.position+Vector2(0,barrier.size.y)])
	sim.islands.append({"bounds":barrier,"outline":polygon})
	sim.player.pos=start
	sim.player.path.clear()
	sim._clear_classic_raster_state(sim.player)
	check(sim.course(goal,true),"island-safe course accepted")
	var actual: Array=sim.player.get("_iso_route",[])
	check(actual.size()>1 and actual.back()==goal,"live ship chooses smooth coast detour instead of zigzag on open water")
	var p: Vector2=start
	var all_clear: bool=true
	for waypoint: Vector2 in actual:
		all_clear=all_clear and sim.segment_free(p,waypoint,2.0)
		p=waypoint
	check(all_clear,"every physical coastal segment is collision safe")
	var ticks: int=0
	while not sim.player.path.is_empty() and ticks<1800:
		sim._move(sim.player,1.0/30.0)
		ticks+=1
	check(ticks<1800 and sim.player.pos.distance_to(goal)<0.01,"coastal voyage reaches destination without being trapped")

	print(JSON.stringify({"status":"PASS" if failed.is_empty() else "FAIL","checks":checks,"failures":failed}))
	quit(0 if failed.is_empty() else 1)
