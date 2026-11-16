extends SceneTree
## M376: 2D Classic and native 3D share an exact direct/coastal world course.
## Classic 48x32 tile geometry selects a destination only; sprite cadence
## cannot affect physics, collision, world heading or online waypoints.
const SIM=preload("res://simulation.gd")
const NAV=preload("res://navigation.gd")
const VIS=preload("res://ship_visuals.gd")
var checks: int=0
var failures: Array[String]=[]

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var start: Vector2=NAV.classic_tile_center(Vector2i(50,20))
	var deltas: Array[Vector2]=[
		Vector2(576,0),Vector2(-576,0),Vector2(0,384),Vector2(0,-384),
		Vector2(480,-320),Vector2(-480,-320),Vector2(480,320),Vector2(-480,320)]
	for shift: Vector2 in deltas:
		var desired: Vector2=start+shift
		var two_d=SIM.new()
		var three_d=SIM.new()
		for sim in [two_d,three_d]:
			sim.npcs.clear()
			sim.islands.clear()
			sim.player.pos=start
			sim.player.path=[]
			sim._clear_classic_raster_state(sim.player)
		two_d.set_classic_steering(true)
		three_d.set_classic_steering(false)
		var accepted_2d: bool=two_d.course(desired,true)
		var accepted_3d: bool=three_d.course(desired,true)
		check(accepted_2d and accepted_3d,"both graphics accept same click "+str(shift))
		if not accepted_2d or not accepted_3d:continue
		var endpoint: Vector2=Vector2(two_d.player.path.back())
		check(two_d.player.path==three_d.player.path and two_d.player.path.size()==1,
			"open water uses one shared direct waypoint "+str(shift))
		var forward: Vector2=(endpoint-start).normalized()
		var identical: bool=true
		var max_lateral: float=0.0
		for frame in 600:
			if two_d.player.path.is_empty() and three_d.player.path.is_empty():break
			two_d._move(two_d.player,1.0/30.0)
			three_d._move(three_d.player,1.0/30.0)
			var world: Vector2=two_d.player.pos
			identical=identical and world.distance_to(Vector2(three_d.player.pos))<0.0001
			max_lateral=maxf(max_lateral,absf((world-start).cross(forward)))
		check(identical and max_lateral<0.01,"2D/3D follow one straight world line on every tick "+str(shift))
		check(two_d.player.pos.distance_to(endpoint)<0.01 and three_d.player.pos.distance_to(endpoint)<0.01,
			"both modes arrive at exactly same target "+str(shift))
		var parked: Vector2=two_d.player.pos
		for frame in 30:two_d._move(two_d.player,1.0/30.0)
		check(two_d.player.pos==parked,"no jitter after arrival "+str(shift))
	# Simulated classic view alternation must NOT change actual movement.
	var a: int=VIS.classic_sprite_cadence(Vector2.RIGHT,0.0)
	var b: int=VIS.classic_sprite_cadence(Vector2.RIGHT,30.0)
	var c: int=VIS.classic_sprite_cadence(Vector2.RIGHT,60.0)
	check(a!=b and b!=c and a==c,"2D classic cardinal view alternates with travelled distance")
	check(VIS.classic_sprite_cadence(Vector2(24,-16),0.0)==VIS.classic_sprite_cadence(Vector2(24,-16),30.0),
		"natural iso diagonal retains the same sprite heading")
	check(is_equal_approx(SIM.CLASSIC_TILE_SAIL_SPEED,76.0),"movement pace unchanged at 76 world units per second")
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
