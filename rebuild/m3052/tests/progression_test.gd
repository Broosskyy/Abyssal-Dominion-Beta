extends SceneTree
const SIM = preload("res://simulation.gd")
var failures: Array[String] = []
var count := 0
func check(ok: bool,label: String) -> void:
	count += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	var sim = SIM.new()
	check(not sim.buy_upgrade("cannon"),"upgrades require physical docking")
	sim.player.pos=sim.harbor
	check(sim.dock(),"ship docks at reachable water marker")
	var before: Vector2=sim.npcs[0].pos
	var clock: float=sim.clock
	sim.step(10)
	check(sim.clock==clock and sim.npcs[0].pos==before,"harbor freezes guest combat without advancing enemies")
	check(not sim.course(sim.START),"docked vessel cannot sail until departure")
	var wallet=int(sim.player.gold)
	check(sim.buy_upgrade("cannon") and int(sim.player.gold)==wallet-150,"upgrade debits exact cost once")
	check(sim.weapon_damage(0)==39 and sim.weapon_damage(1)==24,"cannon equipment changes both cannon and chain damage")
	wallet=int(sim.player.gold)
	check(not sim.buy_upgrade("cannon") and int(sim.player.gold)==wallet,"unaffordable upgrade leaves stats and wallet unchanged")
	check(not sim.buy_upgrade("fake"),"unknown equipment is rejected")
	sim.player.gold=10000
	for key in ["cannon","harpoon","hull","sails"]:
		while int(sim.upgrades[key])<3:check(sim.buy_upgrade(key),"upgrade tier purchased: "+key)
		wallet=int(sim.player.gold)
		check(not sim.buy_upgrade(key) and int(sim.player.gold)==wallet,"maximum tier does not charge again: "+key)
	check(int(sim.player.max_hp)==3600 and is_equal_approx(float(sim.player.speed),224.4),"hull and sails modify real ship stats")
	check(sim.weapon_damage(2)==197,"harpoon tiers change actual projectile damage")
	sim.player.hp=2000
	wallet=int(sim.player.gold)
	check(sim.harbor_repair_cost()==40 and sim.harbor_repair() and int(sim.player.hp)==3600 and int(sim.player.gold)==wallet-40,"drydock restores upgraded hull at exact cost")
	check(not sim.harbor_repair(),"full hull cannot be charged for repair")
	sim.depart()
	check(not sim.docked and sim.course(sim.START),"departure resumes movement")

	sim=SIM.new()
	check(not sim.claim_quest(),"unfinished quest cannot pay")
	sim.kills=3
	check(sim.claim_quest() and sim.level==2 and sim.quest_index==1,"coast quest grants gold, XP and next assignment")
	wallet=int(sim.player.gold)
	check(not sim.claim_quest() and int(sim.player.gold)==wallet,"claim cannot pay a different unfinished quest")
	sim.loot_collected=3
	check(sim.claim_quest() and sim.quest_index==2,"salvage unlocks monster hunt")
	sim.monster_kills=1
	check(sim.claim_quest() and sim.level>=3,"monster hunt grants next XP threshold")
	sim.award_xp(10000)
	check(sim.level>4 and sim.level<=20,"large XP award handles multiple level thresholds")

	sim=SIM.new()
	check(not sim.travel(1),"map switch blocked away from portal")
	sim.player.pos=sim.portals[0].pos
	check(not sim.travel(1) and sim.map_id==0,"level gate blocks northern map")
	sim.award_xp(100)
	sim.player.last_hit=sim.clock
	check(not sim.travel(1),"combat prevents portal escape")
	sim.player.last_hit=-100
	sim.npcs[0].hp=123
	check(sim.travel(1) and sim.map_id==1 and sim.visited[1],"portal loads northern region after unlocking")
	check(int(sim.npcs[0].max_hp)==630 and sim.islands[0].art=="snow2","new map uses stronger enemies and regional art")
	check(sim.shots.is_empty() and sim.target==-1 and not sim.firing,"map switch clears stale combat references")
	var route=sim.plan_path(sim.START,sim.portals[1].pos)
	check(not route.is_empty(),"northern return portal has a navigable route")
	sim.player.pos=sim.portals[1].pos
	check(sim.travel(0) and int(sim.npcs[0].hp)==123,"returning preserves previous map enemy state")
	sim.award_xp(1000)
	sim.player.pos=sim.portals[1].pos
	check(sim.travel(2) and sim.map_id==2 and sim.visited[2],"shadow region becomes accessible at level four")
	check(not sim.blocked(sim.START) and not sim.blocked(sim.harbor),"shadow entry and harbor are navigable water")
	for region in 3:
		sim.configure_map(region)
		for portal in sim.portals:
			check(not sim.plan_path(sim.START,portal.pos).is_empty(),"portal reachable on region %d"%region)
		check(not sim.plan_path(sim.START,sim.harbor).is_empty(),"harbor reachable on region %d"%region)
		var invariant=true
		for i in 300:
			sim.step(1.0/30.0)
			for body: Dictionary in sim.npcs:
				if sim.blocked(body.pos,15):invariant=false
		check(invariant,"regional NPC navigation avoids coastlines %d"%region)

	sim=SIM.new()
	sim.player.gold=4000
	sim.player.pos=sim.harbor
	sim.dock()
	sim.buy_upgrade("hull")
	sim.buy_upgrade("cannon")
	sim.level=4
	sim.xp=27
	sim.quest_index=3
	sim.loot_collected=7
	var saved: Dictionary=JSON.parse_string(JSON.stringify(sim.export_save()))
	var restored=SIM.new()
	check(restored.restore_save(saved),"current save schema is accepted")
	check(restored.level==4 and restored.xp==27 and restored.quest_index==3 and restored.loot_collected==7,"XP and quest progress survive JSON roundtrip")
	check(restored.upgrades.hull==1 and restored.upgrades.cannon==1 and int(restored.player.max_hp)==2800,"equipment and derived stats survive JSON roundtrip")
	check(restored.docked and restored.player.pos==sim.player.pos and int(restored.player.gold)==int(sim.player.gold),"docking, wallet and position survive reload")
	var starter_save=sim.export_save()
	starter_save["skin"]=26
	check(restored.restore_save(starter_save) and int(restored.player.skin)==26,"new Small Starter survives save and restore without clamping to an old design")
	var legacy={"schema":1,"gold":543,"ammo":[50,20,10],"skin":8,"kills":3,"claimed":true}
	check(restored.restore_save(legacy) and int(restored.player.gold)==543 and int(restored.player.skin)==8 and restored.quest_index==1,"M3052 legacy wallet, design and claimed quest migrate")
	check(not restored.restore_save({"schema":999}),"unsupported saves are rejected")
	var result={"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
