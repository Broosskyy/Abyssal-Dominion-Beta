extends SceneTree
const SIM=preload("res://simulation.gd")
const NAV=preload("res://navigation.gd")
var failures: Array[String]=[]
var count=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	for goal in [Vector2(400,0),Vector2(-250,80),Vector2(40,-370),Vector2(-100,-100)]:
		var route=NAV.diagonal_leg(Vector2.ZERO,goal)
		var before=Vector2.ZERO
		var valid=not route.is_empty()
		for point: Vector2 in route:
			var delta=point-before
			valid=valid and absf(absf(delta.x)-absf(delta.y))<0.01 and delta.length()>0.001
			before=point
		check(valid and before.distance_to(goal)<0.01,"four-view diagonal legs reach goal: "+str(goal))
	var sim=SIM.new()
	var body=sim.npcs[0];body.pos=Vector2(500,500)
	var route=sim.plan_actor_path(body,Vector2(950,500))
	check(route.size()>=4,"long cardinal goal becomes real alternating diagonals")
	var before: Vector2=body.pos
	var safe=true
	for point: Vector2 in route:
		safe=safe and sim.segment_free(before,point);before=point
	check(safe,"every zigzag segment is checked against coastline geometry")
	body.path=route
	var diagonal_motion=true
	for _i in 160:
		sim._move(body,0.1)
		if not body.path.is_empty():diagonal_motion=diagonal_motion and absf(absf(body.heading.x)-absf(body.heading.y))<0.001
	check(diagonal_motion and body.pos.distance_to(Vector2(950,500))<0.01,"actual movement preserves diagonal headings through waypoints without corner cutting")
	body.pos=Vector2(500,500)
	body.view_count=8
	check(sim.plan_actor_path(body,Vector2(950,500)).size()==1,"eight-view ships retain free straight navigation")
	body.renderer="3d";body.view_count=4
	check(sim.plan_actor_path(body,Vector2(950,500)).size()==1,"future 3D renderer does not inherit legacy zigzag restriction")
	for map_index in [0,1,2]:
		sim.configure_map(map_index)
		sim.shots.clear()
		body=sim.npcs[0];sim.npcs.clear();sim.npcs.append(body)
		body.pos=Vector2(700,500);body.home=body.pos;body.reload=0.0
		sim.player.pos=Vector2(500,500);sim.player.hp=sim.player.max_hp
		sim.select(body.id)
		for _i in 30:sim._step_npc(body,1.0/30.0)
		check(sim.shots.is_empty() if map_index<2 else not sim.shots.is_empty(),"entry maps never attack on proximity or selection; hostile map still does: "+str(map_index))
		sim.shots.clear();body.aggressive=true;body.reload=0.0;body.pos=Vector2(700,500)
		sim._step_npc(body,0.1)
		check(not sim.shots.is_empty(),"provoked NPC can retaliate on map "+str(map_index))
		sim.player.pos=Vector2(2500,500);sim._step_npc(body,0.1)
		check(not body.aggressive and body.state=="patrol","escaping combat clears retaliation instead of permanent pursuit: "+str(map_index))
		sim.shots.clear();sim.docked=true;body.aggressive=true;body.reload=0.0
		sim.player.pos=Vector2(500,500)
		var dock_hp: float=sim.player.hp
		var patrol_start: Vector2=body.pos
		for _i in 120:sim.step(1.0/30.0)
		check(body.pos.distance_to(patrol_start)>50,"patrol continues while captain is docked on region "+str(map_index))
		check(sim.player.hp==dock_hp and sim.shots.is_empty() and not body.aggressive,"docking suppresses hostile and retaliatory fire on region "+str(map_index))
		sim.docked=false
	sim=SIM.new()
	body=sim.npcs[0];body.pos=Vector2(500,500);body.home=body.pos;body.patrol=0
	var patrol=sim._patrol_path(body)
	check(not patrol.is_empty() and patrol.back().distance_to(body.home)>=220,"patrols cover a substantial course rather than tiny circles")
	for island: Dictionary in sim.islands:
		var centroid=Vector2.ZERO
		for vertex: Vector2 in island.outline:centroid+=vertex
		centroid/=island.outline.size()
		check(sim.blocked(centroid,0),"measured land centroid is blocked: "+str(island.name))
		check(not sim.blocked(island.bounds.end+Vector2(60,60),0),"water beyond measured bounds is clear: "+str(island.name))
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
