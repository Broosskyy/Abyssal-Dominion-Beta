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
	check(sim.deck_slots.size()==10 and sim.deck_slots.count(-1)==10,"ten real empty deck slots, without free ownership")
	sim.player.pos=sim.harbor;sim.dock();sim.player.gold=20000
	for slot in 10:
		var gold=int(sim.player.gold)
		check(sim.buy_deck("cannon") and int(sim.deck_slots[slot])==slot and int(sim.player.gold)==gold-600,"gold deck purchased and mounted exactly once: %d" % slot)
	check(sim.cannon_slots()==50 and sim.equipped_cannons()==10,"ten cannon decks add slots but do not grant free cannons")
	var entries=MARKS.deck_entries(sim)
	check(entries.size()==10 and entries.all(func(e):return e.lit and e.color==CONTENT.DECK_TIER_COLORS[0]),"all ten gold decks use the gold material colour")
	check(sim.equip_deck(0,9) and sim.deck_slots[0]==-1 and sim.deck_slots[9]==0 and sim.deck_slots.count(0)==1,"moving one physical deck cannot duplicate it")
	check(sim.unequip_deck(9) and sim.deck_slots[9]==-1,"unmounting frees a real slot")
	check(sim.equip_deck(9,9) and sim.equip_deck(0,0),"stored decks remount in both rows")
	var wallet=int(sim.player.gold)
	check(not sim.upgrade_deck(0) and int(sim.player.gold)==wallet and sim.decks[0].tier==0,"elite level gate preserves gold and deck")
	sim.level=3
	check(sim.upgrade_deck(0) and sim.decks[0].tier==1 and int(sim.player.gold)==wallet-900,"gold improves to elite with a real purchase")
	check(MARKS.deck_entries(sim)[0].color==CONTENT.DECK_TIER_COLORS[1],"elite deck is blue")
	wallet=int(sim.player.gold);sim.essence=20
	check(not sim.upgrade_deck(0) and int(sim.player.gold)==wallet and sim.essence==20,"crystal progression is gated for later")
	sim.level=8
	check(sim.upgrade_deck(0) and sim.decks[0].tier==2 and int(sim.player.gold)==wallet-1800 and sim.essence==14,"elite improves to crystal and consumes the stated currencies")
	check(MARKS.deck_entries(sim)[0].color==CONTENT.DECK_TIER_COLORS[2],"crystal deck is purple")
	wallet=int(sim.player.gold)
	check(not sim.upgrade_deck(0) and int(sim.player.gold)==wallet,"crystal is the final deck material")
	sim.depart()
	check(not sim.buy_deck("armor") and not sim.upgrade_deck(1) and not sim.equip_deck(0,1),"deck rebuilding still requires docking")
	var cells=MARKS.deck_cells(Vector2.ZERO,6.3)
	check(cells.size()==10 and cells[0].y==cells[4].y and cells[5].y==cells[9].y and cells[0].y<cells[5].y,"ten icons form exactly two five-slot rows")
	for column in 5:check(cells[column].x==cells[column+5].x,"aligned deck columns %d" % column)
	# Save the new ten-slot system with mixed materials and real timed decks.
	sim.add_special_deck("storm_deck",600);sim.add_special_deck("salvage_deck",900);sim.add_tide_deck(1200)
	var saved=JSON.parse_string(JSON.stringify(sim.export_save()))
	var restored=SIM.new()
	check(saved.schema==7 and restored.restore_save(saved),"ten-slot save and selected ship schema 7 round-trip")
	check(restored.decks==sim.decks and restored.deck_slots==sim.deck_slots,"all ten individual decks and their materials survive reload")
	check(restored.buffs.storm_deck==600 and restored.buffs.salvage_deck==900 and restored.buffs.tide_deck==1200,"surrounding special-deck timers survive reload")
	# Existing data-50 saves keep their first two slots, material indices and wallet.
	var legacy={"schema":3,"gold":774,"ammo":[29,111,151],"level":5,"decks":[{"type":"cannon","tier":0},{"type":"armor","tier":1}],"deck_slots":[0,1],"buffs":{"tide_deck":450}}
	var migrated=SIM.new()
	check(migrated.restore_save(legacy) and migrated.deck_slots.size()==10 and migrated.deck_slots[0]==0 and migrated.deck_slots[1]==1 and migrated.deck_slots.count(-1)==8,"two-slot saves migrate without inventing eight owned decks")
	check(migrated.player.gold==774 and migrated.decks.size()==2 and migrated.buffs.tide_deck==450,"migration preserves wallet, inventory and tide time")
	check(migrated.cannon_slots()==24 and int(migrated.player.max_hp)==roundi(migrated.PLAYER_HP*1.15),"migration preserves the original equipment effects")
	legacy.deck_slots=[0,0,1,99,-4,1]
	check(migrated.restore_save(legacy) and migrated.deck_slots.count(0)==1 and migrated.deck_slots.count(1)==1 and migrated.deck_slots[3]==-1,"invalid or duplicated physical deck references are rejected")
	# Specials have actual effects and expiration; they are not decorative ownership.
	var special=SIM.new();special.npcs.clear();special.player.gold=2000
	check(not special.buy_special_deck("storm_deck") and special.player.gold==2000,"special-deck purchase requires the harbor")
	special.player.pos=special.harbor;special.dock()
	check(not special.buy_special_deck("storm_deck") and special.player.gold==2000,"special-deck level gate preserves funds")
	special.level=3
	check(special.buy_special_deck("storm_deck") and special.player.gold==1100 and special.buffs.storm_deck==1800,"storm deck is purchased with a real timer")
	check(is_equal_approx(float(special.player.speed),special.PLAYER_SPEED*1.12),"storm deck changes sailing speed")
	special.buffs.storm_deck=1;special.add_special_deck("salvage_deck",1)
	check(special.loot_gold(100)==115,"salvage deck changes real loot rewards")
	special.depart();special.step(2)
	check(special.buffs.storm_deck==0 and special.buffs.salvage_deck==0 and is_equal_approx(float(special.player.speed),special.PLAYER_SPEED) and special.loot_gold(100)==100,"special decks expire back to the original effects")
	check(not special.add_special_deck("invented",60),"unknown special decks cannot grant effects")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
