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
	check(str(body.renderer)=="mesh" and route==sim.plan_path(body.pos,Vector2(950,500)) and route.size()==1,"full Meshy GLBs navigate freely instead of alternating artificial diagonals")
	var before: Vector2=body.pos
	var safe=true
	for point: Vector2 in route:
		safe=safe and sim.segment_free(before,point);before=point
	check(safe,"every GLB route segment remains coastline-safe")
	body.path=route
	var stable_course=true
	for _i in 160:
		sim._move(body,0.1)
		if not body.path.is_empty():stable_course=stable_course and body.heading.dot(Vector2.RIGHT)>.999
	check(stable_course and body.pos.distance_to(Vector2(950,500))<0.01,"free path sails directly toward the goal without artificial zigzags")
	# Legacy four-angle sprites still retain the old detour algorithm.
	body.pos=Vector2(500,500)
	body.renderer="sprite";body.view_count=4
	var fallback=sim.plan_actor_path(body,Vector2(950,500))
	var diagonal_fallback=fallback.size()>=4
	before=body.pos
	for waypoint: Vector2 in fallback:
		var leg: Vector2=waypoint-before
		diagonal_fallback=diagonal_fallback and absf(absf(leg.x)-absf(leg.y))<0.01
		before=waypoint
	check(diagonal_fallback and before.distance_to(Vector2(950,500))<0.01,"actual four-view sprite fallback keeps diagonal headings")
	body.renderer="mesh";body.view_count=4
	check(sim.plan_actor_path(body,Vector2(950,500)).size()==1,"3D ship renderer never inherits sprite zigzag restriction")
	body.view_count=8
	check(sim.plan_actor_path(body,Vector2(950,500)).size()==1,"eight-view ships retain free straight navigation")
	for map_index in [0,1,2]:
		sim.configure_map(map_index)
		sim.shots.clear()
		body=sim.npcs[0];sim.npcs.clear();sim.npcs.append(body)
		# All three chart layouts must start this NPC in real navigable water.
		# (700,500) clips a mirrored island collision margin in region 2.
		body.pos=Vector2(640,500);body.home=body.pos;body.reload=0.0
		check(not sim.blocked(body.pos),"patrol scenario starts outside coastline collision: "+str(map_index))
		sim.player.pos=Vector2(500,500);sim.player.hp=sim.player.max_hp
		sim.select(body.id)
		for _i in 30:sim._step_npc(body,1.0/30.0)
		check(sim.shots.is_empty() if map_index<2 else not sim.shots.is_empty(),"entry maps never attack on proximity or selection; hostile map still does: "+str(map_index))
		sim.shots.clear();body.aggressive=true;body.reload=0.0;body.pos=Vector2(640,500)
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
	# Every normal region needs a stable, free-water berth adjacent to its
	# mirrored coast; decorative island harbor must NEVER block boarding.
	var port_sites: Array[Vector2]=[]
	for port_map in [0,1,2]:
		sim.configure_map(port_map)
		var berth: Vector2=sim.harbor
		port_sites.append(berth)
		check(sim.has_harbor() and not sim.blocked(berth,36.0) and not sim.on_land(berth),"island-harbor berth stays navigable and out of coastal collision on map "+str(port_map))
		check(sim._harbor_site_for_map()==berth,"berth does not reroll during map visits: "+str(port_map))
		sim.player.pos=berth
		sim.player.hp=sim.player.max_hp
		sim.player.last_hit=-100.0
		sim.docked=false
		check(sim.can_dock() and sim.dock(),"working docking and original port gameplay on sea map "+str(port_map))
		sim.depart()
		check(not sim.docked,"harbor departure restores sailing on map "+str(port_map))
		for i in sim.islands.size():
			var island: Dictionary=sim.islands[i]
			var expected_width: float=float(sim.base_islands[i].width)*sim.island_art_scale(str(island.art))
			if sim.CONTENT.has_guild_island(port_map) and i==sim.CONTENT.FORTRESS_ISLAND:expected_width*=sim.CONTENT.GUILD_ISLAND_SCALE
			check(absf(float(island.width)-expected_width)<.1,"island artwork and land collisions use normalized visible width on map "+str(port_map)+" island "+str(i))
	check(port_sites[0]!=port_sites[1] and port_sites[0]!=port_sites[2] and port_sites[1]!=port_sites[2],"normal maps have distinct repeatable coastal harbors")
	sim.configure_map(3)
	check(not sim.has_harbor(),"bonus wave map has no standard island-harbor berth")
	sim=SIM.new()
	body=sim.npcs[0];body.pos=Vector2(500,500);body.home=body.pos;body.patrol=0
	var patrol=sim._patrol_path(body)
	check(not patrol.is_empty() and patrol.back().distance_to(body.home)>=220,"patrols cover a substantial course rather than tiny circles")
	for island: Dictionary in sim.islands:
		var centroid=Vector2.ZERO
		for vertex: Vector2 in island.outline:centroid+=vertex
		centroid/=island.outline.size()
		check(sim.blocked(centroid,0),"measured land centroid is blocked: "+str(island.name))
		var water: Vector2=island.bounds.end+Vector2(60,60)
		if sim.harbor_bounds.grow(60).has_point(water):water=sim.harbor+Vector2(200,0)
		check(not sim.blocked(water,0),"water beyond both coastal and harbor land is clear: "+str(island.name))
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
