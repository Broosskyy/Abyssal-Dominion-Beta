extends SceneTree
const SIM=preload("res://simulation.gd")
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
	var sim=SIM.new();sim.npcs.clear();sim.player.pos=Vector2(500,500)
	var goal:=Vector2(1200,500)
	check(sim.course(goal),"water tap creates a classic course")
	var previous: Vector2=sim.player.pos
	var last_side: float=0.0
	var changes: int=0
	for waypoint: Vector2 in sim.player.path:
		var gap: Vector2=waypoint-previous
		check(absf(absf(gap.x)-absf(gap.y))<.01,"open-sea legs are diagonal, never a rotating sprite on a straight path")
		if last_side!=0 and signf(gap.y)!=last_side:changes+=1
		last_side=signf(gap.y);previous=waypoint
	check(changes>=4 and previous==goal,"eastbound travel alternates diagonal legs and reaches the exact tap")
	var stock: Array=sim.player.ammo.duplicate()
	for step in 900:
		sim._move(sim.player,1.0/60.0)
		if sim.player.path.is_empty():break
	check(sim.player.pos.distance_to(goal)<.01 and sim.player.ammo==stock,"classic sailing arrives without changing ammunition")
	sim.course(Vector2(1800,500));sim._move(sim.player,.25)
	var corner: Vector2=sim.player.pos
	check(sim.course(Vector2(300,850)) and sim.player.path.back()==Vector2(300,850),"new tap immediately replaces the previous zigzag course")
	sim._move(sim.player,.01)
	check(sim.player.heading.x<0 and sim.player.pos.distance_to(corner)<2,"new direction takes effect without turning circle or teleport")
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame;game.set_process(false)
	var before: Dictionary=game.sim.export_save()
	game.sim.course(game.sim.player.pos+Vector2(600,0))
	var course: Array=game.sim.player.path.duplicate()
	game._set_render_mode("classic");await process_frame
	check(game.browser_classic and game.render_mode=="classic" and game.mesh_layer==null,"native Classic disables and removes the 3D fleet viewport")
	check(game._classic_fleet_ready(),"native 2D loads all 23 ship and paint atlases")
	check(game.sim.player.path==course and game.sim.player.pos==Vector2(before.position[0],before.position[1]),"switching graphics preserves position and current course")
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
	check(not reloaded.browser_classic and reloaded.mesh_layer!=null and reloaded.mesh_layer.has_complete_fleet() and reloaded.render_mode=="3d","native captain can restore the complete original 3D fleet")
	reloaded._set_render_mode("classic");await process_frame
	reloaded._set_render_mode("hybrid");await process_frame
	check(not reloaded.browser_classic and reloaded.render_mode=="hybrid" and reloaded.mesh_layer!=null,"repeated 2D/3D/2.5D switches leave one working renderer")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
