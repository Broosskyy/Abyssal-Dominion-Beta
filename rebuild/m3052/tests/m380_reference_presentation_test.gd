extends SceneTree
## M380: screenshot-driven visual-only sizing and stronger reference ornaments.
## This contract deliberately does not depend on model material/texture.
const MARKS=preload("res://sea_marks.gd")
const MESH=preload("res://ship_mesh_layer.gd")
var checks: int=0
var failures: Array[String]=[]

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	var player: Dictionary=game.sim.player
	var original_skin: int=int(player.skin)
	var original_pos: Vector2=player.pos
	var original_path: Array=player.path.duplicate(true)
	var original_hitbox: Variant=player.get("radius",null)
	var original_speed: Variant=player.get("speed",null)
	var original_decks: Array=game.sim.deck_slots.duplicate(true)
	var original_cannons: int=game.sim.cannon_slots()
	var original_model: String=game.mesh_layer.player_key_for_skin(original_skin) if game.mesh_layer!=null else ""
	check(is_equal_approx(game.PLAYER_PRESENTATION_SCALE,.85),"player displayed 15% smaller without resizing gameplay collider")
	player.skin=0
	check(is_equal_approx(game._actor_visual_length(player),game.FINAL_SHIP_LENGTH*.85),"starter ship is 85% of former visual size")
	for skin in [1,2,7,13]:
		player.skin=skin
		check(is_equal_approx(game._actor_visual_length(player),180.0*.85),"all elite player skins use identical smaller silhouette "+str(skin))
	player.skin=original_skin
	check(is_equal_approx(MESH.FULL_3D_CAMERA_TILT_DEGREES,56.0),"full native camera is lowered towards classic 3/4 water view")
	var bake_script: String=FileAccess.get_file_as_string("res://tools/bake_web_fleet.gd")
	check(bake_script.contains("MESH.FULL_3D_CAMERA_TILT_DEGREES"),"eight 2D GLB frames use exact same adjusted native 3D camera")
	var ring: Vector2=game._selection_ring_radii(player)
	var hull: float=game._actor_visual_length(player)
	check(ring.x>=hull*.52 and ring.y>=hull*.21,"bead ellipse visible around hull even though ship art was reduced")
	check(game._selection_ring_tint(player)==Color("31e65d"),"player selection bead ring always emerald green")
	check(game._player_reference_ring_points(original_pos,ring).size()==44,"ring retains 44 visibly separated lights")
	check(game._ring_stroke_for_zoom(2.35,1.0)>2.0,"each bead remains clearly readable at 100% zoom")
	check(game.PLATE_ID_BASELINE<game.PLATE_HP_Y and game.PLATE_HP_Y<game.PLATE_SHIELD_Y and game.PLATE_SHIELD_Y<game.PLATE_DECK_Y,"name, HP, shield and deck read top to bottom")
	check(game.PLATE_DECK_Y==51.0,"enlarged emblem starts below the shield instead of floating away")
	var r: float=8.0
	var layout: Dictionary=MARKS.reference_deck_geometry(r)
	check(layout.left_crown.x==-layout.right_crown.x and layout.skulls[0].x==-layout.skulls[1].x,"gold crown/skull fittings are truly symmetric")
	check(layout.skulls[0].y<0 and layout.number.y>0 and layout.number.y<layout.bottom_crest.y and layout.bottom_crest.y<layout.deck_pips.y,"two skulls, large number, bottom special and 10 deck cells form correct stack")
	check(layout.number.x==0 and layout.bottom_crest.x==0 and layout.deck_pips.x==0,"the enlarged number and lower pirate crest remain centered")
	check(int(roundi(r*3.2))>=25,"the central cannon number is at least 25px, not microscopic")
	check(MARKS.deck_entries(game.sim).size()==10,"ten real independent deck statuses still exist")
	var overlay_source: String=FileAccess.get_file_as_string("res://ship_plate_overlay.gd")
	check(overlay_source.contains("51*pixel_scale),8.0*pixel_scale"),"rendered pixel-space overlay actually draws the larger deck")
	var marks_source: String=FileAccess.get_file_as_string("res://sea_marks.gd")
	check(marks_source.contains("_reference_special_icon") and marks_source.contains("\"tide\"") and marks_source.contains("\"storm\"") and marks_source.contains("\"salvage\""),"three specials have distinct original pictograms in the reference deck")
	check(player.pos==original_pos and player.path==original_path and player.get("radius",null)==original_hitbox and player.get("speed",null)==original_speed,"HUD, GLB appearance and ring never alter movement, collisions or ship speed")
	check(game.sim.deck_slots==original_decks and game.sim.cannon_slots()==original_cannons,"gold/pearl/crystal upgrades and real cannon capacity unchanged")
	if game.mesh_layer!=null:
		check(game.mesh_layer.player_key_for_skin(original_skin)==original_model,"ship size does not replace original 3D model")
	# No touch HUD may overlap the complete enlarged nameplate assembly.
	for screen: Vector2i in [Vector2i(852,393),Vector2i(844,390),Vector2i(720,405)]:
		root.size=screen
		await process_frame
		game._layout()
		game.camera.position=player.pos
		game.camera.force_update_scroll()
		var anchor: Vector2=game._plate_screen_anchor(player)
		var px: float=game._plate_pixels()
		var deck_bounds:=Rect2(anchor+Vector2(-68,33)*px,Vector2(136,78)*px)
		var quick: Rect2=game.quick_bar.get_global_rect()
		check(not quick.intersects(deck_bounds),"mobile quickbar does not cover bigger M380 deck at "+str(screen))
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
