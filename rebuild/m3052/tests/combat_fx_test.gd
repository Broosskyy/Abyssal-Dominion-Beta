extends SceneTree
const FX=preload("res://combat_fx.gd")
const SIM=preload("res://simulation.gd")
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	check(FX.WEAPONS.size()==8,"7 selectable ammunition types plus tower mortar")
	var sim=SIM.new()
	check(sim.AMMO_NAMES==FX.WEAPONS.slice(0,7),"effect profiles are mapped to actual game ammunition indices")
	var colors: Array[String]=[]
	var target: Dictionary=sim.npcs[0]
	sim.player.pos=Vector2(500,500)
	target.pos=Vector2(750,500)
	for type in FX.WEAPONS:
		var weapon: String=str(type)
		var tint: Color=FX.weapon_color(weapon)
		check(tint.a>0.99 and tint.r>=0 and tint.g>=0 and tint.b>=0,"visible color palette: "+weapon)
		colors.append(tint.to_html())
		check(FX.lift(weapon,0.0)==0.0 and absf(FX.lift(weapon,1.0))<.001 and FX.lift(weapon,.5)>10.0,"projectile lands on exact sea target: "+weapon)
		var shot={"id":103,"source":0,"target":1,"weapon":weapon,"pos":Vector2(610,500),"start":Vector2(500,500),"distance":220.0,"traveled":110.0,"age":0.15}
		var airborne: Vector2=FX.projectile_center(shot)
		check(is_equal_approx(airborne.x,610.0) and airborne.y<500.0,"mid-flight elevated without changing collision position: "+weapon)
		var count=3 if weapon in ["cannon","chain"] else 1
		sim.shots.clear();sim.events.clear()
		sim._launch(0,int(target.id),weapon,17,count)
		check(sim.shots.size()==count and str(sim.events.back().weapon)==weapon,"actual simulation creates distinct "+weapon+" muzzle and projectiles")
		check(Vector2(sim.events.back().heading).is_equal_approx(Vector2.RIGHT),"muzzle spark direction follows the enemy")
		for projectile: Dictionary in sim.shots:
			check(str(projectile.weapon)==weapon and projectile.has("visual_heading") and projectile.has("salvo_index"),"shot carries cosmetic direction and muzzle index: "+weapon)
		if count==3:
			check(float(sim.shots[0].age)==0.0 and float(sim.shots[1].age)<0 and float(sim.shots[2].age)<float(sim.shots[1].age),"80 ms stagger retained for "+weapon)
	check(colors.size()==colors.duplicate().reduce(func(total,v):return total+(1 if colors.count(v)==1 else 0),0),"each selectable ammo has a distinct color profile")
	check(FX.weapon_color("cannon",true)!=FX.weapon_color("cannon",false),"NPC shells remain visually distinguishable")
	var afflicted={"id":44,"spotted":sim.clock+5.0,"ice":2.0,"slow":4.0,"slow_rate":0.38}
	check(FX.active_statuses(afflicted,sim.clock)==["flare","ice"],"flare mark and ice aura coexist without duplicate slow effect")
	afflicted.ice=0.0
	check(FX.active_statuses(afflicted,sim.clock)==["flare","snow"],"snow debuff visibly replaces ended ice freeze")
	afflicted.slow_rate=0.55
	check(FX.active_statuses(afflicted,sim.clock)==["flare","chain"],"chain slow uses a distinct visual indicator")
	afflicted.spotted=sim.clock-1.0
	afflicted.slow=0.0
	check(FX.active_statuses(afflicted,sim.clock).is_empty(),"expired statuses do not leave persistent VFX")
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false)
	game.sim.shots.clear()
	game.sim.events.clear()
	game.sim.player.pos=Vector2(2200,1600)
	var enemy: Dictionary=game.sim.npcs[0]
	enemy.pos=Vector2(2420,1600)
	for n in 7:
		game.sim._launch(0,int(enemy.id),str(game.sim.AMMO_NAMES[n]),10,1)
	game.sim.clock=1.0
	for projectile: Dictionary in game.sim.shots:projectile.age=.14
	for event: Dictionary in game.sim.events:event.time=.85
	game.queue_redraw()
	await process_frame
	await process_frame
	check(game.drawn_shots==7,"sea-map draw pass processes each real ammo VFX")
	game._refresh_ui()
	for index in 7:
		game.sim.ammo_mode=index
		game._refresh_ui()
		check(bool(game.ammo_selector.get("ammo_marker")),"M3100 color-coded combat HUD enabled")
		check(Color(game.ammo_selector.get("ammo_color"))==FX.weapon_color(str(game.sim.AMMO_NAMES[index])),"HUD accent matches projectile profile "+str(index))
		game._open_modal("Munition")
		check(game.ammo_rows.size()==7 and Color(game.ammo_rows[index].accent)==FX.weapon_color(str(game.sim.AMMO_NAMES[index])),"popover row accent matches flight FX "+str(index))
		game.modal.hide()
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
