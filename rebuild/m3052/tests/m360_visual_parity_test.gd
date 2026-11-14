extends SceneTree
## Update 360: real-world movement stays shared, while 2D sprites use
## true compass headings and both renderers have equal ship/zoom metrics.
const VIS=preload("res://ship_visuals.gd")
const SIM=preload("res://simulation.gd")
var checks: int=0
var failures: Array[String]=[]

func check(ok: bool,description: String) -> void:
	checks+=1
	if not ok:failures.append(description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	var all_bearings: Array[Vector2]=[Vector2.UP,Vector2(1,-1),Vector2.RIGHT,Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1)]
	for i in 8:
		game.classic_heading_cache.clear()
		var actor: Dictionary={"id":9280+i,"kind":"ship","pos":Vector2(600,600),"heading":all_bearings[i],"path":[]}
		check(VIS.heading_eight(actor.heading)==i,"source GLB atlas includes matching true facing %d" % i)
		check(game._classic_frame_for_actor(actor)==i,"Classic renderer chooses actual 8-view image %d" % i)
	for screen in [Vector2i(844,390),Vector2i(1280,720),Vector2i(2340,1080)]:
		root.size=screen
		await process_frame
		game.desired_zoom=1.18
		game.browser_classic=false
		var native_zoom: float=game._sharp_zoom()
		var native_player: float=game._actor_visual_length(game.sim.player)
		var native_npc: float=game._actor_visual_length(game.sim.npcs[0])
		game.browser_classic=true
		check(absf(game._sharp_zoom()-native_zoom)<0.0001,"mobile/desktop zoom exactly identical across 2D/3D at "+str(screen))
		check(is_equal_approx(game._actor_visual_length(game.sim.player),native_player),"player GLB and 2D atlas use identical world length at "+str(screen))
		check(is_equal_approx(game._actor_visual_length(game.sim.npcs[0]),native_npc),"NPC GLB and 2D atlas use identical world length at "+str(screen))
	# Under-sail motion is purely a drawing property.
	game.ship_animations_enabled=true
	game.elapsed=PI/(2.0*2.1)
	var motion_actor: Dictionary={"id":0,"kind":"ship","pos":Vector2(700,700),"heading":Vector2.RIGHT,"path":[Vector2(1100,700)]}
	var old_pos: Vector2=motion_actor.pos
	var old_heading: Vector2=motion_actor.heading
	check(absf(game._classic_sail_heel(motion_actor))>0.004,"under-sail 2D hull has gentle visual heel rather than static card")
	game.ship_animations_enabled=false
	check(absf(game._classic_sail_heel(motion_actor))<0.00001,"turning off animations disables hull heave")
	check(motion_actor.pos==old_pos and motion_actor.heading==old_heading,"visual animation does not change physical position or facing")
	game.browser_classic=false
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
