extends SceneTree
## 2D Classic and native 3D MUST use the same actual physical world
## coordinates, 48x32 tile itinerary, speed and authoritative WS payload.
## The renderer has no permission to select an alternate pathfinder.
const SIM=preload("res://simulation.gd")
const NAV=preload("res://navigation.gd")
const NET=preload("res://network_client.gd")
var checks: int=0
var failures: Array[String]=[]

func check(condition: bool,label: String) -> void:
	checks+=1
	if not condition:failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var classic=SIM.new()
	var full_3d=SIM.new()
	classic.npcs.clear()
	full_3d.npcs.clear()
	classic.player.pos=Vector2(4200,2900)
	full_3d.player.pos=Vector2(4200,2900)
	classic.set_classic_steering(true)
	full_3d.set_classic_steering(false) # old 3D renderer used to disable raster
	check(classic.classic_steering and full_3d.classic_steering,"3D rendering CANNOT disable global 48x32 physics")

	var click: Vector2=Vector2(4755,3075)
	var a: bool=classic.course(click,true)
	var b: bool=full_3d.course(click,true)
	check(a and b,"both 2D and 3D accept the same clicked coordinates")
	if a and b:
		var target_2d: Vector2=Vector2(classic.player.path.back())
		var target_3d: Vector2=Vector2(full_3d.player.path.back())
		check(target_2d==target_3d and target_2d==classic._classic_clicked_target(click),"both modes snap to identical world target tile")
		check(classic.player["_iso_route"]==full_3d.player["_iso_route"],"both modes plan IDENTICAL full global tile itinerary")
		var planned: Array=classic.player["_iso_route"]
		var valid: bool=not planned.is_empty()
		var last: Vector2=classic.player.pos
		for tile: Vector2 in planned:
			var d: Vector2=tile-last
			if d.length()>30.0:valid=false
			last=tile
		check(valid,"all shared steps are short true 48x32 raster tile legs")
		var packet2d: Dictionary=NET.course_payload(target_2d,planned,17,true)
		var packet3d: Dictionary=NET.course_payload(target_3d,full_3d.player["_iso_route"],17,true)
		check(packet2d==packet3d and packet2d.navigation_mode=="classic_48x32","network sends exactly the SAME ordered physical waypoints for 2D and 3D")
		check(packet2d.raster_preexpanded==true and packet2d.route.size()==planned.size(),"server receives full precalculated tile course instead of direct 3D shortcut")
		for frame in 75:
			classic._move(classic.player,1.0/30.0)
			full_3d._move(full_3d.player,1.0/30.0)
			check(Vector2(classic.player.pos).distance_to(Vector2(full_3d.player.pos))<0.001,"2D/3D world positions remain equal on tick "+str(frame))
		check(classic.player.heading.distance_to(full_3d.player.heading)<0.001,"both renderers observe the identical physical bearing")
		var old_index: int=int(full_3d.player.get("_iso_route_index",0))
		var old_route: Array=full_3d.player.get("_iso_route",[]).duplicate()
		var old_position: Vector2=full_3d.player.pos
		full_3d.set_classic_steering(true)
		full_3d.set_classic_steering(false)
		check(full_3d.player.pos==old_position and full_3d.player.get("_iso_route_index",-1)==old_index and full_3d.player.get("_iso_route",[])==old_route,"graphics switch does not restart physical route, clear current microstep or teleport")
		var retap: Vector2=Vector2(4385,3175)
		var retap_2d: bool=classic.course(retap,true)
		var retap_3d: bool=full_3d.course(retap,true)
		check(retap_2d and retap_3d,"both views can retap while sailing")
		if retap_2d and retap_3d:
			check(classic.player.get("_iso_committed_step",null)==full_3d.player.get("_iso_committed_step",null),"both modes finish the same committed tile before retap")
			check(classic.player.get("_iso_route",[])==full_3d.player.get("_iso_route",[]),"retap recomputes the same turn-by-turn raster route")
			for tick in 420:
				classic._move(classic.player,1.0/30.0)
				full_3d._move(full_3d.player,1.0/30.0)
				if tick%20==0:
					check(Vector2(classic.player.pos).distance_to(Vector2(full_3d.player.pos))<0.001,"mixed-view convoy stays on same trail after retap "+str(tick))
				if classic.player.path.is_empty() or full_3d.player.path.is_empty():break
			check(classic.player.path.is_empty() and full_3d.player.path.is_empty() and classic.player.pos.distance_to(full_3d.player.pos)<0.001,"both views finish same position after shared journey")
	check(is_equal_approx(SIM.CLASSIC_TILE_SAIL_SPEED,76.0),"approved 344 speed is unchanged in both modes")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
