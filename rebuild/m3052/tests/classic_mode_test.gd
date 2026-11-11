extends SceneTree
const SIM=preload("res://simulation.gd")
const VISUALS=preload("res://ship_visuals.gd")
var checks:=0
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	# The four historical Classic facings use the diagonal frames from the
	# eight baked 2D sprites. Four views change only visual orientation.
	for heading: Vector2 in [Vector2(1,-1),Vector2(-1,-1),Vector2(-1,1),Vector2(1,1)]:
		var expected: int=[1,7,5,3][[Vector2(1,-1),Vector2(-1,-1),Vector2(-1,1),Vector2(1,1)].find(heading)]
		check(VISUALS.heading_four(heading)==expected,"four-way Classic graphic selects correct baked diagonal "+str(heading))
	for heading: Vector2 in [Vector2.RIGHT,Vector2.UP,Vector2.LEFT,Vector2.DOWN,Vector2(5,2),Vector2(-8,1)]:
		check(VISUALS.heading_four(heading) in [1,3,5,7],"every ordinary captain heading chooses exactly one of the four Classic frames")
	var east_frame: int=VISUALS.heading_four(Vector2.RIGHT)
	check(VISUALS.heading_four(Vector2(1,-0.07),east_frame)==east_frame and VISUALS.heading_four(Vector2(1,0.07),east_frame)==east_frame,"Classic sprite hysteresis prevents flickering when sailing nearly east")
	var sim=SIM.new();sim.npcs.clear();sim.player.pos=Vector2(500,500)
	var goal:=Vector2(1200,500)
	check(not sim.classic_steering,"native default uses direct navigation")
	check(sim.course(goal),"water tap creates a course")
	check(sim.player.path.size()==1 and sim.player.path[0]==goal,"native open water follows one direct line")
	var initial_route: Array=sim.player.path.duplicate()
	var initial_pos: Vector2=sim.player.pos
	sim.set_classic_steering(true)
	check(sim.classic_steering and sim.player.path==initial_route and sim.player.pos==initial_pos,"switching to Classic never rewrites the physical route or teleports the captain")
	check(sim.player.path.size()==1 and sim.player.path[0]==goal,"Classic horizontal sailing has no synthetic diagonal zigzags")
	var stock: Array=sim.player.ammo.duplicate()
	var horizontal_track: bool=true
	for step in 900:
		sim._move(sim.player,1.0/60.0)
		horizontal_track=horizontal_track and absf(float(sim.player.pos.y)-500.0)<0.01
		if sim.player.path.is_empty():break
	check(horizontal_track and sim.player.pos.distance_to(goal)<.01 and sim.player.ammo==stock,"Classic physically sails dead straight toward a horizontal click, without spending ammo")
	var diagonal_goal:=Vector2(1600,850)
	check(sim.course(diagonal_goal) and sim.player.path==sim.plan_path(sim.player.pos,diagonal_goal),"Classic follows a direct diagonal tap using ordinary simulation physics")
	sim._move(sim.player,0.25)
	var corner: Vector2=sim.player.pos
	check(sim.course(Vector2(300,850)) and sim.player.path.back()==Vector2(300,850),"new tap immediately replaces the course")
	sim._move(sim.player,.01)
	check(sim.player.heading.x<0 and sim.player.pos.distance_to(corner)<2,"retap takes effect without turn circle or teleport")
	var changing_route: Array=sim.player.path.duplicate()
	var switch_origin: Vector2=sim.player.pos
	sim.set_classic_steering(false)
	check(not sim.classic_steering and sim.player.pos==switch_origin and sim.player.path==changing_route,"returning to 3D leaves the exact active course and location intact")
	var npc_body: Dictionary={"pos":Vector2(500,500),"heading":Vector2.RIGHT,"kind":"ship"}
	var npc_direct: Array[Vector2]=sim.plan_actor_path(npc_body,Vector2(1200,500))
	check(npc_direct.size()==1 and npc_direct[0]==Vector2(1200,500),"native NPC patrol ship follows direct courses")
	sim.set_classic_steering(true)
	var npc_classic: Array[Vector2]=sim.plan_actor_path(npc_body,Vector2(1200,500))
	check(npc_classic==npc_direct,"Classic NPC sprites follow exact same physical paths as native NPCs")
	var monster: Dictionary={"pos":Vector2(500,500),"heading":Vector2.RIGHT,"kind":"monster"}
	check(sim.plan_actor_path(monster,Vector2(1200,500))==npc_direct,"sea monsters keep direct navigation in every mode")
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame;game.set_process(false)
	var before: Dictionary=game.sim.export_save()
	game._set_render_mode("hybrid");await process_frame
	check(not game.sim.classic_steering and game.render_mode=="hybrid","native 2.5D uses direct steering")
	game.sim.course(game.sim.player.pos+Vector2(600,0))
	var destination: Vector2=game.sim.player.path.back()
	var course: Array=game.sim.player.path.duplicate()
	game._set_render_mode("classic");await process_frame
	check(game.browser_classic and game.render_mode=="classic" and game.mesh_layer==null,"native Classic disables and removes the 3D fleet viewport")
	check(game._classic_fleet_ready(),"native 2D loads all 23 ship and paint atlases")
	check(game.sim.classic_steering and game.sim.player.path.back()==destination and game.sim.player.path==course and game.sim.player.pos==Vector2(before.position[0],before.position[1]),"Classic 2D preserves existing physical waypoint path and position while changing only sprite views")
	game.sim.player.heading=Vector2(1,-1)
	check(game._classic_frame_for_actor(game.sim.player)==1,"Classic renderer draws the expected NE atlas frame from the preserved eight-view collection")
	game.sim.player.heading=Vector2(1,1)
	check(game._classic_frame_for_actor(game.sim.player)==3,"Classic renderer changes facing without changing simulated world coordinates")
	check(game.sim.player.gold==int(before.gold) and game.sim.player.skin==int(before.skin) and game.sim.player.ammo==before.ammo,"graphics switch preserves ship, wallet and ammunition")
	game._open_modal("Anzeige")
	var options: Array[String]=[]
	for button in game.modal_body.find_children("*","Button",true,false):options.append(button.text)
	check(options.any(func(text):return text.begins_with("CLASSIC 2D")) and options.any(func(text):return text.begins_with("2,5D")) and options.any(func(text):return text.begins_with("3D")),"native settings keep all three modes reachable from Classic")
	game.queue_free();await process_frame
	var reloaded=load("res://sea_map.tscn").instantiate();root.add_child(reloaded);current_scene=reloaded
	await process_frame;reloaded.set_process(false)
	check(reloaded.browser_classic and reloaded.render_mode=="classic" and reloaded.mesh_layer==null,"saved Classic preference starts natively without constructing 3D")
	reloaded._set_render_mode("3d");await process_frame
	check(not reloaded.browser_classic and not reloaded.sim.classic_steering and reloaded.mesh_layer!=null and reloaded.mesh_layer.has_complete_fleet() and reloaded.render_mode=="3d","3D restores original direct steering and complete native fleet")
	reloaded._set_render_mode("classic");await process_frame
	reloaded._set_render_mode("hybrid");await process_frame
	check(not reloaded.browser_classic and not reloaded.sim.classic_steering and reloaded.render_mode=="hybrid" and reloaded.mesh_layer!=null,"2.5D restores direct steering and one working renderer")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
