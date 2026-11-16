extends SceneTree
## M379 corrects the photographed M378 discrepancy without altering M376 motion.
## Compact side scrolls and smaller labels, green water-level dots and one
## matching 48-degree 3/4 camera for native 3D and baked 2D.
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
	var r: float=5.5
	var layout: Dictionary=MARKS.reference_deck_geometry(r)
	check(float(MESH.FULL_3D_CAMERA_TILT_DEGREES)==48.0,"native 3D uses the shared 48-degree three-quarter camera")
	var baked_source: String=FileAccess.get_file_as_string("res://tools/bake_web_fleet.gd")
	check(baked_source.contains("var tilt=deg_to_rad(MESH.FULL_3D_CAMERA_TILT_DEGREES)") and baked_source.contains("var view_cos: float=cos(deg_to_rad(MESH.FULL_3D_CAMERA_TILT_DEGREES))"),"2D source GLB frame projection uses the exact native full-3D viewing angle")
	check(game._plate_title_size(player)<=14,"player caption is compact compared with the ship")
	check(game.PLATE_ID_BASELINE==10.0 and game.PLATE_HP_Y==19.0 and game.PLATE_SHIELD_Y==28.0 and game.PLATE_DECK_Y==47.0,"name, faded identity, HP, shield and deck occupy tight independent rows")
	check(game.PLATE_SHIELD_Y+5.0<game.PLATE_DECK_Y-6.0,"compact player deck never overlaps the shield bar")
	check(layout.left_crown.x==-layout.right_crown.x and absf(float(layout.left_crown.x))<=6.5*r+.001,"reference crowns remain symmetrical and close to ship center")
	check(layout.skulls.size()==2 and float(layout.skulls[0].x)==-float(layout.skulls[1].x),"two skulls frame the middle deck value symmetrically")
	check(layout.skulls[0].y<layout.number.y and layout.number.y<layout.bottom_crest.y and layout.bottom_crest.y<layout.deck_pips.y,"ornaments and two-row deck markers have the right vertical order")
	var ring: Vector2=game._selection_ring_radii(player)
	var ship: float=game._actor_visual_length(player)
	check(ring.x<ship*.405 and ring.y<ship*.16,"waterline ring hugs hull instead of forming a broad glowing disc")
	var points: Array[Vector2]=game._player_reference_ring_points(start,ring)
	check(points.size()==44,"player ring remains a fine 44-dot ellipse")
	check(game._selection_ring_tint(player)==Color("31e65d"),"green player identity independent of model paint")
	var original_skin: int=int(player.skin)
	for skin in [1,2,11,12,13]:
		player.skin=skin
		check(game._selection_ring_tint(player)==Color("31e65d"),"changing ship paints cannot alter green player ring")
	player.skin=original_skin
	check(game.sim.cannon_slots()==value and game.sim.deck_slots==original_slots,"deck appearance never changes mounted cannons or ten real standard slots")
	check(game.render_mode==initial_mode and player.pos==start and player.path==course,"player HUD and 2D sprite angle never mutate physical sailing route")
	game.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
