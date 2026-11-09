extends SceneTree
const SIM=preload("res://simulation.gd")
const MARKS=preload("res://sea_marks.gd")
const CONTENT=preload("res://content.gd")
var checks:=0
var failures: Array[String]=[]
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures.append(label)
func _initialize() -> void:
	var sim=SIM.new()
	check(CONTENT.DECK_KEYS==["cannon"] and CONTENT.DECK_TIERS==["Gold","Perlen","Kristall"] and CONTENT.DECK_STAGE_MAX==5,"one ordinary deck type with five levels in three materials")
	check(sim.deck_slots.size()==10 and sim.deck_slots.count(-1)==10,"exactly ten independent physical slots")
	sim.player.pos=sim.harbor
	sim.dock()
	sim.player.gold=200000
	sim.essence=300
	for slot in 10:
		var wallet: int=int(sim.player.gold)
		check(sim.buy_deck("cannon") and int(sim.deck_slots[slot])==slot and int(sim.player.gold)==wallet-600,"identical Gold I deck purchased and auto-mounted "+str(slot))
	check(sim.decks.size()==10 and sim.decks.all(func(d):return d.type=="cannon" and d.tier==0 and d.stage==1),"ten duplicate Gold I copies coexist, no essence conversion")
	check(sim.cannon_slots()==20 and sim.equipped_cannons()==10,"ten Gold I decks grant provisional slots but not free cannons")
	var entries=MARKS.deck_entries(sim)
	check(entries.size()==10 and entries.all(func(e):return e.lit and e.color==CONTENT.DECK_TIER_COLORS[0]),"all ten deck cells are golden")
	check(sim.equip_deck(0,9) and sim.deck_slots[0]==-1 and sim.deck_slots[9]==0,"moving a physical deck preserves uniqueness")
	check(sim.unequip_deck(9) and sim.deck_slots[9]==-1,"removing a deck frees a slot")
	check(sim.equip_deck(9,9) and sim.equip_deck(0,0),"mixed deck copies remount in both rows")
	var info: Dictionary=sim.deck_upgrade_info(0)
	check(info.stage==1 and info.next_tier==0 and info.next_stage==2 and info.cannons_next>info.cannons_now,"next upgrade always reports current and next stage plus cannon gain")
	var wallet: int=int(sim.player.gold)
	check(sim.upgrade_deck(0) and sim.decks[0].tier==0 and sim.decks[0].stage==2 and int(sim.player.gold)==wallet-180,"first Gold I→II upgrade debits the displayed cost once")
	for _step in 3:check(sim.upgrade_deck(0),"Gold deck advances through levels III-V")
	check(sim.decks[0].tier==0 and sim.decks[0].stage==5,"fifth Gold level holds material until promotion")
	info=sim.deck_upgrade_info(0)
	check(info.promoting and info.next_tier==1 and info.next_stage==1 and info.cannons_next>info.cannons_now,"Gold V explicitly previews Pearl I with positive cannon gain")
	wallet=int(sim.player.gold)
	check(not sim.upgrade_deck(0) and int(sim.player.gold)==wallet,"Pearl rank gate cannot spend currency")
	sim.level=3
	check(sim.upgrade_deck(0) and sim.decks[0].tier==1 and sim.decks[0].stage==1,"Gold V promotes to Pearl I")
	check(MARKS.deck_entries(sim)[0].color==CONTENT.DECK_TIER_COLORS[1],"Pearl material changes ship-deck color")
	for _step in 4:check(sim.upgrade_deck(0),"Pearl deck advances to fifth stage")
	info=sim.deck_upgrade_info(0)
	check(info.promoting and info.next_tier==2 and info.next_stage==1 and info.cannons_next>info.cannons_now,"Pearl V previews Crystal I")
	wallet=int(sim.player.gold)
	check(not sim.upgrade_deck(0) and int(sim.player.gold)==wallet,"Crystal level gate preserves funds")
	sim.level=8
	check(sim.upgrade_deck(0) and sim.decks[0].tier==2 and sim.decks[0].stage==1,"Pearl V promotes to Crystal I")
	for _step in 4:check(sim.upgrade_deck(0),"Crystal deck progresses to fifth and final stage")
	info=sim.deck_upgrade_info(0)
	check(info.maximum and sim.decks[0].tier==2 and sim.decks[0].stage==5,"Crystal V is maximum")
	wallet=int(sim.player.gold)
	check(not sim.upgrade_deck(0) and int(sim.player.gold)==wallet,"maximum level never charges")
	for _step in 4:sim.upgrade_deck(1)
	sim.upgrade_deck(1)
	check(sim.decks[1].tier==1 and sim.decks[1].stage==1,"second physical deck upgrades independently")
	entries=MARKS.deck_entries(sim)
	check(entries[0].color==CONTENT.DECK_TIER_COLORS[2] and entries[1].color==CONTENT.DECK_TIER_COLORS[1] and entries[2].color==CONTENT.DECK_TIER_COLORS[0],"Crystal, Pearl and Gold copies may occupy the same ten-slot ship")
	var total: int=0
	for index in sim.deck_slots:
		if int(index)>=0:total+=sim.deck_cannon_bonus(int(sim.decks[index].tier),int(sim.decks[index].stage))
	check(sim.cannon_slots()==sim.BASE_CANNON_SLOTS+total,"cannon capacities sum across all ten independent upgrades")
	sim.depart()
	check(not sim.buy_deck("cannon") and not sim.upgrade_deck(2) and not sim.equip_deck(0,1),"standard deck purchase/upgrade/mount requires harbor")
	var cells=MARKS.deck_cells(Vector2.ZERO,6.3)
	check(cells.size()==10 and cells[0].y==cells[4].y and cells[5].y==cells[9].y and cells[0].y<cells[5].y,"ten visible gems still form two rows of five")
	# The three side decks never consume or replace physical standard slots.
	var old_slots=sim.deck_slots.duplicate()
	sim.add_tide_deck(1200)
	sim.add_special_deck("storm_deck",600)
	sim.add_special_deck("salvage_deck",900)
	check(sim.deck_slots==old_slots and sim.buffs.tide_deck==1200 and sim.buffs.storm_deck==600 and sim.buffs.salvage_deck==900,"three independent side-deck timers preserve the ten normal slots")
	var saved=JSON.parse_string(JSON.stringify(sim.export_save()))
	var restored=SIM.new()
	check(saved.schema==8 and restored.restore_save(saved),"save schema remains backward-compatible")
	check(restored.decks==sim.decks and restored.deck_slots==sim.deck_slots,"material and five-stage progression survive signed pack/restart")
	check(restored.buffs.tide_deck==1200 and restored.buffs.storm_deck==600 and restored.buffs.salvage_deck==900,"three special timers survive reload")
	# Legacy copies must remain owned, not silently sold or deduplicated.
	var legacy={"schema":3,"gold":774,"ammo":[29,111,151],"level":5,"decks":[{"type":"armor","tier":0},{"type":"hunter","tier":1},{"type":"cannon","tier":2}],"deck_slots":[0,1,2],"buffs":{"tide_deck":450}}
	var migrated=SIM.new()
	check(migrated.restore_save(legacy) and migrated.deck_slots[0]==0 and migrated.deck_slots[1]==1 and migrated.deck_slots[2]==2,"legacy physical positions and materials retained")
	check(migrated.decks.size()==3 and migrated.decks.all(func(d):return d.type=="cannon" and d.stage==1),"old specialized copies become identical normal decks, preserving quantity")
	check(migrated.player.gold==774 and migrated.buffs.tide_deck==450,"wallet and tide bonus survive migration")
	legacy.deck_slots=[0,0,1,99,-4,1]
	check(migrated.restore_save(legacy) and migrated.deck_slots.count(0)==1 and migrated.deck_slots.count(1)==1,"invalid duplicate slot references rejected")
	var special=SIM.new()
	special.player.pos=special.harbor
	special.dock()
	special.level=3
	special.player.gold=2000
	check(not special.buy_special_deck("storm_deck"),"Runendeck cannot be bought; Kessel-only")
	special._grant("storm_deck",1800,"Runendeck",2)
	check(special.buffs.storm_deck==1800,"Kessel reward activates real Runendeck effect")
	check(is_equal_approx(float(special.player.speed),special.PLAYER_SPEED*1.12),"Runendeck truly modifies speed")
	check(special.buy_special_deck("salvage_deck") and special.player.gold==1100 and special.buffs.salvage_deck==1800,"Korsarendeck has separate real 30-minute effect")
	check(special.loot_gold(100)==115,"Korsarendeck changes loot gold")
	special.buffs.storm_deck=1
	special.buffs.salvage_deck=1
	special.depart()
	special.step(2)
	check(special.buffs.storm_deck==0 and special.buffs.salvage_deck==0 and is_equal_approx(float(special.player.speed),special.PLAYER_SPEED) and special.loot_gold(100)==100,"independent side decks expire cleanly")
	check(not special.add_special_deck("invented",60),"unknown side decks cannot be granted")
	# Opt-in, atomic one-step upgrade of ONLY the mounted standard decks.
	var fleet=SIM.new()
	fleet.player.pos=fleet.harbor
	fleet.dock()
	fleet.player.gold=9000
	for i in 3:check(fleet.buy_deck("cannon"),"set up mounted Gold deck for bundle test "+str(i))
	var preview: Dictionary=fleet.deck_fleet_upgrade_preview()
	check(preview.count==3 and preview.gold==540 and preview.essence==0 and preview.cannon_gain==3 and preview.can_upgrade,"preview sums three independent Gold I→II upgrades exactly")
	fleet.player.gold=539
	check(not fleet.upgrade_mounted_decks() and fleet.decks.all(func(d):return d.stage==1) and fleet.player.gold==539,"short gold fails the entire upgrade bundle without partial charges")
	fleet.player.gold=9000
	check(fleet.upgrade_mounted_decks() and fleet.decks.all(func(d):return d.stage==2) and fleet.player.gold==8460,"all mounted copies advance exactly one stage with one atomic debit")
	fleet.decks[0].stage=5
	fleet.player.gold=9000
	fleet.essence=0
	preview=fleet.deck_fleet_upgrade_preview()
	check(preview.count==3 and preview.captain_level==3 and preview.essence==2 and not preview.can_upgrade,"material promotion reports captain-level gate before debit")
	check(not fleet.upgrade_mounted_decks() and fleet.decks[0].tier==0 and fleet.decks[0].stage==5,"batch upgrade cannot bypass captain level")
	fleet.level=3
	preview=fleet.deck_fleet_upgrade_preview()
	check(not preview.can_upgrade and preview.reason.contains("Essenz"),"material promotion checks full bundle essence")
	fleet.essence=2
	preview=fleet.deck_fleet_upgrade_preview()
	var before_gold: int=int(fleet.player.gold)
	check(preview.can_upgrade and fleet.upgrade_mounted_decks(),"mixed deck ranks can be upgraded together when total cost and level are met")
	check(fleet.decks[0].tier==1 and fleet.decks[0].stage==1 and fleet.decks[1].stage==3 and fleet.decks[2].stage==3,"Gold V promotes to Pearl I while Gold II copies independently advance to III")
	check(int(fleet.player.gold)==before_gold-int(preview.gold) and fleet.essence==0,"mixed fleet upgrade charges the exact previewed sum once")
	check(fleet.unequip_deck(2),"unequip a standard deck for exclusion from bundle")
	preview=fleet.deck_fleet_upgrade_preview()
	check(preview.count==2 and not 2 in preview.targets and fleet.decks[2].stage==3,"warehouse-only decks never enter a mounted-only bulk upgrade")
	var fleet_saved: Dictionary=JSON.parse_string(JSON.stringify(fleet.export_save()))
	var fleet_loaded=SIM.new()
	check(fleet_loaded.restore_save(fleet_saved) and fleet_loaded.decks==fleet.decks and fleet_loaded.deck_slots==fleet.deck_slots,"batch upgraded individual copies persist across save reload")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
