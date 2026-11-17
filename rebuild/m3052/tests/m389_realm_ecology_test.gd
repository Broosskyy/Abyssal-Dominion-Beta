extends SceneTree
## M389: authored geography and gameplay rewards in all twenty beta seas,
## strictly without changing legacy maps, movement, paid systems or saves.
const SIM=preload("res://simulation.gd")
const CONTENT=preload("res://content.gd")
const ECO=preload("res://realm_ecology.gd")
const ATLAS=preload("res://realm_catalog.gd")
var checks:int=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func _initialize()->void:
	call_deferred("_run")

func _run()->void:
	check(ECO.GUARDIANS.size()==20 and ECO.GUARDIANS.duplicate().size()==20,"all twenty seas have encounter names")
	var guardians:Dictionary={}
	var map_signatures:Dictionary={}
	for realm_id in range(1,21):
		var index:int=CONTENT.realm_map_id(realm_id)
		check(ECO.map_realm(index)==realm_id,"ecology maps to real sea "+str(realm_id))
		check(ECO.biome(realm_id)!="","every sea has a biome")
		var name:String=ECO.monster_title(realm_id,"tiamat")
		check(not guardians.has(name),"each guardian is named differently")
		guardians[name]=true
		var positions:Dictionary={}
		var art_types:Dictionary={}
		var signature:Array=[]
		for half in 2:
			for slot in 9:
				var p:Vector2=ECO.island_site(realm_id,slot,half)
				var art:String=ECO.island_art(realm_id,slot,half)
				check(p.is_finite() and p.x>480.0 and p.x<17120.0 and p.y>480.0 and p.y<5920.0,"island is inside navigable region")
				check((p.x<8800.0)==(half==0),"island stays in its intended half")
				check(not ECO.island_title(realm_id,slot,half).is_empty(),"island identity present")
				art_types[art]=true
				for other in positions.values():
					check(p.distance_to(Vector2(other))>485.0,"no overlapping large land bases in realm "+str(realm_id))
				positions[str(half)+"_"+str(slot)]=p
				signature.append([p.x,p.y,art])
		check(positions.size()==18 and art_types.size()>=2,"18 varied islands in distinct region biome")
		var fingerprint:String=JSON.stringify(signature)
		check(not map_signatures.has(fingerprint),"landmark layouts differ between seas")
		map_signatures[fingerprint]=true
		for patrol in 16:
			var p:Vector2=ECO.patrol_site(realm_id,patrol)
			check(p.x>450 and p.x<17150 and p.y>450 and p.y<6000,"patrol spawn stays in physical sea")
			check(not ECO.patrol_title(realm_id,patrol).is_empty(),"named patrol exists")
		for monster_key in ["kraken","serpent","crab"]:
			check(not ECO.monster_title(realm_id,monster_key).is_empty(),"regional species named")
		var q:Dictionary=ECO.mission(realm_id)
		check(q.salvage_goal==3 and q.hunt_goal==1,"bounties require actual salvage and harpoon kill")
		check(q.gold>0 and q.xp>0 and q.essence>0,"all bounties award useful PvE progress")
	check(ECO.island_site(0,0,0)==Vector2(-1,-1),"invalid realms cannot invent land")
	check(ECO.mission(21).is_empty(),"no invented reward for nonexistent regions")

	var s=SIM.new()
	check(s.map_id==0 and s.islands.size()==9 and s.npcs.size()==20,"existing classic sea is untouched")
	check(s.realm_mission_info().is_empty() and not s.claim_realm_mission(),"no new rewards in old sea")
	for realm_id in [1,5,9,13,20]:
		s.configure_map(CONTENT.realm_map_id(realm_id))
		check(s.islands.size()==18 and s.world_extent()==Vector2(17600,6400),"sea has two contiguous coastlines")
		check(s.npcs.size()==20,"sixteen normal ship NPCs and four sea monsters")
		check(s.npcs.filter(func(a):return str(a.kind)=="monster").size()==4,"existing monster renderer can display all regional hunts")
		check(s.islands.any(func(a):return float(a.pos.x)>13000.0),"east half includes actual islands")
		check(s.islands.any(func(a):return float(a.pos.x)<5000.0),"west half includes actual islands")
		check(not s.blocked(s.harbor),"harbor stays in open water")
		check(not s.blocked(SIM.START),"player starts on navigable sea")
		for actor:Dictionary in s.npcs:
			check(not s.blocked(actor.pos),"live ships and monsters spawn at sea, not on islands")
		for drop:Dictionary in s.drops:
			check(not s.blocked(drop.pos),"salvage gold cannot spawn under solid coast")
		for pickup:Dictionary in s.sparkles:
			check(not s.blocked(pickup.pos),"mission salvage pickups are accessible")
		check(s.npcs.any(func(a):return str(a.name)==ECO.monster_title(realm_id,"tiamat")),"real regional guardian appears in encounter roster")
		check(s.npcs.filter(func(a):return str(a.kind)=="ship").any(func(a):return str(a.name).begins_with(str(ATLAS.realm(realm_id).name))),"patrols display regional names")
		var m:Dictionary=s.realm_mission_info()
		check(m.salvage==0 and m.hunts==0 and not m.ready,"new region bounty starts unclaimed")

	s.configure_map(CONTENT.realm_map_id(5))
	s.player.hp=s.player.max_hp
	var initial:Dictionary=s.realm_mission_info()
	s._realm_mission_record("salvage")
	check(s.realm_mission_info().salvage==1,"real salvage event advances only local region")
	for pickup in s.sparkles.slice(0,2):
		s.player.pos=Vector2(pickup.pos)
		s._collect_sparkles()
	check(s.realm_mission_info().salvage==3,"collecting two actual sea pickups completes salvage requirement")
	var monster:Dictionary=s.npcs.filter(func(a):return str(a.kind)=="monster")[0]
	var gold_before:int=int(s.player.gold)
	check(not s.claim_realm_mission() and s.player.gold==gold_before,"cannot claim with zero monster kills")
	monster.hp=1
	monster.shield=0
	s._hit({"source":0,"damage":1000000,"weapon":"harpoon"},monster)
	check(s.realm_mission_info().hunts==1 and bool(s.realm_mission_info().ready),"real kill registers once")
	s._hit({"source":0,"damage":1000000,"weapon":"harpoon"},monster)
	check(s.realm_mission_info().hunts==1,"cannot farm a single corpse twice")
	gold_before=int(s.player.gold)
	var essence_before:int=s.essence
	check(s.claim_realm_mission(),"ready region bounty pays once")
	check(int(s.player.gold)==gold_before+int(initial.gold) and s.essence==essence_before+int(initial.essence),"bounty pays exactly the declared wallet rewards")
	gold_before=int(s.player.gold)
	check(not s.claim_realm_mission() and int(s.player.gold)==gold_before,"already claimed bounty cannot pay again")
	var exported:Dictionary=s.export_save()
	var reload=SIM.new()
	check(reload.restore_save(exported) and bool(reload.realm_mission_info().claimed),"mission claim survives restart")
	check(not reload.claim_realm_mission() and int(reload.player.gold)==gold_before,"relaunch cannot duplicate bounties")
	reload.configure_map(CONTENT.realm_map_id(6))
	check(reload.realm_mission_info().salvage==0 and not reload.realm_mission_info().claimed,"other region bounty remains independent")
	reload.configure_map(CONTENT.realm_map_id(5))
	check(bool(reload.realm_mission_info().claimed),"return trip restores original mission completion")
	reload.configure_map(0)
	check(reload.realm_mission_info().is_empty(),"old world has no changed quest system")
	var tampered:Dictionary=exported.duplicate(true)
	tampered.realm_missions={"5":{"salvage":99999,"hunts":99999,"claimed":false},"0":{"salvage":99,"hunts":99},"500":{"claimed":true}}
	var safe=SIM.new()
	check(safe.restore_save(tampered),"legacy schema accepts optional region bounty states")
	check(safe.realm_mission_info().salvage==3 and safe.realm_mission_info().hunts==1,"untrusted progress is clamped before payout")
	check(safe.realm_missions.size()==1,"invalid realm IDs are rejected on load")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
