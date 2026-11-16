extends SceneTree
## M379 corrects the photographed M378 discrepancy without altering M376 motion.
## M380 preserves compact player labels and diagonal 2D/3D parity while
## increasing the deck emblem, lowering the camera and restoring green dots.
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
	var game=load("res://sea_map.tscn").instantiate()
	root.size=Vector2i(1280,720)
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	var player: Dictionary=game.sim.player
	var start: Vector2=Vector2(player.pos)
	var course: Array=player.path.duplicate(true)
	var original_slots: Array=game.sim.deck_slots.duplicate(true)
	var value: int=game.sim.cannon_slots()
	var initial_mode: String=game.render_mode
	var r: float=8.0
	var layout: Dictionary=MARKS.reference_deck_geometry(r)
	check(float(MESH.FULL_3D_CAMERA_TILT_DEGREES)==56.0,"native 3D uses the shared lowered 56-degree three-quarter camera")
	var baked_source: String=FileAccess.get_file_as_string("res://tools/bake_web_fleet.gd")
	check(baked_source.contains("var tilt=deg_to_rad(MESH.FULL_3D_CAMERA_TILT_DEGREES)") and baked_source.contains("var view_cos: float=cos(deg_to_rad(MESH.FULL_3D_CAMERA_TILT_DEGREES))"),"2D source GLB frame projection uses the exact native full-3D viewing angle")
	check(game._plate_title_size(player)<=14,"player caption is compact compared with the ship")
	check(game.PLATE_ID_BASELINE==10.0 and game.PLATE_HP_Y==19.0 and game.PLATE_SHIELD_Y==28.0 and game.PLATE_DECK_Y==51.0,"name, faded identity, HP, shield and deck occupy tight independent rows")
	check(game.PLATE_SHIELD_Y+5.0<game.PLATE_DECK_Y-6.0,"compact player deck never overlaps the shield bar")
	check(layout.left_crown.x==-layout.right_crown.x and absf(float(layout.left_crown.x))<=6.5*r+.001,"reference crowns remain symmetrical and close to ship center")
	check(layout.skulls.size()==2 and float(layout.skulls[0].x)==-float(layout.skulls[1].x),"two skulls frame the middle deck value symmetrically")
	check(layout.skulls[0].y<layout.deck_pips.y and layout.deck_pips.y<layout.bottom_crest.y and layout.number==layout.deck_pips,"ten center pips replace the old deck count; lower skull extension is separate")
	var ring: Vector2=game._selection_ring_radii(player)
	var ship: float=game._actor_visual_length(player)
	check(absf(ring.x-ship*.53)<.01 and absf(ring.y-ship*.215)<.01,"green dotted waterline ring stays proportional to the 15% smaller rendered hull")
	var points: Array[Vector2]=game._player_reference_ring_points(start,ring)
	check(points.size()==44,"player ring remains a fine 44-dot ellipse")
	check(game._selection_ring_tint(player)==Color("31e65d"),"green player identity independent of model paint")
	# Authentic parked Classic ship must keep diagonal 3/4 sprite framing
	# instead of the previous top-down cardinal 8-view image.
	var was_classic: bool=game.browser_classic
	game.browser_classic=true
	var parked: Dictionary=player.duplicate(true)
	parked["id"]=93781
	parked["kind"]="ship"
	parked["path"]=[]
	for direction: Vector2 in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
		parked["heading"]=direction
		check(game._classic_frame_for_actor(parked) in [1,3,5,7],"parked Classic ship uses oblique 3/4 framing for "+str(direction))
	game.classic_heading_cache.erase(93781)
	game.browser_classic=was_classic
	var original_skin: int=int(player.skin)
	for skin in [1,2,11,12,13]:
		player.skin=skin
		check(game._selection_ring_tint(player)==Color("31e65d"),"changing ship paints cannot alter green player ring")
	player.skin=original_skin
	check(game.sim.cannon_slots()==value and game.sim.deck_slots==original_slots,"deck appearance never changes mounted cannons or ten real standard slots")
	check(game.render_mode==initial_mode and player.pos==start and player.path==course,"player HUD and 2D sprite angle never mutate physical sailing route")
	# M379 phone screenshot QA: the old touch quickbar covered the captain
	# nameplate/HP while centered at 852x393. Test the REAL layout for each
	# landscape phone size instead of only testing button dimensions.
	for screen: Vector2i in [Vector2i(852,393),Vector2i(844,390),Vector2i(720,405)]:
		root.size=screen
		await process_frame
		game._layout()
		game.camera.position=player.pos
		game.camera.force_update_scroll()
		var p: float=game._plate_pixels()
		var anchor: Vector2=game._plate_screen_anchor(player)
		var bar_rect:=Rect2(Vector2(anchor.x-58.0*p,anchor.y+19.0*p),Vector2(116.0*p,15.0*p))
		var deck_rect:=Rect2(Vector2(anchor.x-66.0*p,anchor.y+33.0*p),Vector2(132.0*p,77.0*p))
		var quick: Rect2=game.quick_bar.get_global_rect()
		check(not quick.intersects(bar_rect),"mobile quick slots never cover captain HP/shield bars at "+str(screen))
		check(not quick.intersects(deck_rect),"mobile quick slots never cover captain ornate deck emblem at "+str(screen))
		check(not game.camera_pad.visible or not quick.intersects(game.camera_pad.get_global_rect()),"quick slots do not cover movable camera pad at "+str(screen))
		check(quick.position.x>=0.0 and quick.end.x<=float(screen.x) and quick.position.y>=0.0 and quick.end.y<=float(screen.y),"mobile quick bar stays fully on-screen at "+str(screen))
		for tab: Button in game.quick_bar.tabs:
			check(tab.size.x>=44.0 and tab.size.y>=44.0,"mobile quickbar has 44px page targets at "+str(screen))
	game.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
