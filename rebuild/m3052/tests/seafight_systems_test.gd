extends SceneTree
const SIM=preload("res://simulation.gd")
const CONTENT=preload("res://content.gd")
var failures: Array[String]=[]
var count:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:failures.append(label)
func duel(sim) -> Dictionary:
	sim.npcs.clear();sim.drops.clear();sim.sparkles.clear()
	var npc: Dictionary=sim.base_npcs[0].duplicate(true)
	sim.player.pos=Vector2(500,500);npc.pos=Vector2(900,500);npc.home=npc.pos
	sim.npcs.append(npc);sim.select(npc.id)
	return npc
func last_audit(sim) -> Dictionary:
	return sim.staff.audit[sim.staff.audit.size()-1] if not sim.staff.audit.is_empty() else {}
func _staff_checks() -> void:
	# Roles, codes and the audit trail.
	for role in CONTENT.STAFF_ROLE_ORDER:check(sim_role("%s-3060" % role)==role,"%s test code unlocks its role" % role)
	check(sim_role("admin 3060")=="ADMIN" and sim_role("ADMIN-3061")=="" and sim_role("")=="","codes ignore case and separators but nothing else")
	var plain:=true
	for role in CONTENT.STAFF_ROLE_ORDER:plain=plain and not "3060" in str(CONTENT.STAFF_ROLES[role].code_sha256)
	check(plain,"content stores only code hashes")
	var sim=SIM.new()
	check(not sim.staff_sign_in("falsch") and not sim.staff.active() and not bool(last_audit(sim).allowed),"wrong code is refused and logged")
	check(not sim.staff_teleport(0,"harbor") and not sim.staff_grant("gold"),"tools need a signed-in role")
	sim.player.gold=500
	check(sim.staff_sign_in("mod-3060") and sim.staff.role=="MOD" and sim.staff.shows_badge() and sim.staff.badge()=="MOD","moderator signs in with an official badge")
	check(not sim.staff_spawn("dummy") and not sim.staff_grant("gold") and not sim.staff_teleport(0,"harbor") and int(sim.player.gold)==500,"moderator cannot spawn, grant or teleport")
	check(not bool(last_audit(sim).allowed) and "Recht fehlt" in str(last_audit(sim).detail),"refused tools are written to the audit trail")
	check(sim.staff_set_presence("ghost") and sim.staff.hidden() and not sim.staff.shows_badge(),"ghost presence hides the badge")
	var npc: Dictionary=duel(sim);npc.aggressive=true
	check(not sim.npc_engages(npc) and sim.apply_damage(sim.player,400)==0,"ghosts are not attacked")
	check(sim.staff_sign_out(true) and not sim.staff.active() and int(sim.player.gold)==500,"sign-out restores the starting state")
	# Ship powers.
	sim=SIM.new();sim.staff_sign_in("ADMIN-3060")
	check(sim.staff_toggle("god") and sim.apply_damage(sim.player,900)==0 and int(sim.player.hp)==sim.PLAYER_HP,"god mode ignores damage")
	npc=duel(sim);npc.aggressive=true
	check(sim.npc_engages(npc),"an official staff ship is still a target")
	check(sim.staff_toggle("no_aggro") and not sim.npc_engages(npc) and not bool(npc.aggressive),"no-aggro calms enemies")
	sim.staff_toggle("unlimited_ammo");sim.staff_toggle("instant_reload")
	var ammo: int=sim.player.ammo[0];sim.player.reload=0;sim._fire_player()
	check(int(sim.player.ammo[0])==ammo and is_equal_approx(float(sim.player.reload),0.25),"unlimited ammo and instant reload")
	sim.staff_toggle("speed");sim.player.path=[sim.player.pos+Vector2(2000,0)];sim.player.pos=Vector2(500,900);sim.player.path=[Vector2(2000,900)]
	sim._move(sim.player,1.0)
	check(is_equal_approx(float(sim.player.pos.x),500+sim.PLAYER_SPEED*2.5),"rush speed moves 2.5 times as far")
	# Staff kills never score.
	sim.select(npc.id);npc.hp=1;npc.shield=0
	var gold: int=sim.player.gold
	sim._hit({"source":0,"damage":50,"weapon":"cannon"},npc)
	check(sim.kills==0 and sim.drops.is_empty() and sim.xp==0 and int(sim.player.gold)==gold and sim.staff_kills==1,"staff kills give no loot, XP or ranking")
	# Teleport across maps, including bonus maps.
	sim.level=1
	check(sim.staff_teleport(2,"fortress") and sim.map_id==2 and not sim.blocked(sim.player.pos) and sim.player.pos.y>sim.fortress_island().bounds.end.y,"teleport ignores level gates and lands below the fortress")
	check(sim.staff_teleport(2,"",Vector2(3000,700)) and sim.player.pos.distance_to(Vector2(3000,700))<200,"teleport to a chart point")
	check(sim.staff_teleport(4,"start") and sim.in_bonus_map() and bool(sim.bonus.staff) and int(sim.bonus.origin)==2,"teleport opens a staff test run on a bonus map")
	sim.step(3.5)
	for body: Dictionary in sim.npcs:body.hp=0
	gold=sim.player.gold;sim.step(0.1)
	check(int(sim.bonus.wave)==1 and int(sim.player.gold)==gold,"staff test waves pay nothing")
	check(sim.staff_world("skip_wave") and sim.bonus_wave_alive()==0,"skip wave on a staff run")
	var saved: Dictionary=sim.export_save()
	check(int(saved.map_id)==2 and (saved.bonus as Dictionary).is_empty(),"staff test runs are never saved")
	check(sim.staff_teleport(0,"harbor") and sim.map_id==0 and sim.bonus.is_empty() and sim.player.pos.distance_to(sim.harbor)<200,"teleport home closes the test run")
	# Spawns, target tools and grants.
	check(sim.staff_spawn("dummy") and bool(sim.actor(sim.target).frozen) and bool(sim.actor(sim.target).staff_spawn) and int(sim.actor(sim.target).reward)==0,"training target spawns frozen and selected")
	var dummy: Dictionary=sim.actor(sim.target)
	check(sim.staff_inspect().get("name","")==dummy.name and sim.staff_target("sink") and int(dummy.hp)==0,"inspect and sink the selected target")
	sim.step(60)
	check(int(dummy.hp)==0,"staff targets do not respawn")
	for i in 14:sim.staff_spawn("ship")
	check(sim.staff_spawn_count()==12,"staff spawns are capped")
	check(sim.staff_clear_spawns() and sim.staff_spawn_count()==0,"staff spawns can be cleared")
	gold=sim.player.gold
	check(sim.staff_grant("gold") and int(sim.player.gold)==gold+10000 and sim.staff_grant("decks") and sim.owns_deck("cannon",2),"admin grants gold and decks")
	check(sim.staff.touched and sim.staff.audit.size()>=10,"privileged actions are audited")
	var state: Dictionary=JSON.parse_string(JSON.stringify(sim.staff.export_state()))
	var copy=SIM.new();copy.staff.restore_state(state)
	check(copy.staff.role=="ADMIN" and copy.staff.flag("god") and copy.staff.audit.size()==sim.staff.audit.size(),"staff session survives an app restart")
	check(sim.staff_sign_out(false) and sim.staff_marked and bool(sim.export_save().staff_marked) and not sim.staff.flag("god"),"keeping staff changes marks the save")
	# GM has no grant right; QA has no summon right.
	sim=SIM.new();sim.staff_sign_in("GM-3060")
	check(not sim.staff_grant("gold") and sim.staff_spawn("ship"),"game master spawns but cannot grant")
	sim.staff_sign_out(true)
	sim.staff_sign_in("QA-3060");npc=duel(sim)
	check(not sim.staff_summon_target() and sim.staff_teleport_target() and sim.target==int(npc.id),"QA jumps to targets but cannot summon")
	check(sim.staff_set_presence("spectator"),"spectator presence")
	sim.player.reload=0;sim.firing=true;sim._fire_player()
	check(sim.shots.is_empty() and not sim.firing,"spectators cannot fire")
	# A real bonus run blocks staff test runs.
	sim=SIM.new();sim.level=2;sim.scrolls[0]=1;sim.player.last_hit=-100;sim.start_bonus(0);sim.staff_sign_in("ADMIN-3060")
	check(not sim.staff_teleport(4,"start") and sim.staff_teleport(0,"start") and str(sim.bonus.state)=="break" and not sim.in_bonus_map(),"teleporting out pauses a real bonus run")
	# Guild tags that imitate staff badges.
	for tag in ["ADM","4DM","M0D","GM1","QA","MODS"]:check(SIM.reserved_tag(tag),"guild tag %s is reserved" % tag)
	for tag in ["TSW","KRAK","AB"]:check(not SIM.reserved_tag(tag),"guild tag %s is allowed" % tag)
	sim=SIM.new();sim.player.gold=1000
	check(not sim.found_guild("Falsche Admins","4DM") and sim.guild.is_empty(),"founding refuses a reserved tag")
func sim_role(code: String) -> String:
	return preload("res://staff.gd").role_for_code(code)
func _initialize() -> void:
	# Hull and shield are separate resources.
	var sim=SIM.new()
	check(int(sim.player.shield)==sim.PLAYER_SHIELD and int(sim.player.max_shield)==sim.PLAYER_SHIELD,"captain starts with a full shield next to the hull")
	sim.apply_damage(sim.player,300)
	check(int(sim.player.shield)==700 and int(sim.player.hp)==sim.PLAYER_HP,"shield absorbs damage before the hull")
	sim.apply_damage(sim.player,900)
	check(int(sim.player.shield)==0 and int(sim.player.hp)==sim.PLAYER_HP-200,"overflow damage reaches the hull")
	var shield_before: float=sim.player.shield
	sim.player.last_hit=sim.clock
	sim.step(1.0)
	check(float(sim.player.shield)==shield_before,"shield waits for its regeneration delay")
	sim.player.last_hit=sim.clock-20
	sim.step(1.0)
	check(float(sim.player.shield)>shield_before and float(sim.player.shield)<=float(sim.player.max_shield),"shield regenerates after the delay")
	sim=SIM.new()
	sim.player.hp=1000;sim.player.shield=0;sim.player.last_hit=sim.clock-6.5
	sim.toggle_repair()
	sim.step(0.5)
	check(sim.repairing and float(sim.player.hp)>1000 and float(sim.player.shield)==0,"hull repair never refills the shield")
	var npc: Dictionary

	# Panzerplatten reduce incoming damage and are spent per received hit.
	sim=SIM.new();sim.player.shield=0
	check(sim.toggle_supply("plates") and sim.plates_on,"armor plates toggle on")
	var plates: int=sim.supplies.plates
	sim.apply_damage(sim.player,100)
	check(int(sim.player.hp)==sim.PLAYER_HP-65 and int(sim.supplies.plates)==plates-1,"one plate reduces one hit by 35 %")
	sim.supplies.plates=1;sim.apply_damage(sim.player,100)
	check(not sim.plates_on and int(sim.supplies.plates)==0,"plates switch off when the last plate is spent")
	check(not sim.toggle_supply("plates") and not sim.plates_on,"empty plates cannot be switched on")

	# Schwarzpulver is consumed only by a valid salvo.
	sim=SIM.new();npc=duel(sim)
	sim.toggle_supply("powder")
	var powder: int=sim.supplies.powder
	npc.pos=Vector2(1400,500)
	sim._fire_player()
	check(int(sim.supplies.powder)==powder and sim.shots.is_empty(),"out-of-range attempt keeps the powder")
	npc.pos=Vector2(900,500);sim.set_ammo(2);sim._fire_player()
	check(int(sim.supplies.powder)==powder and sim.shots.is_empty(),"wrong ammunition keeps the powder")
	sim.set_ammo(0);sim.player.reload=0;sim._fire_player()
	check(int(sim.supplies.powder)==powder-1 and sim.shots.size()==3 and int(sim.shots[0].damage)==roundi(31*1.4),"valid salvo spends one powder for +40 % damage")

	# Emergency items have their own cooldowns.
	sim=SIM.new();sim.player.hp=1000
	var kits: int=sim.supplies.repair_kit
	check(sim.use_supply("repair_kit") and is_equal_approx(float(sim.player.hp),1000+sim.PLAYER_HP*0.35) and int(sim.supplies.repair_kit)==kits-1,"repair kit heals 35 % of the hull and spends one kit")
	check(not sim.use_supply("repair_kit") and int(sim.supplies.repair_kit)==kits-1,"repair kit cooldown blocks a second use")
	sim.step(46)
	sim.player.hp=500
	check(sim.use_supply("repair_kit"),"repair kit is usable again after its cooldown")
	sim.player.shield=0
	check(sim.use_supply("shield_charge") and int(sim.player.shield)==500,"shield charge restores half the shield")
	check(not sim.use_supply("shield_charge"),"shield charge has its own cooldown")

	# Cannon capacity is separate from owned cannons.
	sim=SIM.new()
	check(sim.cannon_slots()==10 and sim.equipped_cannons()==10 and sim.weapon_damage(0)==31,"ten slots and ten cannons keep the original salvo")
	check(not sim.buy_cannons(),"cannons are bought in the harbor")
	sim.player.pos=sim.harbor;sim.dock();sim.player.gold=5000
	check(sim.buy_cannons() and int(sim.player.cannons)==12 and sim.equipped_cannons()==10,"extra cannons wait for free slots")
	sim.add_tide_deck(1800)
	check(sim.cannon_slots()==20 and sim.equipped_cannons()==12 and sim.weapon_damage(0)==roundi(31*1.2),"tide deck adds ten slots and the extra cannons fire")
	sim.add_tide_deck(1800)
	check(is_equal_approx(float(sim.buffs.tide_deck),3600),"finding another tide deck extends its time")
	sim.step(3601)
	check(sim.cannon_slots()==10 and sim.equipped_cannons()==10,"expired tide deck returns the slots")

	# Kristallsegen: one major blessing with moderate combined bonuses.
	sim=SIM.new()
	sim.activate_blessing(60)
	check(int(sim.player.max_hp)==roundi(sim.PLAYER_HP*1.2) and int(sim.player.hp)==int(sim.player.max_hp),"blessing raises and fills the extra hull")
	check(sim.weapon_damage(0)==roundi(31*1.15) and sim.cannon_slots()==15 and is_equal_approx(float(sim.player.speed),sim.PLAYER_SPEED*1.1),"blessing adds damage, five slots and speed")
	sim.activate_blessing(30)
	check(is_equal_approx(float(sim.buffs.blessing),60),"a second blessing never stacks on top of the first")
	sim.step(61)
	check(int(sim.player.max_hp)==sim.PLAYER_HP and not sim.has_blessing(),"blessing expires back to base values")

	# Decks.
	sim=SIM.new()
	check(sim.grant_deck("armor",0) and sim.deck_slots[0]==0,"first deck mounts into a free slot")
	check(int(sim.player.max_hp)==roundi(sim.PLAYER_HP*1.1) and int(sim.player.max_shield)==roundi(sim.PLAYER_SHIELD*1.1),"armor deck raises hull and shield")
	var essence: int=sim.essence
	check(not sim.grant_deck("armor",0) and sim.essence==essence+CONTENT.DUPLICATE_DECK_ESSENCE and sim.decks.size()==1,"duplicate deck converts into essence")
	sim.grant_deck("armor",1)
	check(sim.deck_slots.size()==10 and sim.deck_slots[1]==1,"separate physical decks can occupy the ten slots")
	check(not sim.equip_deck(1,1),"decks are rebuilt only in the harbor")
	sim.player.pos=sim.harbor;sim.dock()
	check(sim.equip_deck(1,1),"different copies of a deck role can be mounted together")
	check(sim.equip_deck(1,0) and int(sim.player.max_hp)==roundi(sim.PLAYER_HP*1.15),"higher tier deck replaces the mounted one")
	sim.player.gold=1000
	check(sim.buy_deck("cannon") and sim.deck_slots[1]==2 and sim.cannon_slots()==14,"harbor sells a tier I cannon deck that adds capacity")
	check(sim.unequip_deck(1) and sim.cannon_slots()==10,"unmounting a deck removes its bonus")

	# Kastelle: six castles to level 8, paced by captain level.
	sim=SIM.new();sim.player.pos=sim.harbor;sim.dock();sim.player.gold=99999
	check(CONTENT.UPGRADE_KEYS.size()==6,"six castles are available")
	for i in 3:sim.buy_upgrade("crew")
	check(int(sim.upgrades.crew)==3 and is_equal_approx(sim.reload_time(),sim.BASE_RELOAD*0.88),"crew castle shortens the reload")
	check(not sim.buy_upgrade("crew") and int(sim.upgrades.crew)==3,"castle level 4 needs a higher captain level")
	sim.level=3
	check(sim.buy_upgrade("crew") and int(sim.upgrades.crew)==4,"captain level 3 opens castle level 4")
	sim.level=20
	while sim.buy_upgrade("crew"):pass
	check(int(sim.upgrades.crew)==CONTENT.CASTLE_MAX and sim.upgrade_cost("crew")==-1,"castles stop at level 8")
	check(sim.loot_gold(100)==roundi(100*(1+0.08*8)),"crew castle increases loot gold")
	sim.upgrades.war=2
	npc=duel(sim);sim.docked=false;npc.elite=true;sim.player.reload=0
	sim._fire_player()
	check(int(sim.shots[0].damage)==roundi(31*1.2),"war castle adds damage against elites")

	# Gezeitenessenz and the cauldron.
	sim=SIM.new()
	check(sim.sparkles.size()==5,"each region shows five essence sparkles")
	var sparkle: Dictionary=sim.sparkles[0]
	essence=sim.essence
	sim.player.pos=sparkle.pos;sim._collect_sparkles()
	check(sim.essence==essence+1 and float(sparkle.respawn)>0,"sailing through a sparkle pays one essence")
	sim._collect_sparkles()
	check(sim.essence==essence+1,"a collected sparkle pays only once")
	check(sim.throw_kessel(1).is_empty(),"cauldron stands in the harbor")
	sim.player.pos=sim.harbor;sim.dock()
	sim.essence=4
	check(sim.throw_kessel(5).is_empty() and sim.essence==4,"not enough essence throws nothing")
	check(sim.throw_kessel(3).is_empty(),"only the published throw sizes are allowed")
	var results: Array=sim.throw_kessel(1)
	check(results.size()==1 and sim.essence==3 and sim.kessel_meter==1,"every flask pays one visible reward and fills the meter")
	sim.essence=9
	results=sim.throw_kessel(5)
	var weights:=0
	for entry: Dictionary in CONTENT.KESSEL_POOL:weights+=int(entry.weight)
	check(weights==100,"published pool weights add up to 100 %")
	results=sim.throw_kessel(1)
	sim.essence=10
	var kits_before: int=sim.supplies.repair_kit
	results=sim.throw_kessel(1)
	results.append_array(sim.throw_kessel(1))
	results.append_array(sim.throw_kessel(1))
	var milestone:=false
	for entry: Dictionary in results:milestone=milestone or bool(entry.get("milestone",false))
	check(milestone and sim.kessel_meter==10 and int(sim.supplies.repair_kit)>=kits_before+2,"grand meter pays its ten-throw milestone")
	check(sim.free_flask_ready("2026-11-04") and sim.claim_free_flask("2026-11-04").size()>=1,"daily free flask pays without essence")
	check(not sim.free_flask_ready("2026-11-04") and sim.claim_free_flask("2026-11-04").is_empty(),"free flask is limited to one per day")
	check(sim.free_flask_ready("2026-11-05"),"next day brings a new free flask")
	var hundred=SIM.new();hundred.player.pos=hundred.harbor;hundred.dock();hundred.essence=100
	for i in 4:hundred.throw_kessel(25)
	check(hundred.kessel_meter==0 and hundred.owns_deck("cannon",1) and hundred.scrolls[0]>=1,"full meter pays every milestone and starts a new cycle")

	# Bonus maps.
	sim=SIM.new();sim.level=2;sim.player.last_hit=-100
	check(not sim.start_bonus(0),"bonus map needs a scroll")
	sim.fragments=5
	check(sim.craft_scroll(0) and sim.scrolls[0]==1 and sim.fragments==0,"five fragments craft a bronze scroll")
	check(not sim.craft_scroll(0),"crafting needs enough fragments")
	sim.scrolls[1]=1
	check(not sim.start_bonus(1),"silver map keeps its level gate")
	var gold: int=sim.player.gold
	check(sim.start_bonus(0) and sim.in_bonus_map() and sim.scrolls[0]==0 and sim.map_id==3,"bronze scroll opens the bronze instance")
	check(not sim.blocked(sim.START) and sim.portals.is_empty() and not sim.can_dock(),"bonus instance has a free start, no portals and no harbor")
	sim.step(3.5)
	check(str(sim.bonus.state)=="fight" and sim.bonus_wave_alive()==3,"first wave spawns three ships")
	var hunters=true
	for body: Dictionary in sim.npcs:hunters=hunters and bool(body.hunter) and not sim.blocked(body.pos,20)
	check(hunters,"wave ships spawn on open water and hunt the captain")
	for body: Dictionary in sim.npcs:body.hp=0
	sim.step(0.1)
	check(int(sim.bonus.wave)==1 and str(sim.bonus.state)=="break" and int(sim.player.gold)>gold,"cleared wave pays and opens a short break")
	sim.step(4.5)
	check(sim.bonus_wave_alive()==5,"second wave raises the pressure")
	sim.player.hp=0;sim.player.respawn=0.1;sim.step(0.2)
	check(int(sim.player.hp)==int(sim.player.max_hp) and sim.in_bonus_map() and int(sim.bonus.wave)==1,"sinking retries inside the instance with progress kept")
	sim.player.last_hit=-100
	check(sim.leave_bonus() and not sim.in_bonus_map() and sim.map_id==0 and int(sim.bonus.wave)==1,"leaving keeps the wave checkpoint")
	var saved: Dictionary=JSON.parse_string(JSON.stringify(sim.export_save()))
	var restored=SIM.new()
	check(restored.restore_save(saved) and int(restored.bonus.wave)==1 and int(restored.bonus.tier)==0,"bonus checkpoint survives a save")
	sim.player.last_hit=-100
	check(sim.start_bonus(0) and sim.scrolls[0]==0 and int(sim.bonus.wave)==1,"resuming does not spend another scroll")
	for wave in range(1,CONTENT.BONUS_WAVES.size()):
		sim.step(4.5)
		check(sim.bonus_wave_alive()>0,"wave %d spawns" % (wave+1))
		var boss:=false
		for body: Dictionary in sim.npcs:
			boss=boss or (bool(body.get("boss",false)) and int(body.hp)>0)
			body.hp=0
		if wave>=3:check(boss,"wave %d brings its boss" % (wave+1))
		sim.step(0.1)
	check(str(sim.bonus.state)=="done" and sim.has_blessing() and sim.decks.size()==1,"final wave pays blessing, chest and a deck")
	saved=JSON.parse_string(JSON.stringify(sim.export_save()))
	check(int(saved.map_id)==0 and str(saved.bonus.done)=="true","saving inside the instance stores the origin region")
	sim.player.last_hit=-100
	check(sim.leave_bonus() and sim.bonus.is_empty() and sim.bonus_runs==1,"finished run closes after leaving")

	# Fortress towers and guilds.
	sim=SIM.new();sim.level=4;sim.configure_map(CONTENT.FORTRESS_MAP)
	var towers: Array=[]
	for body: Dictionary in sim.npcs:
		if body.kind=="tower":towers.append(body)
	check(towers.size()==4,"fortress carries four tower roles")
	var on_land=true
	for tower: Dictionary in towers:on_land=on_land and sim.on_land(tower.pos)
	check(on_land,"towers stand on the fortress island")
	sim.npcs.clear()
	for tower: Dictionary in towers:sim.npcs.append(tower)
	var cannon: Dictionary=towers[0]
	var water: Vector2=cannon.pos
	for angle in 24:
		var probe: Vector2=cannon.pos+Vector2.from_angle(TAU*angle/24.0)*300
		if not sim.blocked(probe):water=probe;break
	sim.player.pos=water
	sim.step(3.0)
	check(sim.player.last_hit>0 or not sim.shots.is_empty(),"towers open fire on a captain in range")
	cannon.shield=0
	sim._step_tower(cannon,1.0)
	check(float(cannon.shield)>0,"guardian tower recharges the other towers' shields")
	check(not sim.found_guild("Ab","XY") and not sim.found_guild("Tiefseewacht","X!") and not sim.found_guild("Tiefseewacht","KRF"),"guild founding validates name and tag")
	sim.player.gold=1000
	check(sim.found_guild("Tiefseewacht","tsw") and sim.guild.tag=="TSW" and int(sim.player.gold)==700,"local guild founding costs gold and stores the tag")
	sim.select(cannon.id);sim.player.reload=0
	for tower: Dictionary in towers:
		tower.hp=1;tower.shield=0
		sim._hit({"source":0,"damage":5,"weapon":"cannon"},tower)
	check(sim.fortress_conquests==1 and sim.guild_island_held() and sim.tower_kills==4,"destroying all towers conquers the guild island")
	sim.step(7.0)
	check(sim.towers_alive()==4 and sim.tower_friendly() and sim.tower_tag()=="TSW","towers return under the captain's guild tag")
	sim.select(cannon.id);sim.player.reload=0;sim.shots.clear();sim._fire_player()
	check(sim.shots.is_empty(),"guild towers cannot be attacked by their owner")
	check(sim.loot_gold(100)==110,"held guild island adds loot gold")
	sim.step(CONTENT.FORTRESS_HOLD)
	check(not sim.tower_friendly() and sim.tower_tag()==CONTENT.FORTRESS_TAG,"corsairs retake the fortress when the hold expires")

	# Save schema 3.
	sim=SIM.new();sim.essence=17;sim.fragments=4;sim.scrolls=[1,0,2];sim.kessel_meter=33;sim.free_flask_day="2026-11-04"
	sim.supplies.powder=7;sim.player.cannons=16;sim.grant_deck("hunter",2);sim.add_tide_deck(600);sim.activate_blessing(300)
	sim.player.gold=900;sim.found_guild("Tiefseewacht","TSW");sim.fortress_hold=100;sim.upgrades.war=5;sim.player.shield=321
	saved=JSON.parse_string(JSON.stringify(sim.export_save()))
	restored=SIM.new()
	check(int(saved.schema)==4 and restored.restore_save(saved),"schema 4 save is accepted")
	check(restored.essence==17 and restored.fragments==4 and restored.scrolls==[1,0,2] and restored.kessel_meter==33 and restored.free_flask_day=="2026-11-04","essence, fragments, scrolls and cauldron survive reload")
	check(int(restored.supplies.powder)==7 and int(restored.player.cannons)==16 and restored.owns_deck("hunter",2) and restored.deck_slots[0]==0,"supplies, cannons and decks survive reload")
	check(restored.has_blessing() and float(restored.buffs.tide_deck)>0 and restored.guild.tag=="TSW" and restored.guild_island_held(),"timed buffs and guild survive reload")
	check(int(restored.upgrades.war)==5 and int(restored.player.shield)==321,"castles and shield survive reload")
	var legacy={"schema":2,"gold":700,"ammo":[50,20,10],"skin":3,"upgrades":{"cannon":2,"harpoon":1,"hull":1,"sails":0},"level":5,"hp":1500}
	var fresh=SIM.new()
	check(fresh.restore_save(legacy) and int(fresh.upgrades.cannon)==2 and int(fresh.upgrades.hull)==1 and int(fresh.player.max_hp)==2800 and fresh.guild.is_empty() and fresh.decks.is_empty(),"legacy equipment maps onto castles with empty new systems")
	var sea=SIM.new()
	var patrol=sea.npcs[1]
	check(patrol.speed<sea.PLAYER_SPEED*0.4 and sea.player.ammo.size()==7,"patrols sail slower than the captain and special ammunition is stocked")
	sea._hit({"source":0,"damage":10,"weapon":"ice"},patrol)
	var held=patrol.pos
	sea._step_npc(patrol,0.5)
	check(float(patrol.ice)>2 and patrol.pos==held,"ice ammunition freezes the ship in place")
	sea._hit({"source":0,"damage":10,"weapon":"flare"},patrol)
	check(float(patrol.spotted)>sea.clock,"flare ammunition marks the target")
	sea._hit({"source":0,"damage":20,"weapon":"snow"},patrol)
	check(float(patrol.slow)>7 and is_equal_approx(float(patrol.slow_rate),0.38),"snow ammunition slows harder than chain shot")
	var pumpkin_before=int(sea.npcs[2].hp)+int(sea.npcs[2].shield)
	patrol.pos=sea.npcs[2].pos
	sea._hit({"source":0,"damage":100,"weapon":"pumpkin"},patrol)
	check(int(sea.npcs[2].hp)+int(sea.npcs[2].shield)<pumpkin_before,"pumpkin ammunition splashes a nearby ship, taking shields before hull")
	_staff_checks()
	var result={"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
