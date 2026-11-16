extends SceneTree
## M378: reference-inspired ring and deck ornament must be presentation-only.
## No route, ship model, hitbox, timing or inventory mutation is allowed.
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
	var before_path: Array=sim.player.path.duplicate(true)
	var before_pos: Vector2=sim.player.pos
	var original_slots: Array=sim.deck_slots.duplicate(true)
	var original_speed: float=float(sim.player.speed)
	var standard=MARKS.reference_deck_geometry(6.0)
	check(standard.has("left_crown") and standard.has("right_crown") and standard.has("skulls") and standard.has("number") and standard.has("deck_pips"),"reference deck layout defines all required ornaments")
	check(standard.left_crown.x<0 and is_equal_approx(-float(standard.left_crown.x),float(standard.right_crown.x)),"ornamental side crowns are precisely symmetrical")
	check(standard.skulls.size()==2 and is_equal_approx(-float(standard.skulls[0].x),float(standard.skulls[1].x)),"two upper skulls sit symmetrically around center")
	check(standard.number.x==0 and standard.bottom_crest.x==0 and standard.deck_pips.x==0,"number, lower crest and ten marks share exact vertical axis")
	check(standard.skulls[0].y<standard.number.y and standard.number.y<standard.bottom_crest.y and standard.bottom_crest.y<standard.deck_pips.y,"skulls, real deck number, bottom ornament and slot marks never overlap vertically")
	var compact=MARKS.reference_deck_geometry(3.0)
	check(standard.number.distance_to(Vector2(compact.number)*2.0)<0.01 and standard.left_crown.distance_to(Vector2(compact.left_crown)*2.0)<0.01,"reference deck geometry scales proportionally for phone and desktop")
	check(MARKS.deck_entries(sim).size()==10 and MARKS.deck_cells(Vector2.ZERO,6.0).size()==10,"all ten original independent standard-deck indicators are preserved")
	check(sim.cannon_slots()==sim.BASE_CANNON_SLOTS,"center value is real cannon capacity when all deck slots are empty")
	check(sim.deck_slots==original_slots and sim.player.pos==before_pos and sim.player.path==before_path and float(sim.player.speed)==original_speed,"ornament layout never changes inventory, speed or physics")
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	var own: Dictionary=game.sim.player
	var ring_tint: Color=game._selection_ring_tint(own)
	check(ring_tint.g>ring_tint.r*2.0 and ring_tint.g>ring_tint.b*1.5,"own ship selection ring is unmistakably bright green")
	var original_skin: int=int(own.skin)
	for skin in [0,1,2,11,12,13]:
		own.skin=skin
		check(game._selection_ring_tint(own)==ring_tint,"green own-ship ring persists across player ship skins "+str(skin))
	own.skin=original_skin
	var center:=Vector2(700,900)
	var radii:=Vector2(68,27)
	var points: Array[Vector2]=game._player_reference_ring_points(center,radii)
	check(points.size()==44,"exactly 44 isolated water-contact beads form the own-ship ring")
	var all_on_ellipse: bool=true
	for point: Vector2 in points:
		var normalized: Vector2=(point-center)/radii
		all_on_ellipse=all_on_ellipse and absf(normalized.length()-1.0)<.0001
	check(all_on_ellipse,"green beads lie on one shallow ellipse centered at ship waterline")
	check(game._player_reference_ring_points(center,radii,8).size()==20,"short/low-resolution rings retain at least 20 evenly distributed dots")
	check(game._selection_ring_visible(own),"own-ship reference ring remains visible during play")
	var non_player=game.sim.npcs[0]
	check(not game._selection_ring_visible(non_player) or int(game.sim.target)==int(non_player.id),"unselected NPCs do not inherit the green player ring")
	check(game._selection_ring_tint(non_player)!=ring_tint,"NPC target colour remains separate from own-ship green")
	var preserved_mode: String=game.render_mode
	var preserved_pos: Vector2=own.pos
	var preserved_route: Array=own.path.duplicate(true)
	game._player_reference_ring_points(Vector2(800,600),Vector2(50,20))
	MARKS.reference_deck_geometry(7.0)
	check(game.render_mode==preserved_mode and own.pos==preserved_pos and own.path==preserved_route,"pure rendering helpers cannot change 2D/3D navigation")
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
