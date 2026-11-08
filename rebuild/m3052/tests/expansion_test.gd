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
	check(EXTRA.normalize_quick([["invalid","plates"]])[0]==["powder","plates","skyfire"],"bad shortcut saves fall back safely")
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
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
	game._set_shipyard_filter("event");game._open_modal("Werft");await process_frame
	check(game.modal_body.find_children("ShipDesignPreview*","Panel",true,false).size()==2,"event shipyard filter shows only two seasonal designs")
	game.quick_pages[1][0]="skyfire";game.quick_page=1;game._persist_display_preferences();game.quick_pages=EXTRA.QUICK_DEFAULT.duplicate(true);game._load_display()
	check(game.quick_pages[1][0]=="skyfire" and game.quick_page==1,"custom quick slots and active page survive preferences reload")
	var fleet: Array[Dictionary]=[game.sim.player]
	for skin in [12,13]:
		game.sim.player.skin=skin;game.mesh_layer.sync_fleet(fleet,game.camera,game.get_viewport_rect().size)
		check(game.mesh_layer.model_instance_skins.get(0)==skin and game.mesh_layer.player_key_for_skin(skin)=="black_crown_corsair_elite_test","event uses original mesh with independent albedo")
	game.queue_free();await process_frame
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
