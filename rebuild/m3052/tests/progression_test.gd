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
	var dock_hp: float=sim.player.hp
	var dock_position: Vector2=sim.player.pos
	sim.npcs[0].aggressive=true
	sim.step(10)
	check(sim.clock>clock and sim.npcs[0].pos.distance_to(before)>30,"harbor keeps the sea clock and NPC patrols running")
	check(sim.player.hp==dock_hp and sim.player.pos==dock_position and sim.shots.is_empty(),"docked ship stays protected and moored while NPCs keep moving")
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
	var base_hull=int(sim.npcs[0].max_hp)
	sim.npcs[0].hp=123
	check(sim.travel(1) and sim.map_id==1 and sim.visited[1],"portal loads northern region after unlocking")
	check(int(sim.npcs[0].max_hp)==roundi(float(base_hull)*float(SIM.CONTENT.MAPS[1].enemy_scale)) and sim.islands[0].art=="snow2","new map scales whichever verified NPC art roster is installed")
	check(sim.shots.is_empty() and sim.target==-1 and not sim.firing,"map switch clears stale combat references")
	var route=sim.plan_path(sim.START,sim.portals[1].pos)
	check(not route.is_empty(),"northern return portal has a navigable route")
	sim.player.pos=sim.portals[1].pos
	check(sim.travel(0) and int(sim.npcs[0].hp)==123,"returning preserves previous map enemy state")
	sim.award_xp(1000)
	# Travel through the actual adjacent 2/1 portal before entering 3/1.
	sim.player.pos=sim.portals[0].pos
	check(sim.travel(1),"40-map topology requires the adjacent northern sea")
	sim.player.pos=sim.portals[0].pos
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
				if body.kind!="tower" and sim.blocked(body.pos,15):invariant=false
		check(invariant,"regional NPC navigation avoids coastlines %d"%region)

	for start_region in 3:
		sim=SIM.new();sim.level=20;sim.configure_map(start_region);sim.npcs.clear();sim.drops.clear()
		sim.EXPANSION.set_event(sim,"off")
		var original_gold: int=sim.player.gold
		var destination: int=sim.portals[0].destination
		check(sim.request_portal(destination) and sim.pending_portal==destination,"portal request queues route from region "+str(start_region))
		for _i in 1800:
			sim.step(1.0/30.0)
			if sim.map_id!=start_region:break
		check(sim.map_id==destination and sim.pending_portal==-1 and sim.near_portal()==-1,"real sailing reaches portal and changes region exactly once: "+str(start_region))
		check(sim.visited[destination] and sim.player.gold==original_gold,"automatic crossing preserves wallet and records destination")
		sim.npcs.clear()
		check(sim.request_portal(start_region),"return portal accepts route")
		for _i in 1800:
			sim.step(1.0/30.0)
			if sim.map_id==start_region:break
		check(sim.map_id==start_region,"return crossing completes through actual sailing")
	sim=SIM.new();sim.npcs.clear()
	check(not sim.request_portal(1) and "stufe 2" in sim.message.to_lower() and sim.pending_portal==-1,"locked portal explains the actual level requirement")
	sim.level=4;sim.player.pos=sim.portals[0].pos;sim.player.last_hit=sim.clock
	check(sim.request_portal(1) and sim.map_id==0,"combat cooldown queues crossing without escaping immediately")
	sim.step(3)
	check(sim.map_id==0 and "Portal wartet" in sim.message,"portal waits while combat cooldown remains")
	sim.step(3.1)
	check(sim.map_id==1,"waiting portal completes after six seconds without damage")
	sim=SIM.new();sim.level=4
	check(sim.request_portal(1) and sim.course(sim.START+Vector2(150,0)) and sim.pending_portal==-1,"a new water course cancels pending portal intent")
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
	check(restored.restore_save(starter_save) and int(restored.player.skin)==0,"retired starter skin is migrated to shaded ship")
	var extra_save: Dictionary=starter_save.duplicate(true)
	extra_save["skin"]=29
	check(restored.restore_save(extra_save) and int(restored.player.skin)==0,"old 3D test skin 29 migrates to shaded ship")
	var legacy={"schema":1,"gold":543,"ammo":[50,20,10],"skin":8,"kills":3,"claimed":true}
	check(restored.restore_save(legacy) and int(restored.player.gold)==543 and int(restored.player.skin)==0 and restored.quest_index==1,"M3052 legacy wallet, design and claimed quest migrate")
	check(not restored.restore_save({"schema":999}),"unsupported saves are rejected")
	# Compare a read-only projection with the real purchase, including multipliers.
	for stage in [0,2,SIM.CONTENT.CASTLE_MAX-1]:
		for key: String in SIM.CONTENT.UPGRADE_KEYS:
			var projected=SIM.new()
			projected.level=40;projected.docked=true;projected.player.gold=1000000
			projected.upgrades[key]=stage
			projected.talents={"gunnery":3,"armor":2,"navigation":1}
			projected.activate_blessing(90)
			projected.apply_upgrades();projected.player.hp-=123
			var snapshot: String=JSON.stringify([projected.player,projected.upgrades,projected.talents,projected.buffs,projected.message])
			var hp_before: float=float(projected.player.hp)
			var preview: Dictionary=projected.castle_upgrade_preview(key)
			check(JSON.stringify([projected.player,projected.upgrades,projected.talents,projected.buffs,projected.message])==snapshot and float(projected.player.hp)==hp_before,"castle preview is read-only: "+key+str(stage))
			check(bool(preview.can_upgrade) and projected.buy_upgrade(key),"preview allows exactly the real legal purchase: "+key+str(stage))
			var actual: Array=[]
			match key:
				"cannon":actual=[projected.weapon_damage(0)]
				"harpoon":actual=[projected.weapon_damage(2)]
				"hull":actual=[projected.player.max_hp,projected.player.max_shield]
				"sails":actual=[projected.player.speed]
				"crew":actual=[projected.reload_time(),projected.loot_gold(100)]
				"war":actual=[int(projected.upgrades.war)*10]
			for i in actual.size():check(is_equal_approx(float(preview.rows[i].after),float(actual[i])),"preview equals committed upgrade: "+key+str(stage)+"/"+str(i))
	var denied=SIM.new()
	check(denied.castle_upgrade_preview("unknown").is_empty(),"unknown upgrade has no fabricated preview")
	check(denied.castle_upgrade_preview("hull").reason=="AM HAFEN ANDOCKEN","castle preview explains physical docking prerequisite")
	denied.docked=true;denied.player.gold=0
	check(denied.castle_upgrade_preview("hull").reason.begins_with("ES FEHLEN"),"castle preview states missing gold")
	denied.upgrades.hull=denied.castle_cap()
	check(denied.castle_upgrade_preview("hull").reason.begins_with("AB KAPITÄNSSTUFE"),"castle preview states captain prerequisite")
	denied.upgrades.hull=SIM.CONTENT.CASTLE_MAX
	check(not denied.castle_upgrade_preview("hull").can_upgrade and denied.castle_upgrade_preview("hull").cost==-1,"maxed castle cannot quote another purchase")
	# Repeatable contracts count only actions after a deliberate acceptance.
	var contracts=SIM.new()
	contracts.kills=20;contracts.monster_kills=3;contracts.loot_collected=12
	for key: String in SIM.CONTRACTS.ORDER:
		check(contracts.sea_contracts.accept(contracts,key),"contract can be accepted: "+key)
		check(contracts.sea_contracts.info(contracts,key).progress==0,"historical totals never complete a new contract: "+key)
		check(not contracts.sea_contracts.accept(contracts,key),"repeat acceptance cannot erase active progress: "+key)
	contracts.kills+=1;contracts.monster_kills+=1
	check(contracts.sea_contracts.info(contracts,"patrol").progress==0 and contracts.sea_contracts.info(contracts,"hunt").ready,"monster kill counts for hunt but never the ship contract")
	var contract_gold: int=int(contracts.player.gold)
	var contract_essence: int=contracts.essence
	var contract_quest: int=contracts.quest_index
	check(contracts.sea_contracts.claim(contracts,"hunt") and int(contracts.player.gold)==contract_gold+100 and contracts.essence==contract_essence+1,"contract pays its declared reward")
	contract_gold=int(contracts.player.gold)
	check(not contracts.sea_contracts.claim(contracts,"hunt") and int(contracts.player.gold)==contract_gold,"same contract round cannot pay twice")
	check(contracts.quest_index==contract_quest and contracts.battle_points==0,"contracts do not claim campaign rewards or award PvP points")
	check(contracts.sea_contracts.accept(contracts,"hunt") and contracts.sea_contracts.info(contracts,"hunt").progress==0,"new contract round starts from a fresh baseline")
	contracts.loot_collected+=3
	check(not contracts.sea_contracts.claim(contracts,"salvage"),"incomplete salvage contract cannot pay")
	var contract_saved: Dictionary=JSON.parse_string(JSON.stringify(contracts.export_save()))
	var contract_restored=SIM.new()
	check(contract_restored.restore_save(contract_saved) and contract_restored.sea_contracts.info(contract_restored,"salvage").progress==3,"in-progress contract survives JSON save and reload")
	check(contract_restored.sea_contracts.info(contract_restored,"hunt").completed==1,"completed contract rounds survive reload")
	contract_restored.loot_collected+=1
	check(contract_restored.sea_contracts.claim(contract_restored,"salvage") and not contract_restored.sea_contracts.claim(contract_restored,"salvage"),"restored progress pays exactly once when finished")
	var old_contract_save: Dictionary=contract_saved.duplicate(true)
	old_contract_save.erase("sea_contracts")
	check(contract_restored.restore_save(old_contract_save) and contract_restored.sea_contracts.snapshot().is_empty(),"older saves migrate without invented contracts")
	contract_restored.sea_contracts.restore({"patrol":{"active":true,"start":-50}},contract_restored)
	check(not contract_restored.sea_contracts.info(contract_restored,"patrol").active,"invalid baseline cannot cash historical kills")
	check(not contract_restored.sea_contracts.accept(contract_restored,"unknown") and not contract_restored.sea_contracts.claim(contract_restored,"unknown"),"unknown contract keys are rejected")
	var natural=SIM.new();natural.npcs.clear()
	natural.sea_contracts.accept(natural,"salvage")
	natural.drops.append({"pos":natural.player.pos,"gold":15})
	natural.step(.01)
	check(natural.sea_contracts.info(natural,"salvage").progress==1,"actual sea pickup advances an accepted salvage contract")
	var result={"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
