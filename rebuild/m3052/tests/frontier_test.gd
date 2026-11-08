extends SceneTree
const SIM=preload("res://simulation.gd")
const CONTENT=preload("res://content.gd")
const LEDGER=preload("res://reward_ledger.gd")
var failures: Array[String]=[]
var count:=0
func check(value: bool,label: String) -> void:
	count+=1
	if not value:failures.append(label)
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var s=SIM.new();s.level=20
	check(CONTENT.SEA_MAP_IDS.size()==40,"exactly forty standard maps")
	var codes: Array[String]=[]
	for tier in range(1,21):
		for lane in [1,2]:
			var index: int=CONTENT.sea_index(tier,lane)
			s.configure_map(index)
			var map: Dictionary=CONTENT.MAPS[index]
			check(map.code=="%d/%d" % [tier,lane],"unique ordered code "+str(map.code));codes.append(map.code)
			check(s.has_harbor() and not s.plan_path(s.START,s.harbor).is_empty(),"reachable harbor "+str(map.code))
			check(s.portals.size()==CONTENT.sea_neighbors(index).size(),"real exits for "+str(map.code))
			for exit: Dictionary in s.portals:
				check(index in CONTENT.sea_neighbors(int(exit.destination)),"bidirectional exit "+str(map.code))
				check(not s.plan_path(s.START,exit.pos).is_empty(),"coast-safe portal "+str(map.code))
			if CONTENT.has_guild_island(index):
				var towers: Array=s.npcs.filter(func(npc):return npc.kind=="tower")
				check(towers.size()==12,"twelve modular towers "+str(map.code))
				check(s.fortress_island().width>900,"purpose-built larger fortress footprint "+str(map.code))
				var fortress: Dictionary=s.fortress_island()
				var basin: Vector2=fortress.bounds.position+fortress.bounds.size*Vector2(.5,.72)
				var mouth: Vector2=fortress.bounds.position+fortress.bounds.size*Vector2(.5,.96)
				check(not s.on_land(basin) and not s.blocked(basin,15),"guild inner harbor navigable "+str(map.code))
				check(not s.on_land(mouth) and not s.blocked(mouth,15),"guild entrance open to sea "+str(map.code))
				for tower: Dictionary in towers:
					check(s.on_land(tower.pos),"tower stands on enlarged land "+str(tower.id))
					for other: Dictionary in towers:
						if int(tower.id)<int(other.id):check(tower.pos.distance_to(other.pos)>80,"distinct usable tower positions %s/%s on %s" % [tower.id,other.id,map.code])
	for origin: int in CONTENT.SEA_MAP_IDS:
		var at: int=origin
		for _step in 42:
			if at==CONTENT.sea_index(20,2):break
			at=CONTENT.next_sea_on_route(at,CONTENT.sea_index(20,2))
		check(at==CONTENT.sea_index(20,2),"all maps route to 20/2 from "+str(origin))
	check(CONTENT.MAPS[3].get("bonus",false) and CONTENT.MAPS[4].get("bonus",false) and CONTENT.MAPS[5].get("bonus",false),"bonus ids preserved")
	s.configure_map(CONTENT.sea_index(20,2));s.captain_name="Broosskyy";s.battle_points=0;s.player.pos=s.START
	var save: Dictionary=s.export_save();var restored=SIM.new()
	check(restored.restore_save(JSON.parse_string(JSON.stringify(save))) and restored.map_id==s.map_id and restored.captain_name=="Broosskyy","schema six preserves new seas and player identity")
	s.scrolls[0]=1;s.player.last_hit=-100;s.docked=false
	check(s.start_bonus(0) and s.map_id==3,"bonus can start from 20/2")
	check(s.leave_bonus() and s.map_id==CONTENT.sea_index(20,2),"bonus returns to exact expanded sea")
	# Effects, cooldowns, stock and expiration are actual simulation behavior.
	s=SIM.new();s.player.pos=Vector2(500,500);s.player.path=[Vector2(900,500)]
	for key: String in CONTENT.SUPPLY_KEYS:s.supplies[key]=2
	check(s.use_supply("wind_draught"),"wind item activates")
	var before: Vector2=s.player.pos;s._move(s.player,1)
	check(is_equal_approx(s.player.pos.distance_to(before),float(s.player.speed)*1.25),"wind item changes movement")
	check(not s.use_supply("wind_draught") and s.supplies.wind_draught==1,"cooldown rejects repeated consumption")
	s._tick_timers(21);check(s.buffs.wind_draught==0,"wind expires in sea time")
	s.player.slow=4;check(s.use_supply("cleansing_rum") and s.player.slow==0,"rum removes a real slow")
	check(s.use_supply("salvage_charm") and s.loot_gold(100)==120,"salvage item modifies actual loot")
	s.player.shield=0;s.player.hp=1000
	check(s.use_supply("smoke_bomb"),"smoke item activates from inventory")
	s._hit({"source":int(s.npcs[0].id),"weapon":"cannon","damage":100},s.player)
	check(int(s.player.hp)==930,"smoke reduces an actual incoming impact by thirty percent")
	s.configure_map(2);s.player.gold=10000;s.found_guild("Tiefseewacht","TSW");s.fortress_hold=100
	var turret: Dictionary=s.npcs.filter(func(npc):return npc.kind=="tower")[0]
	var turret_face: Vector2=s._projectile_target(turret)
	check(turret_face.y<float(turret.pos.y)-40,"shells target masonry above the tower footprint")
	s._hit({"source":0,"id":916,"weapon":"cannon","damage":40},turret)
	check(not s.events.is_empty() and bool(s.events.back().get("structure",false)) and Vector2(s.events.back().pos)==turret_face,"tower hits emit masonry impact with exact visual target")
	check(s.upgrade_guild_tower(0) and s.tower_levels[0]==2,"owner can upgrade a tower")
	var hp: int=0
	for npc in s.npcs:
		if int(npc.id)==400:hp=int(npc.max_hp)
	check(hp>int(CONTENT.TOWERS[0].hp),"tower upgrade raises actual combat HP")
	s.configure_map(CONTENT.sea_index(4,2));check(not s.tower_friendly(),"ownership never leaks into another guild island")
	check(not s.upgrade_guild_tower(0),"another held island cannot authorize enemy upgrades")
	s.configure_map(2);check(s.tower_levels[0]==2 and s.tower_friendly(),"return restores that island's upgrade and owner")
	# Legacy four-tower saves preserve each old role and append six level-one slots.
	var legacy: Dictionary=s.export_save()
	legacy.guild_holdings["2"].levels=[2,3,4,5]
	var migrated=SIM.new();check(migrated.restore_save(legacy),"four-tower guest save loads")
	check(migrated.tower_levels==[2,3,4,5,1,1,1,1,1,1,1,1],"four old upgrades retained with eight new slots")
	migrated.player.gold=999999
	check(migrated.upgrade_guild_tower(11) and migrated.tower_levels[11]==2,"twelfth tower has independent upgrade")
	var full=SIM.new();check(full.restore_save(JSON.parse_string(JSON.stringify(migrated.export_save()))) and full.tower_levels==migrated.tower_levels,"all twelve upgrades survive JSON save reload")
	check(not full.upgrade_guild_tower(12),"tower index beyond twelve is rejected")
	var piece_test=SIM.new()
	piece_test.fragments=5
	check(piece_test.assign_bonus_piece(0) and piece_test.bonus_pieces[0]==1 and piece_test.fragments==4,"map segment assignment consumes only one collected fragment")
	check(piece_test.restore_save(JSON.parse_string(JSON.stringify(piece_test.export_save()))) and piece_test.bonus_pieces[0]==1,"assigned bonus segments survive save reload")
	check(piece_test.craft_scroll(0) and piece_test.scrolls[0]==1 and piece_test.fragments==0 and piece_test.bonus_pieces[0]==0,"mixed existing and allocated map pieces craft scroll exactly once")
	var ledger=LEDGER.new();ledger.restore({"last_seen":100000,"high_water":100000},200000)
	check(ledger.pending_seconds==28800,"AFK cap is eight hours")
	var wallet: int=s.player.gold
	check(ledger.claim_afk(s) and not ledger.claim_afk(s) and s.player.gold-wallet==1440,"AFK claim grants exactly once")
	check(ledger.claim_daily(s,200000) and not ledger.claim_daily(s,200000),"daily claim grants once per UTC day")
	check(not ledger.daily_available(100000),"clock rollback cannot reopen daily rewards")
	var next=LEDGER.new();next.restore(ledger.snapshot(200000),200000)
	check(not next.claim_daily(s,200000) and next.pending_seconds==0,"reopening preserves claimed rewards")
	check(next.claim_daily(s,286400) and next.streak==2,"next consecutive day advances streak")
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);await process_frame
	for dimensions in [Vector2i(844,390),Vector2i(2340,1080),Vector2i(1080,2340)]:
		root.size=dimensions;await process_frame
		game._open_modal("Verbrauch");await process_frame
		check(game.supply_selector.visible and game.supply_buttons.values().all(func(button):return not button.visible),"one separate consumable selector at "+str(dimensions))
		check(game.modal_body.find_children("Use_*","Button",true,false).size()==11,"all eleven functional items in picker")
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(game.modal.get_global_rect()),"consumables fit viewport "+str(dimensions))
		game._open_modal("Seekarten");await process_frame
		check(game.modal_body.find_child("WorldChart",true,false)!=null,"forty-map chart opens")
		var chart=game.modal_body.find_child("WorldChart",true,false)
		check(game.target_clear.z_index>game.target_numbers.z_index,"target cancel button owns the top drawing layer")
		chart.chapter=-1
		check(chart.visible_nodes()==CONTENT.SEA_MAP_IDS,"complete world atlas exposes forty maps without changing pages")
		for index: int in CONTENT.SEA_MAP_IDS:
			check(chart.node_at(chart.node_point(index))==index,"overview tap hitbox "+str(index))
		var catalog: Array=[]
		for chapter in 4:
			chart.chapter=chapter
			for index: int in chart.visible_nodes():
				check(chart.node_at(chart.node_point(index))==index,"illustrated atlas hitbox "+str(index))
				if index in CONTENT.SEA_MAP_IDS:catalog.append(index)
		check(catalog.size()==40 and catalog==CONTENT.SEA_MAP_IDS,"four illustrated leaves expose all forty seas in order")
		for tab in ["GRAFIK","STEUERUNG","HUD","EFFEKTE"]:
			game.modal_tab["Anzeige"]=tab;game._open_modal("Anzeige");await process_frame
			check(game.modal_tabs.get_child_count()==4 and game.modal_scroll.size.y>80,"categorized settings "+tab+" at "+str(dimensions))
	root.size=Vector2i(2340,1080);await process_frame
	game._open_modal("Werft");await process_frame
	var list=game.modal_scroll
	list.pending=-1;list.velocity=0;list.scroll_vertical=100
	var point: Vector2=list.get_global_rect().get_center()
	var down=InputEventScreenTouch.new();down.index=5;down.pressed=true;down.position=point
	list._input(down)
	var other=InputEventScreenTouch.new();other.index=6;other.pressed=true;other.position=point
	list._input(other)
	other.pressed=false;list._input(other)
	check(list.pressing and list.active_touch==5,"second finger cannot release or steal a scrolling gesture")
	var before_scroll: int=list.scroll_vertical
	var drag=InputEventScreenDrag.new();drag.index=5;drag.position=point-Vector2(0,120)
	list._input(drag)
	var expected: float=120.0/list.get_global_transform().get_scale().y-list.SLOP
	check(absf(float(list.scroll_vertical-before_scroll)-expected)<2,"scaled finger movement maps to local scroll coordinates")
	down.pressed=false;down.canceled=true;list._input(down)
	check(not list.pressing and list.active_touch==-1 and list.velocity==0,"canceled touch clears scrolling ownership and glide")
	game.queue_free();await process_frame
	var hub=load("res://start_hub.tscn").instantiate();root.add_child(hub);await process_frame
	for dimensions in [Vector2i(844,390),Vector2i(2340,1080),Vector2i(1080,2340)]:
		root.size=dimensions;await process_frame
		for page in ["welcome","auth","home","rewards","profile","maps","guild","settings"]:
			hub._show(page);await process_frame
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(hub.panel.get_global_rect()),"front door fits "+page+" at "+str(dimensions))
			check(hub.scroll.size.y>140,"front door content scrolls "+page)
			if dimensions.x>=1080 and page=="home":
				check(hub.body.get_node("SailButton").get_global_rect().size.y>=72,"main action stays readable on high-resolution phones")
	hub.queue_free();await process_frame
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
