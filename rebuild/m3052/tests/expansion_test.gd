extends SceneTree
const SIM=preload("res://simulation.gd")
const EXTRA=preload("res://sea_expansion.gd")
var checks:=0
var failures: Array[String]=[]
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var s=SIM.new()
	check(s.npcs.filter(func(a):return a.kind=="monster").size()==4,"Tiamat and three distinct harpoon monsters coexist")
	for actor in s.npcs:
		if actor.kind=="monster":check(not s.blocked(actor.pos),"monster begins in water")
	var victim: Dictionary=s.npcs[0];victim.pos=Vector2(650,500);s.player.pos=Vector2(500,500)
	s.target=-1;var stock: int=s.supplies.skyfire
	check(not s.use_supply("skyfire") and s.supplies.skyfire==stock,"invalid rocket use consumes no stock")
	s.select(victim.id)
	check(s.use_supply("skyfire") and s.shots.back().weapon=="explosive" and s.supplies.skyfire==stock-1,"quick rocket is a real targeted projectile")
	check(not s.use_supply("skyfire"),"rocket cooldown prevents repeated use")
	s.player.hp=1000;s.player.shield=0
	check(s.use_supply("healing_amulet") and s.player.hp==1600,"amulet restores exactly twenty-five percent")
	check(s.use_supply("blessing_flask") and s.has_blessing() and s.player.hp==2560,"blessing restores health and grants real timed effect")
	s.powder_on=true;s.player.reload=0;s.ammo_mode=0;s._fire_player()
	check(s.shots.back().get("powder",false) and s.shots.back().damage>s.weapon_damage(0),"powder damage bonus travels with real projectile")
	s.plates_on=true;s.player.hp=2000;s.player.shield=0
	s._hit({"source":victim.id,"damage":100,"weapon":"cannon"},s.player)
	check(s.player.hp==1935 and s.events.back().get("plates",false),"armor reduces actual incoming hit by thirty-five percent and marks feedback")
	var save: Dictionary=s.export_save();var restored=SIM.new();restored.restore_save(save)
	check(restored.cooldowns.skyfire>0,"special-item cooldown survives save/restart")
	EXTRA.set_event(s,"halloween");var pickup: Dictionary=s.event_pickups[0];s.player.pos=pickup.pos
	var tokens: int=s.event_tokens.halloween;stock=s.supplies.skyfire
	EXTRA.collect(s,.1);EXTRA.collect(s,.1)
	check(s.event_tokens.halloween==tokens+1 and s.supplies.skyfire==stock+1,"pumpkin pays once before respawn")
	EXTRA.set_event(s,"columbus");s.player.pos=s.event_pickups[0].pos;EXTRA.collect(s,.1)
	check(s.event_tokens.columbus==1,"Columbus has distinct collectible currency")
	s.player.skin=13;restored=SIM.new();restored.restore_save(s.export_save())
	check(restored.player.skin==13 and restored.event_tokens.columbus==1 and restored.event_mode=="columbus","event paint and currencies persist")
	EXTRA.set_event(s,"off");check(s.event_pickups.is_empty(),"turning event off removes its collectible layer")
	var hunter=SIM.new()
	var hunt_actor: Dictionary=EXTRA.event_target(hunter)
	check(not hunt_actor.is_empty() and hunter.npcs.size()==SIM.new().npcs.size(),"event hunt reuses exactly one existing ship without growing the fleet")
	var original_name: String=str(hunt_actor.event_base_name)
	hunt_actor.hp-=37;var injured: int=int(hunt_actor.hp)
	EXTRA.set_event(hunter,"columbus")
	check(int(hunt_actor.hp)==injured and str(hunt_actor.event_key)=="columbus","changing events never heals a live target")
	EXTRA.set_event(hunter,"halloween")
	var hunt_tokens: int=int(hunter.event_tokens.halloween)
	var token_reward: int=EXTRA.hunt_token_reward(hunter)
	hunter._hit({"source":0,"damage":1000000,"weapon":"cannon"},hunt_actor)
	check(int(hunter.event_tokens.halloween)==hunt_tokens+token_reward,"real event kill pays the declared extra token reward")
	hunter._hit({"source":0,"damage":1000000,"weapon":"cannon"},hunt_actor)
	check(int(hunter.event_tokens.halloween)==hunt_tokens+token_reward,"a dead event target cannot pay twice")
	EXTRA.set_event(hunter,"columbus")
	check(int(hunt_actor.hp)==0 and float(hunt_actor.respawn)>0,"event switching cannot resurrect a sunk target")
	hunter._step_npc(hunt_actor,49.0)
	check(int(hunt_actor.hp)==int(hunt_actor.max_hp) and str(hunt_actor.event_key)=="columbus","ordinary respawn preserves the current event hunt")
	hunter.event_tokens.columbus=4
	var trade_stock: int=int(hunter.player.ammo[0])
	check(EXTRA.trade(hunter,"voyage_ammo") and hunter.event_tokens.columbus==0 and int(hunter.player.ammo[0])==trade_stock+25,"event trade debits exact tokens and adds exact ammunition")
	check(not EXTRA.trade(hunter,"voyage_ammo") and int(hunter.player.ammo[0])==trade_stock+25,"insufficient tokens cannot buy twice")
	hunter.event_tokens.halloween=8
	check(not EXTRA.trade(hunter,"pumpkin_ammo") and hunter.event_tokens.halloween==8,"inactive event currency cannot be spent through the wrong offer")
	var hunt_restored=SIM.new()
	check(hunt_restored.restore_save(JSON.parse_string(JSON.stringify(hunter.export_save()))) and hunt_restored.event_tokens.halloween==8 and hunt_restored.event_tokens.columbus==0,"event currency spending survives JSON save and reload")
	EXTRA.set_event(hunter,"off")
	check(EXTRA.event_target(hunter).is_empty() and str(hunt_actor.name)==original_name,"turning events off removes hunt markers and restores patrol names")
	EXTRA.set_event(hunter,"halloween");hunt_actor.hp=1;hunt_actor.shield=0;hunt_actor["staff_spawn"]=true
	hunt_tokens=int(hunter.event_tokens.halloween)
	hunter._hit({"source":0,"damage":1000000,"weapon":"cannon"},hunt_actor)
	check(int(hunter.event_tokens.halloween)==hunt_tokens,"staff-spawned kills cannot pay event tokens")
	var cached_hunt=SIM.new()
	var cached_actor: Dictionary=EXTRA.event_target(cached_hunt)
	cached_actor.hp=17
	cached_hunt.map_states[0]={"npcs":cached_hunt.npcs.duplicate(true),"drops":cached_hunt.drops.duplicate(true)}
	EXTRA.set_event(cached_hunt,"columbus")
	cached_hunt.configure_map(1);cached_hunt.configure_map(0)
	check(int(EXTRA.event_target(cached_hunt).hp)==17 and str(EXTRA.event_target(cached_hunt).event_key)=="columbus","cached map adopts current event without healing its previous patrol")
	check(cached_hunt.npcs.filter(func(actor):return str(actor.get("event_key",""))=="columbus").size()==1,"returning to a map never duplicates event targets")
	var entry_reward: int=EXTRA.hunt_token_reward(cached_hunt)
	cached_hunt.configure_map(int(SIM.CONTENT.SEA_MAP_IDS.back()))
	check(EXTRA.hunt_token_reward(cached_hunt)>entry_reward,"late-region hunt token reward exceeds entry-region reward")
	check(EXTRA.normalize_quick([["invalid","plates"]])[0]==["powder","plates","skyfire"],"bad shortcut saves fall back safely")
	var forecast=SIM.new()
	forecast.islands.clear();forecast.upgrades.war=2
	forecast.activate_blessing(60)
	var prey: Dictionary=forecast.actor(100)
	prey.pos=forecast.player.pos+Vector2(200,0);prey.hp=1010;prey.shield=95
	forecast.player.ammo[2]=100;forecast.ammo_mode=2;forecast.select(100)
	var forecast_before: String=JSON.stringify([forecast.player,forecast.npcs,forecast.upgrades])
	var plan: Dictionary=EXTRA.monster_hunt_info(forecast,"tiamat")
	check(JSON.stringify([forecast.player,forecast.npcs,forecast.upgrades])==forecast_before,"monster forecast is read-only")
	forecast._fire_player()
	var harpoon: Dictionary=forecast.shots.back()
	check(int(harpoon.damage)==int(plan.damage),"forecast hit value matches actual harpoon including elite and blessing bonuses")
	for hit in int(plan.required)-1:forecast._hit(harpoon,prey)
	check(int(prey.hp)>0,"one fewer harpoon than the estimate leaves the unmarked prey alive")
	forecast._hit(harpoon,prey)
	check(int(prey.hp)==0,"estimated harpoon count finishes the static unmarked prey including its shield")
	check(not EXTRA.monster_hunt_info(forecast,"absent").present,"unknown species never fabricates a live target")
	check(not EXTRA.monster_hunt_info(forecast,"").present,"empty species key never matches unrelated monsters")
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
	game._open_modal("Events")
	var event_ammo: Array=game.sim.player.ammo.duplicate()
	var event_select: Button=game.modal_body.find_child("EventHuntSelect",true,false) as Button
	check(event_select!=null and not event_select.disabled,"event hunt has a real accessible target action")
	if event_select!=null:event_select.pressed.emit()
	check(game.sim.target==int(EXTRA.event_target(game.sim).id) and not game.sim.firing and game.sim.player.ammo==event_ammo,"event selection does not fire or spend ammunition")
	game.sim.docked=true;game._open_modal("Events")
	var event_sail: Button=game.modal_body.find_child("EventHuntSail",true,false) as Button
	check(event_sail!=null and event_sail.disabled,"event pursuit cannot move a docked ship")
	game.sim.docked=false;game._close_modal()
	game._open_modal("Events")
	var live_event: Dictionary=EXTRA.event_target(game.sim)
	live_event.hp=0;live_event.respawn=25.0;game._refresh_ui()
	var dead_select: Button=game.modal_body.find_child("EventHuntSelect",true,false) as Button
	var live_details: Label=game.modal_body.find_child("EventHuntDetails",true,false) as Label
	check(dead_select.disabled and live_details.text.contains("25 s"),"event roster updates real respawn state while open")
	game.sim.event_tokens.halloween=4;game._refresh_ui()
	var trade_button: Button=game.modal_body.find_child("EventTrade_pumpkin_ammo",true,false) as Button
	var pumpkin_stock: int=int(game.sim.player.ammo[4])
	check(trade_button!=null and not trade_button.disabled,"gaining tokens enables the actual trade without reopening")
	trade_button.pressed.emit()
	check(game.sim.event_tokens.halloween==0 and int(game.sim.player.ammo[4])==pumpkin_stock+10,"event trade UI commits the displayed purchase")
	game._close_modal()

	for dimensions in [Vector2i(844,390),Vector2i(2340,1080),Vector2i(1080,2340)]:
		root.size=dimensions;await process_frame;game._layout()
		for kind in ["Spielinfo","Verbrauch","Schnellzugriff","Events","Monster","Profil","Werft","Anzeige"]:
			game._open_modal(kind);await process_frame;await process_frame
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(game.modal.get_global_rect()),"menu fits "+kind+str(dimensions))
			check(not game.modal_back.get_global_rect().intersects(game.modal_close.get_global_rect()),"back and close remain separate")
			check(not game.modal_back.get_global_rect().intersects(game.modal_title.get_global_rect()),"back never covers title")
		game.modal.hide();game._open_modal("Spielinfo");game._open_modal("Events");game._back_modal()
		check(game.modal_kind=="Spielinfo" and game.modal.visible,"back returns to parent menu")
		check(not game.quick_bar.get_global_rect().intersects(game.attack.get_global_rect()),"quickbar leaves fire control clear")
		check(not game.quick_bar.get_global_rect().intersects(game.ammo_selector.get_global_rect()),"quickbar leaves ammunition clear")
	root.size=Vector2i(390,844);await process_frame;game._layout()
	game._open_modal("Monster");await process_frame;await process_frame
	for spec: Dictionary in EXTRA.monster_specs():
		var portrait_copy: Label=game.modal_body.find_child("MonsterDetails_"+str(spec.key),true,false) as Label
		check(portrait_copy!=null and portrait_copy.size.x>=game.modal_scroll.size.x*.7,"narrow monster card uses readable full-width text: "+str(spec.key))
	game._set_shipyard_filter("event");game._open_modal("Werft");await process_frame
	check(game.modal_body.find_children("ShipDesignPreview*","Panel",true,false).size()==2,"event shipyard filter shows only two seasonal designs")
	# PvE hunting is a real live roster: Tiamat included, no dead target
	# can be selected and buttons never enable automatic combat.
	game._open_modal("Monster");await process_frame
	var hunt_text: String=""
	var hunt_buttons: Array[Button]=[]
	for label: Label in game.modal_body.find_children("*","Label",true,false):hunt_text+=label.text+" "
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text=="ANVISIEREN":hunt_buttons.append(button)
	check(hunt_text.contains("Tiamat") and hunt_text.contains("Kraken") and hunt_text.contains("Nerissa") and hunt_text.contains("Karapax") and hunt_buttons.size()==4,"all four real living monsters appear in hunt menu")
	game.sim.firing=false
	game._hunt_monster(100)
	check(game.sim.target==100 and not game.sim.firing,"hunt selection targets Tiamat without firing automatically")
	game.sim.actor(100).hp=0
	game._open_modal("Monster");await process_frame
	var disabled_hunt: bool=false
	for button: Button in game.modal_body.find_children("*","Button",true,false):
		if button.text=="ANVISIEREN" and button.disabled:disabled_hunt=true
	check(disabled_hunt,"dead monsters cannot be selected through hunt menu")
	game.sim.actor(100).respawn=31.0;game._refresh_ui()
	var returning: Label=game.modal_body.find_child("MonsterDetails_tiamat",true,false) as Label
	check(returning!=null and returning.text.contains("31 s"),"monster roster shows actual respawn time while open")
	game.sim._step_npc(game.sim.actor(100),32.0);game._refresh_ui()
	var returned: Button=game.modal_body.find_child("MonsterSelect_tiamat",true,false) as Button
	check(not returned.disabled and returning.text.contains("HP"),"respawned monster becomes selectable without rebuilding the menu")
	game.sim.ammo_mode=0;game.sim.firing=true
	var hunting_stock: Array=game.sim.player.ammo.duplicate()
	var load_harpoons: Button=game.modal_body.find_child("LoadHuntHarpoons",true,false) as Button
	load_harpoons.pressed.emit()
	check(game.sim.ammo_mode==2 and not game.sim.firing and game.sim.player.ammo==hunting_stock,"explicit harpoon loading stops firing and never consumes stock")
	var market_link: Button=game.modal_body.find_child("HuntHarpoonMarket",true,false) as Button
	market_link.pressed.emit()
	for frame in 5:await process_frame
	var harpoon_purchase: Button=game.modal_body.find_child("MarketAmmo2",true,false) as Button
	check(game.modal_kind=="Markt" and game._tab("Markt")=="MUNITION" and harpoon_purchase!=null,"hunt market shortcut opens real harpoon offer")
	check(game.modal_scroll.scroll_vertical>0,"market shortcut scrolls directly to the harpoon card")
	game._back_modal()
	check(game.modal_kind=="Monster","market keeps a Back path to the hunt roster")
	game.sim.actor(100).hp=0
	game.sim.clear_target()
	game._hunt_monster(100)
	check(game.sim.target==-1 and not game.sim.firing,"expired monster selection never fires")
	# Invalid bonus start must not undock or spend an existing map scroll.
	game.sim.configure_map(0)
	game.sim.level=1;game.sim.docked=true;game.sim.scrolls[0]=1;game.sim.player.last_hit=-100
	game._open_modal("Bonuskarten")
	game._start_bonus(0)
	check(game.sim.docked and game.sim.map_id==0 and game.sim.scrolls[0]==1 and game.sim.message.contains("Kapitänsstufe"),"invalid bonus start stays docked and preserves entry scroll")
	game.sim.level=2
	game._start_bonus(0)
	check(not game.sim.docked and game.sim.in_bonus_map() and game.sim.scrolls[0]==0,"valid bonus start departs and spends one scroll")
	game.quick_pages[1][0]="skyfire";game.quick_page=1;game._persist_display_preferences();game.quick_pages=EXTRA.QUICK_DEFAULT.duplicate(true);game._load_display()
	check(game.quick_pages[1][0]=="skyfire" and game.quick_page==1,"custom quick slots and active page survive preferences reload")
	var fleet: Array[Dictionary]=[game.sim.player]
	for skin in [12,13]:
		game.sim.player.skin=skin;game.mesh_layer.sync_fleet(fleet,game.camera,game.get_viewport_rect().size)
		check(game.mesh_layer.model_instance_skins.get(0)==skin and game.mesh_layer.player_key_for_skin(skin)=="black_crown_corsair_elite_test","event uses original mesh with independent albedo")
	game.queue_free();await process_frame
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
