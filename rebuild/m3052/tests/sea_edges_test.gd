extends SceneTree
const SIM=preload("res://simulation.gd")
const CONTENT=preload("res://content.gd")
const MOTION=preload("res://monster_motion.gd")
var checks:=0
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	var sim=SIM.new()
	check(sim.WORLD==Vector2(8800,6400),"sea width and height double without enlarging ships")
	for origin in [0,6,1,7,42]:
		for edge: String in ["east","west","north","south"]:
			var dest: int=CONTENT.sea_edge_neighbor(origin,edge)
			if dest<0:continue
			for tangent in [.12,.41,.83]:
				sim.configure_map(origin);sim.level=20;sim.npcs.clear();sim.drops.clear()
				sim.player.hp=sim.player.max_hp;sim.player.shield=777;sim.player.last_hit=sim.clock-6.1
				var before_gold: int=sim.player.gold
				var stock: Array=sim.player.ammo.duplicate()
				var point: Vector2=sim.edge_point(edge,sim.WORLD*tangent)
				var inward: Vector2={"east":Vector2.LEFT,"west":Vector2.RIGHT,"north":Vector2.DOWN,"south":Vector2.UP}[edge]
				sim.player.pos=point+inward*140.0
				check(sim.course(point) and sim.pending_portal==-1,"ordinary sailing accepts noncentral edge point")
				var exit_tangent: Vector2=point
				for step in 90:
					# Crossing may happen during the final diagonal leg; compare
					# against the actual exit point, not the tap beyond the band.
					var before_step: Vector2=sim.player.pos
					sim.step(1.0/30.0)
					if sim.map_id!=origin:
						exit_tangent=before_step+sim.player.heading*minf(165.0/30.0,before_step.distance_to(point))
					if sim.map_id!=origin:break
				check(sim.map_id==dest,"entire %s edge crosses from %d at %.2f" % [edge,origin,tangent])
				var preserved: bool=absf(sim.player.pos.y-exit_tangent.y)<1 if edge in ["east","west"] else absf(sim.player.pos.x-exit_tangent.x)<1
				check(preserved and not sim.blocked(sim.player.pos),"opposite-side arrival preserves tangent in safe water")
				check(sim.player.gold==before_gold and sim.player.ammo==stock and int(sim.player.shield)==777,"crossing preserves wallet, ammunition and shield")
				sim.npcs.clear();sim.step(.1)
				check(sim.map_id==dest and sim.near_portal()==-1,"arrival inset prevents bounce-back")
	sim=SIM.new();sim.npcs.clear();sim.player.pos=sim.edge_point("west",sim.WORLD*.4)
	sim.step(.1);check(sim.map_id==0,"outer world edge cannot wrap to an unrelated region")
	sim.player.pos=sim.edge_point("east",sim.WORLD*.4);sim.step(.1)
	check(sim.map_id==0 and "stufe 2" in sim.message,"sailing into a locked edge retains the level gate")
	sim.level=20;sim.player.last_hit=sim.clock;sim.step(3)
	check(sim.map_id==0,"whole-edge crossing cannot escape combat cooldown")
	sim.step(3.1);check(sim.map_id==1,"whole-edge crossing resumes when combat cooldown ends")
	var legacy: Dictionary=SIM.new().export_save()
	legacy.erase("world_layout");legacy.position=[2100,1450];legacy.gold=733;legacy.pearls=17;legacy.crystals=9
	var restored=SIM.new();check(restored.restore_save(legacy),"old save remains readable")
	check(restored.player.pos==SIM.START and restored.player.gold==733 and restored.pearls==17 and restored.crystals==9,"legacy world coordinates migrate with currencies intact")
	var twice=SIM.new();twice.restore_save(restored.export_save())
	check(twice.player.pos==restored.player.pos,"coordinate migration applies exactly once")
	var moored=SIM.new();moored.player.pos=moored.harbor;moored.dock()
	legacy=moored.export_save();legacy.erase("world_layout");legacy.position=[moored.harbor.x*.5,moored.harbor.y*.5]
	restored=SIM.new();restored.restore_save(legacy)
	check(restored.docked and restored.player.pos==restored.harbor,"legacy moored captain remains safely docked")
	for key: String in ["kraken","serpent","crab"]:
		var first: ArrayMesh=MOTION.frame(key,0.0,100,true)
		check(first==MOTION.frame(key,2.0,100,true),"monster cycles reuse cached meshes without per-frame allocation")
		check(first!=MOTION.frame(key,.5,100,true),"monster body changes across animation phases")
		check(MOTION.frame(key,0,100,false)==MOTION.frame(key,100,100,false),"quiet setting holds monster silhouette stationary")
		for y in 11:
			for x in 11:
				var uv=Vector2(x*.1,y*.1)
				var delta: Vector2=MOTION.offset(key,uv,1.3)
				check(delta.is_finite() and delta.length()<.08,"bounded monster motion cannot move names or collision footprints")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
