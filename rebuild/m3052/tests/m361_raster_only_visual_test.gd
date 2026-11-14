extends SceneTree
## The 48x32 zigzag is a Classic 2D appearance only. Native 3D and
## shared player coordinates MUST NOT follow those visual microsteps.
const SIM=preload("res://simulation.gd")
const NAV=preload("res://navigation.gd")
var checks: int=0
var failed: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failed.append(label)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false)
	game.sim.npcs.clear()
	game.sim.islands.clear()
	var origin: Vector2=NAV.classic_tile_center(NAV.classic_world_to_tile(Vector2(500,500)))
	var goal: Vector2=origin+Vector2(576,0)
	game.sim.player.pos=origin
	game.sim._clear_classic_raster_state(game.sim.player)
	game.browser_classic=true
	game.classic_raster_visuals.clear()
	check(game.sim.course(goal,true),"Classic click course accepted")
	var untouched_route: Array=game.sim.player.get("_iso_route",[]).duplicate(true)
	check(untouched_route.size()==1 and Vector2(untouched_route[0])==goal,"authoritative route remains a single straight leg")
	var original_zoom: float=game._sharp_zoom()
	var original_length: float=game._actor_visual_length(game.sim.player)
	game._classic_actor_render_pos(game.sim.player)
	var worst_visual_y: float=0.0
	var worst_world_y: float=0.0
	var frames: Dictionary={}
	var max_visual_jump: float=0.0
	var previous_visual: Vector2=game._classic_actor_render_pos(game.sim.player)
	for i in 180:
		if game.sim.player.path.is_empty():break
		game.sim._move(game.sim.player,1.0/30.0)
		var virtual_pos: Vector2=game._classic_actor_render_pos(game.sim.player)
		var physical: Vector2=game.sim.player.pos
		worst_visual_y=maxf(worst_visual_y,absf(virtual_pos.y-origin.y))
		worst_world_y=maxf(worst_world_y,absf(physical.y-origin.y))
		max_visual_jump=maxf(max_visual_jump,virtual_pos.distance_to(previous_visual))
		previous_visual=virtual_pos
		frames[game._classic_frame_for_actor(game.sim.player)]=true
	check(worst_visual_y>=8.0 and frames.has(1) and frames.has(3),"2D shows old visible NE/SE raster movement and alternating pictures")
	check(worst_world_y<0.001 and untouched_route==game.sim.player.get("_iso_route",[]),"sprite zigzag cannot modify shared 3D physics/path")
	check(max_visual_jump<42.0,"2D raster stays continuous without huge display teleport")
	check(is_equal_approx(original_length,game._actor_visual_length(game.sim.player)) and is_equal_approx(original_zoom,game._sharp_zoom()),"361 preserves equal 2D/3D hull size and zoom from 360")
	# New clicked direction interrupts the old virtual raster while the
	# real captain retaps immediately; no old physics grid lock returns.
	var before: Vector2=game.sim.player.pos
	check(game.sim.course(before+Vector2(-260,-160),true),"reverse retap accepted")
	var pose_before: Vector2=game._classic_actor_render_pos(game.sim.player)
	game.sim._move(game.sim.player,1.0/30.0)
	check(game.sim.player.heading.dot((game.sim.player.path[0]-before).normalized())>0.99,"retap uses actual new direct course, not raster steering")
	check(game._classic_actor_render_pos(game.sim.player).distance_to(pose_before)<42.0,"retap display change stays visually continuous")
	check(not game.sim.player.has("_iso_committed_step"),"Classic raster does not reintroduce committed physical tile step")
	# Toggle only rendering; 3D must use exact real world position.
	game.browser_classic=false
	check(game._classic_actor_render_pos(game.sim.player).distance_to(game.sim.player.pos)<0.001,"3D never receives Classic-only visual offset")
	check(is_equal_approx(original_length,game._actor_visual_length(game.sim.player)) and is_equal_approx(original_zoom,game._sharp_zoom()),"native 3D zoom and ship length untouched")
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failed.is_empty() else "FAIL","checks":checks,"failures":failed}))
	quit(0 if failed.is_empty() else 1)
