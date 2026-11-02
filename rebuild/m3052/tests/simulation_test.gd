extends SceneTree
const SIM=preload("res://simulation.gd")
var failures: Array[String]=[]
var count:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	var sim=SIM.new()
	check(sim.npcs.size()==17,"16 ship patrols and one monster exist")
	var npc=sim.npcs[0]
	var initial: Vector2=npc.pos
	sim.player.pos=Vector2(400,400)
	for i in 60:sim.step(1.0/30.0)
	check(npc.pos.distance_to(initial)>30,"patrol moves in the actual simulation")
	var left: Vector2=sim.islands[0].pos-Vector2(330,0)
	var right: Vector2=sim.islands[0].pos+Vector2(330,0)
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
	check(not sim.course(sim.islands[0].pos),"island interior rejects course")

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
	sim=SIM.new()
	var invariant=true
	for i in 1800:
		sim.step(1.0/30.0)
		for body: Dictionary in sim.npcs:
			if sim.blocked(body.pos,15):invariant=false
	check(invariant,"one minute of real NPC movement stays outside islands and bounds")
	var result={"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}
	print(JSON.stringify(result))
	var f=FileAccess.open("user://simulation_results.json",FileAccess.WRITE)
	if f!=null:f.store_string(JSON.stringify(result,"  "));f.close()
	quit(0 if failures.is_empty() else 1)
