extends SceneTree
## Six independent upgrade slots. Mojo is a BONE frame, never a global skin.
## The center is ten real mounted decks, not the former cannon-capacity number.
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
	var expected: Array=["mojo_frame","crown_left","crest_right","skull_top_left","skull_top_right","skull_bottom"]
	check(SIM.DECK_EXTENSION_KEYS==expected,"all six reference extensions have their own key and independent ownership")
	check(MARKS.EXTENSION_KEYS==expected,"each extension slot has its own independent renderer/asset")
	check(sim.deck_extensions.size()==6 and sim.deck_extensions.values().all(func(x):return x==false),"new captains are not falsely granted unearned ornament upgrades")
	var originals: Array=sim.deck_slots.duplicate(true)
	var unchanged_buffs: Dictionary=sim.buffs.duplicate(true)
	var unchanged_speed: float=float(sim.player.speed)
	var unchanged_cannons: int=sim.cannon_slots()
	var items: Array[Dictionary]=MARKS.reference_deck_layers(sim)
	check(items.size()==6 and items.all(func(d):return d.asset is Texture2D and not bool(d.installed)),"six standalone imported SVG assets exist and are initially unowned")
	for key: String in expected:
		var image: Texture2D=MARKS.EXTENSION_ART[key]
		check(image!=null and image.get_width()>0 and image.get_height()>0,"standalone transparent texture imported: "+key)
		sim.deck_extensions[key]=true
		var enabled: Array[Dictionary]=MARKS.reference_deck_layers(sim)
		var active: Array[Dictionary]=enabled.filter(func(d):return bool(d.installed))
		check(active.size()==1 and str(active[0].key)==key,"only the selected extension asset appears for "+key)
		sim.deck_extensions[key]=false
	# The Mojo bone frame and five insignia can coexist but never imply a buff.
	sim.deck_extensions.mojo_frame=true
	sim.deck_extensions.skull_top_left=true
	sim.deck_extensions.skull_bottom=true
	check(MARKS.reference_deck_layers(sim).filter(func(d):return bool(d.installed)).size()==3,"Mojo frame, upper-left skull and bottom skull are independent visible layers")
	check(not bool(sim.deck_extensions.crown_left) and not bool(sim.deck_extensions.skull_top_right),"neighbouring upgrade slots remain empty until separately acquired")
	var geom: Dictionary=MARKS.reference_deck_geometry(8.0)
	check(geom.deck_pips==geom.number and geom.deck_pips.x==0,"ten pips occupy the FORMER number's exact central position")
	check(geom.skulls.size()==2 and geom.skulls[0].x==-geom.skulls[1].x and geom.skulls[0].y<geom.deck_pips.y and geom.deck_pips.y<geom.bottom_crest.y,"independent skulls above and below centered two-row deck dots")
	check(MARKS.deck_entries(sim).size()==10 and sim.deck_slots==originals,"ten normal Gold/Pearl/Crystal slots have not been replaced by ornamental expansions")
	check(sim.buffs==unchanged_buffs and float(sim.player.speed)==unchanged_speed and sim.cannon_slots()==unchanged_cannons,"the new graphic modules cannot silently grant timed buffs, cannons or speed")
	var encoded: Dictionary=JSON.parse_string(JSON.stringify(sim.export_save()))
	var restored=SIM.new()
	check(encoded.schema==8 and restored.restore_save(encoded),"modular extensions persist in optional backward-compatible schema-8 data")
	check(restored.deck_extensions==sim.deck_extensions,"each extension ownership flag survives save and reload unchanged")
	var legacy: Dictionary=encoded.duplicate(true)
	legacy.erase("deck_extensions")
	check(restored.restore_save(legacy) and restored.deck_extensions.values().all(func(x):return x==false),"loading old save resets ALL missing extension slots without touching standard decks")
	var invalid: Dictionary=encoded.duplicate(true)
	invalid.deck_extensions={"mojo_frame":true,"crown_left":"yes","invented_injection":true}
	check(restored.restore_save(invalid) and bool(restored.deck_extensions.mojo_frame) and not bool(restored.deck_extensions.crown_left) and restored.deck_extensions.size()==6,"only exact boolean known upgrade slots are restored; unknown keys rejected")
	var script: String=FileAccess.get_file_as_string("res://sea_marks.gd")
	check(not script.contains("str(sim.cannon_slots())"),"NO large cannon number is drawn under the ship anymore")
	check(script.contains("_reference_deck_pips") and script.contains("_draw_reference_module"),"ten real deck points and separate module draw calls make the playerplate")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
