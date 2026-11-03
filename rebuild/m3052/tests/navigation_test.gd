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
	body.view_count=8
	check(sim.plan_actor_path(body,Vector2(950,500)).size()==1,"eight-view ships retain free straight navigation")
	body.renderer="3d";body.view_count=4
	check(sim.plan_actor_path(body,Vector2(950,500)).size()==1,"future 3D renderer does not inherit legacy zigzag restriction")
	for island: Dictionary in sim.islands:
		var centroid=Vector2.ZERO
		for vertex: Vector2 in island.outline:centroid+=vertex
		centroid/=island.outline.size()
		check(sim.blocked(centroid,0),"measured land centroid is blocked: "+str(island.name))
		check(not sim.blocked(island.bounds.end+Vector2(60,60),0),"water beyond measured bounds is clear: "+str(island.name))
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
