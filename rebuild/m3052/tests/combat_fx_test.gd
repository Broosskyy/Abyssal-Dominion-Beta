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
	check(FX.WEAPONS.size()==29,"28 selectable ammunition types plus tower mortar")
	check(FX.VISIBLE_COUNTS==[1,3,5,8],"M3102 approved visible projectile selections are stable")
	for wanted in [1,3,5,8]:
		check(FX.visual_count(wanted)==wanted,"M3102 visible-orb mode %d supported" % wanted)
	check(FX.visual_count(4)==3 and FX.visual_count(-1)==3,"M3102 unsupported settings gracefully use default 3")
	check(FX.RADIANT_COLORS.size()==5,"M3102 five different rainbow Leuchtkugel jewel types")
	for color_id in 5:
		check(FX.radiant_color(0,color_id)!=FX.radiant_color(0,(color_id+1)%5),"M3102 distinct radiant colour %d" % color_id)
	var sample_ball={"id":12,"pos":Vector2(620,500),"start":Vector2(500,500),"distance":240.0,"traveled":140.0,"visual_heading":Vector2.RIGHT}
	check(FX.orb_offset(sample_ball,0,1,0.0)==Vector2.ZERO,"M3102 one-ball visual is exactly original flight path")
	for total in [3,5,8]:
		var cluster: Array[Vector2]=[]
		for orb in total:cluster.append(FX.orb_offset(sample_ball,orb,total,1.0))
		var footprint:=Rect2(cluster[0],Vector2.ZERO)
		for p in cluster:footprint=footprint.expand(p)
		check(footprint.size.x<40.0 and footprint.size.y<40.0,"M3104 %d balls remain one compact flying pile, not a wide row" % total)
		check(minf(footprint.size.x,footprint.size.y)>14.0 and maxf(footprint.size.x,footprint.size.y)>16.0,"M3104 %d-ball pack visibly separates projectiles at any flight heading" % total)
		var min_separation: float=INF
		for first in cluster.size():
			for second in range(first+1,cluster.size()):
				min_separation=minf(min_separation,cluster[first].distance_to(cluster[second]))
		check(min_separation>=14.0,"M3104 %d-ball pack has clear gaps between adjacent spheres" % total)
		if total==3:
			var corner: float=(cluster[1]-cluster[0]).cross(cluster[2]-cluster[0])
			check(absf(corner)>200.0,"M3104 three balls form a spacious triangle, not overlapping or lining up")
	var sim=SIM.new()
	check(sim.AMMO_NAMES==FX.WEAPONS.slice(0,sim.AMMO_NAMES.size()),"all 28 effects are mapped to actual game ammunition indices")
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
	check(game._ammo_texture(3)==game.LEUCHT_ICON,"M3102 colorful 5-jewel Leuchtkugeln shown in ammunition picker")
	check(game.projectile_visual_count in [1,3,5,8],"M3102 restored visual count is supported")
	game._set_projectile_visual_count(5)
	check(game.projectile_visual_count==5,"M3102 five visible projectile mode settable")
	var display_save: Variant=JSON.parse_string(FileAccess.get_file_as_string(game.HUD_SAVE))
	check(display_save is Dictionary and int(display_save.get("projectile_visual_count",0))==5,"M3102 visible-projectile option persists across app restarts")
	game._set_projectile_visual_count(3)
	check(game.projectile_visual_count==3,"M3102 reset visual projectile mode works")
	game.sim.shots.clear()
	game.sim.events.clear()
	game.sim.player.pos=Vector2(2200,1600)
	var enemy: Dictionary=game.sim.npcs[0]
	enemy.pos=Vector2(2420,1600)
	for n in game.sim.AMMO_NAMES.size():
		game.sim._launch(0,int(enemy.id),str(game.sim.AMMO_NAMES[n]),10,1)
	game.sim.clock=1.0
	for projectile: Dictionary in game.sim.shots:projectile.age=.14
	for event: Dictionary in game.sim.events:event.time=.85
	game.queue_redraw()
	await process_frame
	await process_frame
	check(game.drawn_shots==game.sim.AMMO_NAMES.size(),"sea-map draws each of the 28 original missile types")
	# A real three-ball broadside is ONE flying grouped cluster; gameplay still
	# carries three individually damage-bearing, ammo-consuming projectiles.
	game.sim.shots.clear()
	game.sim._launch(0,int(enemy.id),"cannon",17,3)
	var physical_group: int=int(game.sim.shots[0].salvo_group)
	check(game.sim.shots.size()==3,"M3103 physical broadside still has three real projectiles")
	var unique_ids: Dictionary={}
	for projectile: Dictionary in game.sim.shots:
		projectile.age=.25
		unique_ids[int(projectile.id)]=true
		check(int(projectile.salvo_group)==physical_group and int(projectile.salvo_count)==3,
			"M3103 all three real projectiles belong to the same visual pile")
	check(unique_ids.size()==3,"M3103 individual damage-carrying projectiles keep unique IDs")
	game.queue_redraw()
	await process_frame
	await process_frame
	check(game.drawn_shots==1,"M3103 three real shots are drawn as ONE compact Kugelhaufen")
	game._refresh_ui()
	for index in game.sim.AMMO_NAMES.size():
		game.sim.ammo_mode=index
		game._refresh_ui()
		check(bool(game.ammo_selector.get("ammo_marker")),"M3100 color-coded combat HUD enabled")
		check(Color(game.ammo_selector.get("ammo_color"))==FX.weapon_color(str(game.sim.AMMO_NAMES[index])),"HUD accent matches projectile profile "+str(index))
		game._open_modal("Munition")
		check(game.ammo_rows.size()==game.sim.AMMO_NAMES.size() and Color(game.ammo_rows[index].accent)==FX.weapon_color(str(game.sim.AMMO_NAMES[index])),"popover row accent matches flight FX "+str(index))
		game.modal.hide()
	for n in range(7,game.sim.AMMO_NAMES.size()):
		var art: Texture2D=game._ammo_texture(n)
		check(art is AtlasTexture and art.get_width()==128,"M3105 ammo %d has its own 128px cropped visual icon" % n)
	var legacy=SIM.new()
	var old_save=legacy.export_save()
	old_save.ammo=[15,16,17,18,19,20,21]
	check(legacy.restore_save(old_save) and legacy.player.ammo.size()==game.sim.AMMO_NAMES.size() and int(legacy.player.ammo[0])==15 and int(legacy.player.ammo[27])==12,"M3105 legacy 7-ammo saves migrate without loss and grant test stock for new types")
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
