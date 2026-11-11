extends SceneTree
const SIM=preload("res://simulation.gd")
const NAV=preload("res://navigation.gd")
const VISUALS=preload("res://ship_visuals.gd")
var checks:=0
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var full_width: Array[Vector2]=preload("res://navigation.gd").diagonal_leg(Vector2.ZERO,Vector2(8800,0),4.0)
	var cursor: Vector2=Vector2.ZERO
	var valid: bool=not full_width.is_empty()
	for point: Vector2 in full_width:
		var gap: Vector2=point-cursor
		valid=valid and absf(absf(gap.x)-absf(gap.y))<.01 and absf(gap.x)<=4.01
		cursor=point
	check(valid and cursor==Vector2(8800,0),"fine coastal legs cannot truncate a full expanded-world crossing")
	var four_way: Array[Vector2]=NAV.classic_compass_leg(Vector2.ZERO,Vector2(700,0),12.0)
	var origin: Vector2=Vector2.ZERO
	var max_side_error: float=0.0
	var four_headings: bool=not four_way.is_empty()
	for point: Vector2 in four_way:
		var leg: Vector2=point-origin
		max_side_error=maxf(max_side_error,absf(point.y))
		four_headings=four_headings and absf(absf(leg.x)-absf(leg.y))<0.01
		four_headings=four_headings and VISUALS.heading_eight(leg,-1) in [1,3,5,7]
		origin=point
	check(four_headings and four_way.back()==Vector2(700,0),"classic compass has only four original 90-degree-separated headings")
	check(max_side_error<=12.01 and four_way.size()>=20 and four_way.size()<=50,"old-Seafight dance stays within 12 world units, not 144-unit V detours")
	var nearly_diagonal: Array[Vector2]=NAV.classic_compass_leg(Vector2.ZERO,Vector2(700,690),12.0)
	check(nearly_diagonal.size()<=3 and nearly_diagonal.back()==Vector2(700,690),"diagonal destination holds one heading rather than wobbling on every step")
	var whole_chart: Array[Vector2]=NAV.classic_compass_leg(Vector2.ZERO,Vector2(8800,0),12.0)
	check(whole_chart.size()<=480 and whole_chart.back()==Vector2(8800,0),"four-way whole-chart route stays inside online waypoint cap")
	for destination: Vector2 in [Vector2(-740,0),Vector2(0,-640),Vector2(-600,-230),Vector2(760,610),Vector2(-280,900)]:
		var path: Array[Vector2]=NAV.classic_compass_leg(Vector2.ZERO,destination,12.0,-1)
		var current: Vector2=Vector2.ZERO
		var safe_headings: bool=not path.is_empty()
		for leg_goal: Vector2 in path:
			var leg: Vector2=leg_goal-current
			safe_headings=safe_headings and absf(absf(leg.x)-absf(leg.y))<0.02
			current=leg_goal
		check(safe_headings and current.distance_to(destination)<0.01,"four compass headings reach arbitrary signed destination "+str(destination))
	var sim=SIM.new();sim.npcs.clear();sim.player.pos=Vector2(500,500)
	var goal:=Vector2(1200,500)
	check(not sim.classic_steering,"native default is direct steering, not classic zigzag")
	check(sim.course(goal),"water tap creates a course")
	check(sim.player.path.size()==1 and sim.player.path[0]==goal,"2.5D and 3D retain direct open-water navigation")
	sim.set_classic_steering(true)
	check(sim.classic_steering and sim.player.path.back()==goal,"entering Classic mid-voyage rebuilds route to the same destination")
	var previous: Vector2=sim.player.pos
	var last_side: float=0.0
	var changes: int=0
	for waypoint: Vector2 in sim.player.path:
		var gap: Vector2=waypoint-previous
		check(absf(absf(gap.x)-absf(gap.y))<.01,"open-sea legs are diagonal, never a rotating sprite on a straight path")
		if last_side!=0 and signf(gap.y)!=last_side:changes+=1
		last_side=signf(gap.y);previous=waypoint
	check(changes>=2 and previous==goal,"Classic 2D alternates discrete diagonal legs and reaches the exact tap")
	check(sim.player.path.size()>20 and sim.player.path.size()<50,"Classic has short discreet compass steps rather than giant V-shaped legs")
	var sidestep: float=0.0
	for point: Vector2 in sim.player.path:
		sidestep=maxf(sidestep,absf(point.y-500.0))
	check(sidestep<=12.01,"actual Classic gameplay never veers more than 12 world units off a clear horizontal course")
	var stock: Array=sim.player.ammo.duplicate()
	for step in 900:
		sim._move(sim.player,1.0/60.0)
		if sim.player.path.is_empty():break
	check(sim.player.pos.distance_to(goal)<.01 and sim.player.ammo==stock,"classic sailing arrives without changing ammunition")
	sim.course(Vector2(1800,500));sim._move(sim.player,.25)
	var corner: Vector2=sim.player.pos
	check(sim.course(Vector2(300,850)) and sim.player.path.back()==Vector2(300,850),"new tap immediately replaces the previous zigzag course")
	sim._move(sim.player,.01)
	check(sim.player.heading.x<0 and sim.player.pos.distance_to(corner)<2,"new Classic direction takes effect without turning circle or teleport")
	var changing_goal: Vector2=sim.player.path.back()
	var switch_origin: Vector2=sim.player.pos
	sim.set_classic_steering(false)
	check(not sim.classic_steering and sim.player.pos==switch_origin and sim.player.path.back()==changing_goal,"returning to 3D preserves exact position and existing destination")
	check(sim.player.path.size()<=2,"native 2.5D / 3D returns to the old direct path, not zigzag")
	var npc_body: Dictionary={"pos":Vector2(500,500),"heading":Vector2.RIGHT,"kind":"ship"}
	var npc_direct: Array[Vector2]=sim.plan_actor_path(npc_body,Vector2(1200,500))
	check(npc_direct.size()==1 and npc_direct[0]==Vector2(1200,500),"3D NPC patrol ship uses original direct routes")
	sim.set_classic_steering(true)
	var npc_classic: Array[Vector2]=sim.plan_actor_path(npc_body,Vector2(1200,500))
	check(npc_classic.size()>2,"Classic 2D NPC ship uses discrete diagonal steps")
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
	check(game.sim.classic_steering and game.sim.player.path.back()==destination and game.sim.player.path!=course and game.sim.player.pos==Vector2(before.position[0],before.position[1]),"Classic 2D re-plans the remaining route as diagonal steps without moving the captain")
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
