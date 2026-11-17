extends SceneTree
## M385: six independent acquired vs equipped deck extensions, old-save
## compatibility, no fabricated purchases, combat buffs, or sailing changes.
const SIM=preload("res://simulation.gd")
const MARKS=preload("res://sea_marks.gd")
var checks: int=0
var failures: Array[String]=[]

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sim=SIM.new()
	var keys: Array=SIM.DECK_EXTENSION_KEYS
	check(keys.size()==6 and MARKS.EXTENSION_KEYS==keys,"six independently addressable persistent equipment slots")
	check(sim.deck_extension_owned.size()==6 and sim.deck_extensions.size()==6,"separate owned vs fitted dictionaries for all six ornaments")
	check(sim.deck_extension_owned.values().all(func(v):return v==false) and sim.deck_extensions.values().all(func(v):return v==false),"new captains start with six truly locked, unequipped extensions")
	var before_slots: Array=sim.deck_slots.duplicate(true)
	var before_buffs: Dictionary=sim.buffs.duplicate(true)
	var before_gold: int=int(sim.player.gold)
	var before_pos: Vector2=sim.player.pos
	var before_path: Array=sim.player.path.duplicate(true)
	var before_cannon: int=sim.cannon_slots()
	check(not sim.set_deck_extension_equipped("mojo_frame",true),"cannot equip Mojo frame before earning it")
	check(not sim.unlock_deck_extension("nonexistent") and not sim.set_deck_extension_equipped("nonexistent",true),"unknown extension identifiers rejected")
	check(sim.unlock_deck_extension("mojo_frame"),"verified game reward API can unlock exactly one Mojo module")
	check(sim.owns_deck_extension("mojo_frame") and not bool(sim.deck_extensions.mojo_frame),"unlock does not falsely auto-equip module")
	check(not sim.unlock_deck_extension("mojo_frame"),"duplicate acquisition rejected")
	check(sim.set_deck_extension_equipped("mojo_frame",true),"owned Mojo bone frame is equipable")
	check(bool(sim.deck_extensions.mojo_frame) and not bool(sim.deck_extensions.crown_left),"equipping one module does not grant its neighbour")
	check(not sim.set_deck_extension_equipped("mojo_frame",true),"equipping the same state is idempotent")
	check(sim.unlock_deck_extension("skull_bottom") and sim.set_deck_extension_equipped("skull_bottom",true),"bottom skull acquired and mounted independently")
	check(sim.set_deck_extension_equipped("mojo_frame",false),"Mojo frame can be removed while keeping the skull")
	check(sim.owns_deck_extension("mojo_frame") and not bool(sim.deck_extensions.mojo_frame),"removing equipped module never destroys ownership")
	check(bool(sim.deck_extensions.skull_bottom),"removing frame preserves separately equipped skull")
	check(sim.set_deck_extension_equipped("mojo_frame",true),"owned frame can be re-equipped anywhere after unlock")
	check(MARKS.reference_deck_layers(sim).filter(func(d):return bool(d.installed)).size()==2,"renderer draws only two genuinely fitted standalone SVGs")
	check(MARKS.deck_entries(sim).size()==10,"normal 10 Gold/Pearl/Crystal points unaffected")
	check(sim.deck_slots==before_slots and sim.buffs==before_buffs and sim.cannon_slots()==before_cannon,"six ornamental extensions do not silently add cannon/deck stats or buffs")
	check(int(sim.player.gold)==before_gold and sim.player.pos==before_pos and sim.player.path==before_path,"no prices, travel or steering side-effects invented")
	var packed: Dictionary=JSON.parse_string(JSON.stringify(sim.export_save()))
	check(packed.schema==8 and packed.has("deck_extension_owned"),"optional extension ownership field added without invalidating schema 8")
	var restored=SIM.new()
	check(restored.restore_save(packed) and restored.deck_extension_owned==sim.deck_extension_owned and restored.deck_extensions==sim.deck_extensions,"owned and fitted flags round-trip independently")
	check(restored.set_deck_extension_equipped("mojo_frame",false) and restored.owns_deck_extension("mojo_frame"),"reloaded owned Mojo can be temporarily unequipped")
	# M383/M384 game saves had only equipped flags. Preserve the user's work.
	var old: Dictionary=packed.duplicate(true)
	old.erase("deck_extension_owned")
	check(restored.restore_save(old),"previous schema 8 save without ownership field is supported")
	check(restored.owns_deck_extension("mojo_frame") and restored.owns_deck_extension("skull_bottom"),"older equipped additions are automatically preserved as owned")
	check(bool(restored.deck_extensions.mojo_frame) and bool(restored.deck_extensions.skull_bottom),"old M383 equipped visual flags stay mounted")
	var malformed: Dictionary=packed.duplicate(true)
	malformed.deck_extension_owned={"mojo_frame":"yes","crown_left":true,"exploit":true}
	malformed.deck_extensions={"mojo_frame":true,"crown_left":true,"skull_bottom":true}
	check(restored.restore_save(malformed),"corrupted ownership data is handled safely")
	check(not restored.owns_deck_extension("mojo_frame") and not bool(restored.deck_extensions.mojo_frame),"fake string ownership is refused, including requested equip")
	check(restored.owns_deck_extension("crown_left") and bool(restored.deck_extensions.crown_left),"valid true ownership still works")
	check(not restored.owns_deck_extension("skull_bottom") and not bool(restored.deck_extensions.skull_bottom),"equipment without explicit modern ownership is stripped")
	check(restored.deck_extension_owned.size()==6 and not restored.deck_extension_owned.has("exploit"),"unknown forged save keys discarded")
	# Functional in-game menu exposes all six original standalone assets,
	# not a static replacement or a misleading free unlock.
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(852,393)
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	check(game.MODAL_TABS.Decks.has("ERWEITERUNGEN"),"Decks has independent equipment tab")
	game._open_modal("Decks")
	game._switch_tab("Decks","ERWEITERUNGEN")
	await process_frame
	check(game.modal.visible and game._tab("Decks")=="ERWEITERUNGEN","actual game equipment menu opens on narrow mobile")
	for key: String in keys:
		var slot: Button=game.modal_body.find_child("DeckExtensionEquip_"+key,true,false)
		check(slot!=null and slot.disabled,"new players cannot equip an unearned "+key)
	game.sim.unlock_deck_extension("crown_left")
	game._open_modal("Decks")
	var crown: Button=game.modal_body.find_child("DeckExtensionEquip_crown_left",true,false)
	check(crown!=null and not crown.disabled,"earned item becomes equipable through UI")
	crown.pressed.emit()
	check(bool(game.sim.deck_extensions.crown_left) and game.sim.owns_deck_extension("crown_left"),"real equipment button mounts only earned crown")
	game._switch_tab("Decks","VORSCHAU")
	game._set_all_deck_previews(true)
	check(game.sim.deck_extension_owned.get("mojo_frame")==false and game.sim.deck_extensions.get("mojo_frame")==false,"old render-only preview still gives no real upgrades")
	game._close_modal()
	check(game.deck_extension_preview.is_empty(),"closing equipment preview resets visual overrides")
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
