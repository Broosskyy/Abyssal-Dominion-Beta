extends SceneTree
## Update 370: Seafight-era 48x32 navigation must be physical and shared
## by 3D AND Classic 2D, not a separate triangle-wave draw path.
const NAV=preload("res://navigation.gd")
const SIM=preload("res://simulation.gd")
const VIS=preload("res://ship_visuals.gd")
var checks: int=0
var failures: Array[String]=[]
var obstacle: Rect2=Rect2(1300,960,96,104)
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func clear(a: Vector2,b: Vector2) -> bool:
	for i in maxi(1,ceili(a.distance_to(b)/2.0))+1:
		var steps: int=maxi(1,ceili(a.distance_to(b)/2.0))
		if obstacle.has_point(a.lerp(b,float(i)/float(steps))):return false
	return true
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var start: Vector2=NAV.classic_tile_center(Vector2i(60,20))
	var targets: Array[Vector2]=[
		start+Vector2(576,0),start+Vector2(-576,0),
		start+Vector2(0,-384),start+Vector2(0,384),
		start+Vector2(384,-256),start+Vector2(-384,-256),
		start+Vector2(384,256),start+Vector2(-384,256),
		start+Vector2(576,-384),start+Vector2(576,-192),
		start+Vector2(240,-320),start+Vector2(-240,-320)]
	for target in targets:
		var steps: Array[Vector2]=NAV.classic_water_route(start,target)
		var previous: Vector2=start
		var valid: bool=steps.size()>3
		var headings: Dictionary={}
		var max_offset: float=0.0
		for point: Vector2 in steps:
			var move: Vector2=point-previous
			valid=valid and absf(absf(move.x)-24.0)<0.001 and absf(absf(move.y)-16.0)<0.001
			if move.length()>0.01:headings[VIS.heading_four(move)]=true
			max_offset=maxf(max_offset,absf((point-start).cross((target-start).normalized())))
			previous=point
		check(valid and previous.distance_to(target)<0.001,"every full leg on a global 24x16 diamond edge, arrives exactly: "+str(target))
		check(max_offset<=33.0,"greedy line stays near desired click without huge turns: "+str(target))
		check(headings.size()>=1 and headings.size()<=4,"every course consists only of authentic four Classic bearings: "+str(target))
		var captain2=SIM.new()
		var captain3=SIM.new()
		for sim in [captain2,captain3]:
			sim.islands.clear()
			sim.npcs.clear()
			sim.player.pos=start
			sim._clear_classic_raster_state(sim.player)
		captain2.set_classic_steering(true)
		captain3.set_classic_steering(false)
		check(captain2.course(target,true) and captain3.course(target,true),"2D/3D both accept identical snapped click: "+str(target))
		check(captain2.player.get("_iso_route",[])==captain3.player.get("_iso_route",[]) and captain2.player.get("_iso_route",[]).size()>3,"2D/3D receive identical PHYSICAL diamond microsteps: "+str(target))
		var real_steps: Dictionary={}
		var identical: bool=true
		for i in 720:
			if captain2.player.path.is_empty() and captain3.player.path.is_empty():break
			captain2._move(captain2.player,1.0/30.0)
			captain3._move(captain3.player,1.0/30.0)
			identical=identical and captain2.player.pos.distance_to(captain3.player.pos)<0.00001 and captain2.player.heading.distance_to(captain3.player.heading)<0.00001
			real_steps[VIS.heading_four(captain2.player.heading)]=true
		check(identical and captain2.player.path.is_empty() and captain3.player.path.is_empty() and captain3.player.pos.distance_to(target)<0.001,"every 30Hz frame has matching real 2D/3D position, heading and endpoint: "+str(target))
		check(real_steps.size()>=1 and real_steps.size()<=4,"3D hull really follows isometric microstep headings: "+str(target))
	# Coast: detour must also remain on the grid and avoid collision.
	var coast_start: Vector2=NAV.classic_tile_center(Vector2i(57,20))
	var coast_goal: Vector2=coast_start+Vector2(600,0)
	obstacle=Rect2(coast_start+Vector2(240,-40),Vector2(96,80))
	var safe: Array[Vector2]=NAV.classic_safe_route(coast_start,coast_goal,Callable(self,"clear"))
	var previous: Vector2=coast_start
	var physical: bool=safe.size()>15
	for point: Vector2 in safe:
		var shift: Vector2=point-previous
		physical=physical and absf(absf(shift.x)-24.0)<0.001 and absf(absf(shift.y)-16.0)<0.001
		physical=physical and clear(previous,point)
		previous=point
	check(physical and previous==coast_goal,"coastal A* also follows authentic 48x32 edges and never cuts through island")
	# Actual render positions remain the real simulated positions, with
	# 2D only snapping to pixel boundaries; no oscillator may modify course.
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false)
	game.sim.islands.clear()
	game.sim.player.pos=start
	game.sim._clear_classic_raster_state(game.sim.player)
	game.browser_classic=true
	var upper_right: Vector2=start+Vector2(480,-320)
	check(game.sim.course(upper_right,true),"real chart upper-right tap accepted")
	var max_render_error: float=0.0
	var visual_frames: Dictionary={}
	for tick in 145:
		if game.sim.player.path.is_empty():break
		game.sim._move(game.sim.player,1.0/30.0)
		var shown: Vector2=game._classic_actor_render_pos(game.sim.player)
		max_render_error=maxf(max_render_error,shown.distance_to(game.sim.player.pos))
		visual_frames[game._classic_frame_for_actor(game.sim.player)]=true
	check(max_render_error<=1.5,"2D hull depicts genuine world coordinates without independent ±9px lateral fake")
	check(not visual_frames.is_empty() and visual_frames.keys().all(func(k):return k in [1,3,5,7]),"moving Classic sprite uses true four tile bearings")
	var current_world: Vector2=game.sim.player.pos
	var current_route: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
	game.browser_classic=false
	check(game._classic_actor_render_pos(game.sim.player).distance_to(current_world)<0.001 and game.sim.player.get("_iso_route",[])==current_route,"switching to actual 3D keeps physical tile route untouched")
	game.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
