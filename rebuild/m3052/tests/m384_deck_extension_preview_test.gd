extends SceneTree
## M384: preview six real SVG extension assets individually without changing
## ownership, save data, standard deck layout, buff timers or sailing.
const MARKS=preload("res://sea_marks.gd")
var checks: int=0
var failures: Array[String]=[]

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(852,393)
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	var initial_owned: Dictionary=game.sim.deck_extensions.duplicate(true)
	var original_decks: Array=game.sim.deck_slots.duplicate(true)
	var before_buff: Dictionary=game.sim.buffs.duplicate(true)
	var before_gold: int=int(game.sim.player.gold)
	var before_world: Vector2=game.sim.player.pos
	var before_course: Array=game.sim.player.path.duplicate(true)
	var before_cannons: int=game.sim.cannon_slots()
	var before_save: Dictionary=game.sim.export_save()
	check(game.MODAL_TABS.Decks.has("VORSCHAU"),"Decks menu has a dedicated visual preview tab")
	check(game._deck_preview_active().is_empty(),"renderer never shows previews outside active preview modal")
	game._open_modal("Decks")
	game._switch_tab("Decks","VORSCHAU")
	await process_frame
	check(game.modal.visible and game.modal_kind=="Decks" and game._tab("Decks")=="VORSCHAU","Decks preview is an accessible genuine in-game tab")
	check(game.modal_body.find_child("DeckExtensionPreviewStage",true,false)!=null,"preview menu contains a visible in-game badge rendered from original six assets")
	for key: String in MARKS.EXTENSION_KEYS:
		check(game.modal_body.find_child("PreviewToggle_"+key,true,false)!=null,"user has a standalone toggle for "+key)
	var state: Dictionary=game._deck_preview_active()
	check(state.size()==6 and state==initial_owned,"opening preview displays actual owned extensions as baseline, without granting new ones")
	game._set_deck_preview("mojo_frame",true)
	check(bool(game._deck_preview_active().mojo_frame),"Mojo bone frame can be shown alone")
	check(not bool(game._deck_preview_active().crown_left),"Mojo frame cannot enable the left crown implicitly")
	game._set_deck_preview("skull_top_left",true)
	check(bool(game._deck_preview_active().skull_top_left) and not bool(game._deck_preview_active().skull_top_right),"each upper skull is independently toggleable")
	game._set_deck_preview("mojo_frame",false)
	check(not bool(game._deck_preview_active().mojo_frame) and bool(game._deck_preview_active().skull_top_left),"the skull remains visible after disabling Mojo frame")
	game._set_all_deck_previews(true)
	check(game._deck_preview_active().size()==6 and game._deck_preview_active().values().all(func(v):return bool(v)),"show-all is a temporary render-only preview of six separate modules")
	var all_keys: Array[Dictionary]=MARKS.reference_deck_layers(game.sim)
	check(all_keys.filter(func(v):return bool(v.installed)).size()==initial_owned.values().filter(func(v):return bool(v)).size(),"preview never sets persistent equipment ownership")
	check(game.sim.export_save().deck_extensions==before_save.deck_extensions,"the whole preview never writes its fake equipment into persisted save")
	check(game.sim.deck_slots==original_decks and game.sim.buffs==before_buff and game.sim.cannon_slots()==before_cannons,"normal decks, three timed specials and cannon capacity stay untouched")
	check(int(game.sim.player.gold)==before_gold and game.sim.player.pos==before_world and game.sim.player.path==before_course,"preview never spends money, moves player or replans sailing")
	game._switch_tab("Decks","SCHIFF")
	check(game.deck_extension_preview.is_empty() and game._deck_preview_active().is_empty(),"switching away resets every visual override immediately")
	game._switch_tab("Decks","VORSCHAU")
	game._set_all_deck_previews(true)
	game._close_modal()
	check(game.deck_extension_preview.is_empty() and game._deck_preview_active().is_empty(),"closing any modal removes all fake items from the actual playerplate")
	check(game.sim.deck_extensions==initial_owned,"user real owned items unchanged after preview close")
	game._open_modal("Decks")
	game._switch_tab("Decks","VORSCHAU")
	game._set_deck_preview("unknown_extension",true)
	check(not game.deck_extension_preview.has("unknown_extension"),"unknown/injected extension keys can never appear")
	game._open_modal("Kastelle")
	check(game.deck_extension_preview.is_empty() and game._deck_preview_active().is_empty(),"opening another menu cannot leave an incorrect painted deck")
	check(game.sim.export_save().deck_extensions==before_save.deck_extensions,"cross-menu transition never leaks preview into saved equipment")
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
