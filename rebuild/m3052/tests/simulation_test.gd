extends SceneTree
const SIM=preload("res://simulation.gd")
var failures: Array[String]=[]
var count:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	var sim=SIM.new()
	check(sim.npcs.size()==20,"16 ship patrols and four monsters exist")
	var npc=sim.npcs[0]
	check(str(npc.renderer)=="mesh" and str(npc.navigation)=="mode_adaptive","NPC ship renderer is GLB-capable and its steering follows the chosen graphics mode")
	check(float(npc.speed)<=40.0 and float(sim.npcs[8].speed)<=46.0,"normal and elite NPC speed is rebalanced")
	var sample: Dictionary=npc.duplicate(true)
	sample.pos=Vector2(500,500)
	var free_goal:=Vector2(950,500)
	check(not sim.classic_steering and sim.plan_actor_path(sample,free_goal)==sim.plan_path(sample.pos,free_goal),"native 2.5D/3D ships use original direct navigation")
	sim.set_classic_steering(true)
	check(sim.plan_actor_path(sample,free_goal).back()==free_goal and sim.plan_actor_path(sample,free_goal)!=sim.plan_path(sample.pos,free_goal),"Classic genuinely sails by four diagonal segments, not a visual-only flip")
	sim.set_classic_steering(false)
	var rested: Dictionary=npc.duplicate(true)
	rested.pos=Vector2(400,400)
	rested.home=rested.pos
	rested.path=[Vector2(403,400)]
	rested.repath=0.0
	rested.state="patrol"
	sim._step_npc(rested,0.2)
	check(rested.path.is_empty() and float(rested.repath)>=1.9,"patrol pauses briefly after a finished leg")
	var initial: Vector2=npc.pos
	sim.player.pos=Vector2(400,400)
	for i in 60:sim.step(1.0/30.0)
	check(npc.pos.distance_to(initial)>30,"patrol moves in the actual simulation")
	var left: Vector2=sim.islands[1].pos-Vector2(330,0)
	var right: Vector2=sim.islands[1].pos+Vector2(330,0)
	var route=sim.plan_path(left,right)
	check(not route.is_empty(),"route around island exists")
	var before=left
	var safe=true
	for point: Vector2 in route:
		safe=safe and sim.segment_free(before,point)
		before=point
	check(safe,"all route segments clear coastal collisions")
	sim.player.pos=left
	check(sim.course(right),"click sets route")
	for i in 500:sim._move(sim.player,1.0/30.0)
	check(sim.player.pos.distance_to(right)<4,"ship reaches destination around island")
	var land=Vector2.ZERO
	for vertex: Vector2 in sim.islands[0].outline:land+=vertex
	land/=sim.islands[0].outline.size()
	check(not sim.course(land),"measured island interior rejects course")

	sim=SIM.new()
	npc=sim.npcs[0]
	sim.npcs.clear()
	sim.npcs.append(npc)
	sim.drops.clear()
	sim.player.pos=Vector2(500,500)
	npc.pos=Vector2(900,500)
	npc.home=npc.pos
	sim.select(npc.id)
	var hp=int(npc.hp)
	var ammo=int(sim.player.ammo[0])
	sim._fire_player()
	check(sim.shots.size()==3 and int(npc.hp)==hp,"broadside launches actual projectiles without immediate damage")
	check(int(sim.player.ammo[0])==ammo-3,"broadside consumes exactly three cannonballs")
	sim._step_shots(0.1)
	check(int(npc.hp)==hp,"damage waits for projectile arrival")
	sim._step_shots(1.0)
	check(int(npc.hp)==hp-93,"all three impacts apply their damage")
	npc.hp=20
	sim._fire_player()
	sim._step_shots(1.2)
	check(sim.kills==1 and sim.drops.size()==1,"lethal broadside rewards one kill and one drop")
	var gold=int(sim.player.gold)
	var reward=int(sim.drops[0].gold)
	sim.player.pos=sim.drops[0].pos
	sim.step(0.01)
	sim.step(0.01)
	check(int(sim.player.gold)==gold+reward and sim.drops.is_empty(),"physical loot collection pays exactly once")
	npc.hp=420
	npc.pos=Vector2(900,500)
	sim.player.pos=Vector2(500,500)
	sim.player.ammo[0]=0
	sim._fire_player()
	check(sim.shots.is_empty() and int(sim.player.ammo[0])==0,"empty ammo blocks firing without negative stock")
	sim.set_ammo(2)
	sim._fire_player()
	check(sim.shots.is_empty(),"harpoons cannot damage ship targets")
	sim.set_ammo(1)
	sim._fire_player()
	sim._step_shots(1.2)
	check(float(npc.slow)>0 and int(npc.hp)==363,"chain projectiles damage and slow target")
	sim.player.hp=1000
	sim.player.last_hit=sim.clock
	sim.toggle_repair()
	check(not sim.repairing,"recent combat blocks repair")
	sim.player.last_hit=-100
	sim.toggle_repair()
	sim.target=-1
	npc.pos=Vector2(1500,500)
	npc.home=npc.pos
	sim.step(0.5)
	check(sim.repairing and float(sim.player.hp)>1000,"repair restores hull when out of combat")
	sim.player.hp=0
	sim.player.respawn=0.1
	sim.step(0.2)
	check(int(sim.player.hp)==sim.PLAYER_HP and sim.player.pos==sim.START,"sunk player respawns with intact hull")
	sim.kills=3
	gold=int(sim.player.gold)
	check(sim.claim_quest() and not sim.claim_quest() and int(sim.player.gold)==gold+180,"quest reward cannot be duplicated")
	gold=int(sim.player.gold)
	ammo=int(sim.player.ammo[0])
	check(sim.buy_ammo(0) and int(sim.player.gold)==gold-30 and int(sim.player.ammo[0])==ammo+150,"ammo purchase conserves wallet and stock")
	# Undo selection independently of movement and the already launched
	# projectile queue. Never consume ammunition just by deselecting.
	var cancel_target_sim=SIM.new()
	var marked: int=int(cancel_target_sim.npcs[0].id)
	cancel_target_sim.select(marked)
	cancel_target_sim.firing=true
	cancel_target_sim.player.path=[Vector2(2300,1450)]
	cancel_target_sim.shots.clear()
	cancel_target_sim.shots.append({"source":0,"target":marked,"age":0.2,"pos":cancel_target_sim.player.pos})
	var course_before: Array=cancel_target_sim.player.path.duplicate()
	var volley_before: Array=cancel_target_sim.shots.duplicate(true)
	var ammo_before: Array=cancel_target_sim.player.ammo.duplicate()
	cancel_target_sim.clear_target()
	check(cancel_target_sim.target==-1 and not cancel_target_sim.firing and cancel_target_sim.message=="Zielauswahl aufgehoben","manually cancel selected ship and stop future volleys")
	check(cancel_target_sim.player.path==course_before and cancel_target_sim.shots==volley_before and cancel_target_sim.player.ammo==ammo_before,"canceling a target preserves course, spent projectiles and ammunition")
	cancel_target_sim.select(marked)
	check(cancel_target_sim.target==marked,"an enemy can be selected again after cancellation")
	sim=SIM.new()
	var invariant=true
	for i in 1800:
		sim.step(1.0/30.0)
		for body: Dictionary in sim.npcs:
			if sim.blocked(body.pos,15):invariant=false
	check(invariant,"one minute of real NPC movement stays outside islands and bounds")
	var wallet=SIM.new()
	wallet.pearls=1234;wallet.crystals=56
	var wallet_save: Dictionary=wallet.export_save()
	var loaded_wallet=SIM.new()
	check(loaded_wallet.restore_save(wallet_save) and loaded_wallet.pearls==1234 and loaded_wallet.crystals==56,"pearl and crystal balances survive a save/restart")
	wallet_save.erase("pearls");wallet_save.erase("crystals")
	check(loaded_wallet.restore_save(wallet_save) and loaded_wallet.pearls==0 and loaded_wallet.crystals==0,"old saves migrate without inventing premium balances")
	wallet_save["pearls"]=-50;wallet_save["crystals"]=999999999
	loaded_wallet.restore_save(wallet_save)
	check(loaded_wallet.pearls==0 and loaded_wallet.crystals==99999999,"currency restore rejects negative and out-of-range balances")
	var result={"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}
	print(JSON.stringify(result))
	var f=FileAccess.open("user://simulation_results.json",FileAccess.WRITE)
	if f!=null:f.store_string(JSON.stringify(result,"  "));f.close()
	quit(0 if failures.is_empty() else 1)
