extends SceneTree
## Update 359 regression: 2D/3D are display profiles, not movement modes.
## This tests gameplay without private GLB/sprite assets.
const SIM=preload("res://simulation.gd")
const NAV=preload("res://navigation.gd")
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
	for sim in [two_d,three_d]:
		sim.npcs.clear()
		sim.islands.clear()
	var origin: Vector2=NAV.classic_tile_center(NAV.classic_world_to_tile(Vector2(500,500)))
	var destination: Vector2=origin+Vector2(576,0)
	two_d.player.pos=origin
	three_d.player.pos=origin
	two_d.set_classic_steering(true)
	three_d.set_classic_steering(false)
	check(two_d.classic_steering and three_d.classic_steering,"render modes always share physics")
	check(two_d.course(destination,true) and three_d.course(destination,true),"matching 2D and 3D courses accepted")
	check(two_d.player.path==three_d.player.path and two_d.player.get("_iso_route",[])==three_d.player.get("_iso_route",[]),"both views select byte-identical physical 48x32 route")
	check(two_d.player.get("_iso_route",[]).size()>4,"free water traverses REAL 24x16 isometric diamond microsteps in both renderers")
	var max_cross: float=0.0
	var synchronized: bool=true
	var frame: int=0
	while frame<350 and (not two_d.player.path.is_empty() or not three_d.player.path.is_empty()):
		if frame==25:
			# Simulate render-mode change mid-way: never reset the course.
			var before: Vector2=three_d.player.pos
			var path_before: Array=three_d.player.path.duplicate()
			three_d.set_classic_steering(true)
			check(three_d.player.pos==before and three_d.player.path==path_before,"renderer switch preserves position and route")
		two_d._move(two_d.player,1.0/30.0)
		three_d._move(three_d.player,1.0/30.0)
		synchronized=synchronized and two_d.player.pos.distance_to(three_d.player.pos)<0.0001
		max_cross=maxf(max_cross,absf(two_d.player.pos.y-origin.y))
		frame+=1
	check(synchronized and frame<350 and max_cross>=8.0 and max_cross<35.0,"every tick shares identical physical NE/SE zigzag sailing coordinates")
	check(two_d.player.pos.distance_to(destination)<0.001 and three_d.player.pos.distance_to(destination)<0.001,"both modes arrive at the same map coordinate")
	check(is_equal_approx(SIM.CLASSIC_TILE_SAIL_SPEED,76.0),"movement speed unchanged")
	# A reverse course should respond immediately instead of forcing another
	# ship to finish the previous tile segment or a turn radius.
	var third: Vector2=origin+Vector2(-240,-192)
	check(two_d.course(third,true) and three_d.course(third,true),"simultaneous reverse retap accepted")
	check(not two_d.player.has("_iso_committed_step") and not three_d.player.has("_iso_committed_step"),"no stale tile lock remains")
	two_d._move(two_d.player,1.0/30.0)
	three_d._move(three_d.player,1.0/30.0)
	check(two_d.player.pos.distance_to(three_d.player.pos)<0.0001,"immediate retap is consistent across graphic modes")
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
