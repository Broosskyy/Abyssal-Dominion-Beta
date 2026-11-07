extends SceneTree
const VISUALS=preload("res://ship_visuals.gd")
var checks:=0
var failures: Array[String]=[]
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures.append(label)
func caption_clears_hull(game, actor: Dictionary, anchor: Vector2) -> bool:
	var pixels: float=game._plate_pixels()
	if game.mesh_layer!=null and game.mesh_layer.can_render_actor(actor):
		# A true 3D hull is projected from the water plane, not the 320px
		# eight-way sprite fallback. Checking sprite bounds here would enforce
		# the excessive screen gap that the M3084 player fix removes.
		# The chart test pauses _process and changes camera zoom manually.
		# Refresh the 3D owner and its orthographic camera before checking
		# projection: otherwise bottom is from the PREVIOUS test viewport.
		var sampled: Array[Dictionary]=[actor]
		game.mesh_layer.sync_fleet(sampled,game.camera,game.get_viewport_rect().size)
		var waterline: Vector2=game.get_canvas_transform()*game._visual_actor_pos(actor)
		var bottom: float=game.mesh_layer.projected_hull_bottom(actor)
		if bottom> -100000.0:
			# M3093: captain labels use a fixed circumradius envelope so they
			# do not jump while a broad ship turns. The previous <=26 px
			# upper bound assumed a heading-dependent projected AABB, and
			# is not valid for a heading-invariant anchor.
			var safe_clearance: bool=anchor.y>waterline.y and anchor.y>=bottom+10.0*pixels
			var stable_drop: float=game.mesh_layer.stable_player_plate_drop(actor,game.camera.zoom.y,pixels)
			return safe_clearance and absf((anchor.y-waterline.y)-stable_drop)<1.1
		var gap: float=anchor.y-waterline.y
		return gap>=30.0*pixels and gap<=46.0*pixels
	return anchor.y>=game._actor_screen_bounds(actor).end.y+game.CAPTAIN_HULL_CLEARANCE*pixels-.1
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false);game.elapsed=2.0
	var sim=game.sim
	check(game.plate_overlay!=null and game.plate_overlay.get_parent()==game.ui.get_parent(),"ship readouts use an independent screen-space CanvasLayer")
	check(game.plate_overlay.scale==Vector2.ONE,"ship readouts do not inherit scaled HUD")
	check(game.camera.process_callback==Camera2D.CAMERA2D_PROCESS_IDLE,"camera and screen-space readouts both update at frame rate")
	sim.player.pos=Vector2(2400,1500);sim.player.path=[]
	var close: Array[Dictionary]=[sim.player]
	for i in 3:
		var npc=sim.npcs[i]
		npc.pos=sim.player.pos+Vector2(-35+i*46,28+i*11);npc.home=npc.pos;npc.path=[]
		close.append(npc)
	sim.npcs.assign(close.slice(1));sim.select(int(close[1].id))
	var before: Dictionary=sim.export_save().duplicate(true)
	var saved_id: String=sim.captain_id
	check(saved_id.length()==12 and saved_id.is_valid_hex_number(),"captain receives a persistent 12-digit hexadecimal identity")
	check(game._plate_identity(sim.player)=="ID: "+saved_id,"captain identity appears in ship nameplate")
	check(game._plate_identity(close[1]).is_empty(),"NPCs are not falsely labeled as player identities")
	var restored=game.SIM.new()
	check(restored.restore_save(before) and restored.captain_id==saved_id,"local identity survives save/load without an account")
	check(game.PLATE_ID_BASELINE<game.PLATE_HP_Y and game.PLATE_HP_Y+7<game.PLATE_SHIELD_Y and game.PLATE_SHIELD_Y+5<game.PLATE_DECK_Y-6,"identity, hull, shield and deck components have distinct rows")
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,405),Vector2i(2340,1080)]:
		root.size=dimensions;await process_frame
		check(game.plate_overlay.size.is_equal_approx(Vector2(dimensions)),"ship label canvas follows viewport pixels, not camera coordinates")
		for profile in 3:
			game.hud_size=profile;game._layout();game._refresh_ui()
			for zoom in [.55,.96,1.4]:
				game.camera.position=sim.player.pos
				game.camera.zoom=Vector2.ONE*zoom*maxf(1.0,dimensions.y/720.0)
				game.camera.force_update_scroll()
				var placed: Dictionary=game._nameplate_layout(close)
				var suffix=" at %s / profile %d / zoom %s" % [dimensions,profile,zoom]
				check(placed.has(0),"captain caption remains visible in a close encounter"+suffix)
				check(placed.has(sim.target),"selected target caption remains visible in a close encounter"+suffix)
				var stable=true
				var own: Rect2=placed[0]
				var npc_positions: Array=[]
				for actor: Dictionary in close:
					if int(actor.id)!=0:npc_positions.append(actor.pos)
				# Other hulls cross the captain in both directions; its full block
				# must not move even one pixel, regardless of heading or target.
				for shift in [-80.0,-20.0,0.0,20.0,80.0]:
					for actor: Dictionary in close:
						if int(actor.id)!=0:actor.pos=sim.player.pos+Vector2(shift,shift*.3)
					stable=stable and game._nameplate_layout(close)[0]==own
				for i in npc_positions.size():close[i+1].pos=npc_positions[i]
				check(stable,"captain block stays anchored while other hulls cross it"+suffix)
				var anchor=own.position+Vector2(own.size.x*.5,17*game._plate_pixels())
				check(anchor.is_equal_approx(game._plate_screen_anchor(sim.player)),"name, identity, health and decks share measured hull anchor"+suffix)
				check(caption_clears_hull(game,sim.player,anchor),"captain caption respects actual 2D/3D hull baseline"+suffix)
				# Close collisions are permitted: a caption must never detach from its own hull.
				for actor: Dictionary in close:
					if not placed.has(int(actor.id)):continue
					var plate: Rect2=placed[int(actor.id)]
					var plate_anchor=plate.position+Vector2(plate.size.x*.5,17*game._plate_pixels())
					check(plate_anchor.is_equal_approx(game._plate_screen_anchor(actor)),"actor caption stays directly below its own ship even during overlaps"+suffix)
				check(not game._plate_has_rank(close[1]) and game._plate_has_rank(sim.player),"pirate rank is exclusive to players"+suffix)
			check(game.ammo_selector.visible and game.supply_buttons.values().all(func(item):return item.visible),"single ammunition selector and supplies are visible at %s / profile %d" % [dimensions,profile])
	check(sim.export_save()==before,"caption layout and HUD refresh preserve the captain save")
	# Regression: zooming while sailing previously caused one-frame-late, blurred
	# name/HP/shield/deck rendering. The projected layout is refreshed in _process
	# and the font is drawn at an integer physical size, not zoom magnified.
	for resolution in [Vector2i(844,390),Vector2i(2340,1080)]:
		root.size=resolution;await process_frame
		game._layout()
		for zoom in [.8,1.4,2.35]:
			game.camera.zoom=Vector2.ONE*zoom
			var fixed_fs=game.plate_overlay._font_size(16)
			var previous_anchor=Vector2.INF
			for step in 8:
				sim.player.pos+=Vector2(13.27,7.64)
				game.camera.position=sim.player.pos
				game.camera.force_update_scroll()
				game._sync_plate_overlay()
				check(game.plate_rects.has(0),"player plate always available while moving at zoom %.2f" % zoom)
				var r: Rect2=game.plate_rects[0]
				var anchor=(r.position+Vector2(r.size.x*.5,17*game._plate_pixels())).round()
				if previous_anchor!=Vector2.INF:
					check(anchor.is_equal_approx(previous_anchor),"locked camera keeps name/HP/shield/decks fixed on screen at zoom %.2f" % zoom)
				check(game.plate_overlay._font_size(16)==fixed_fs,"font size never changes during camera movement or zoom interpolation")
				previous_anchor=anchor
	# Video 207270: no horizontal displacement for names as nearby ships
	# approach, depart, cross the camera or become the selected target.
	for camera_move in [Vector2.ZERO,Vector2(170,-90),Vector2(-180,130)]:
		game.camera.position=sim.player.pos+camera_move
		game.camera.force_update_scroll()
		for shift in [-210.0,-45.0,0.0,45.0,210.0]:
			for i in range(1,close.size()):
				close[i].pos=sim.player.pos+Vector2(shift+float(i-1)*7,38+float(i)*13)
			var positions: Dictionary=game._nameplate_layout(close)
			for actor: Dictionary in close:
				if not positions.has(int(actor.id)):continue
				var rect: Rect2=positions[int(actor.id)]
				var center=rect.position+Vector2(rect.size.x*.5,17*game._plate_pixels())
				check(center.is_equal_approx(game._plate_screen_anchor(actor)),"NPC plate never detaches from ship when camera and neighbors move")
	# Sub-frame interpolation is shared by hull and label, and a locked follow
	# camera pins the captain plate even at max zoom while moving.
	var old_player_pos: Vector2=sim.player.pos
	var old_accumulator: float=game.accumulator
	var old_before: Dictionary=game.visual_before.duplicate(true)
	var old_after: Dictionary=game.visual_after.duplicate(true)
	var old_camera_locked: bool=game.camera_locked
	game.camera_locked=true
	for zoom in [1.0,2.4,3.2]:
		game.camera.zoom=Vector2.ONE*zoom
		for frame in 12:
			var previous: Vector2=Vector2(2400+float(frame)*4.0,1500+float(frame)*2.0)
			var latest: Vector2=previous+Vector2(4.0,2.0)
			sim.player.pos=latest
			game.visual_before={0:previous}
			game.visual_after={0:latest}
			game.accumulator=game.SIMULATION_TICK*.5
			var displayed: Vector2=game._visual_actor_pos(sim.player)
			check(displayed.is_equal_approx(previous.lerp(latest,.5)),"render position interpolates 30 Hz movement between frames")
			game.camera.position=displayed
			game.camera.force_update_scroll()
			var expected_center=game.get_viewport_rect().size*.5
			var screen_ship=game.get_canvas_transform()*displayed
			var caption=game._plate_screen_anchor(sim.player)
			check(screen_ship.distance_to(expected_center)<1.0,"smooth player ship is camera-centered while driving at high zoom")
			check(absf(caption.x-screen_ship.x)<.1,"caption and animated ship share identical horizontal projection")
	game.accumulator=old_accumulator
	game.visual_before=old_before
	game.visual_after=old_after
	sim.player.pos=old_player_pos
	game.camera_locked=old_camera_locked
	game.camera.zoom=Vector2.ONE
	game.camera.position=sim.player.pos
	game.camera.force_update_scroll()
	# No direction changes may move the status assembly around its own ship.
	var anchored_y=game._plate_screen_anchor(sim.player).y
	for heading in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2(1,1).normalized(),Vector2(-1,-1).normalized()]:
		sim.player.heading=heading
		var hull=game._actor_screen_bounds(sim.player)
		var anchor=game._plate_screen_anchor(sim.player)
		check(caption_clears_hull(game,sim.player,anchor),"all headings retain safe 2D/3D hull-to-caption baseline")
		check(is_equal_approx(anchor.y,anchored_y),"ship name, ID, bars and decks never jump during rotation")
	# A damaged sprite has exactly the same caption baseline as the intact ship.
	var original_hp=int(sim.player.hp)
	var before_damage=game._plate_screen_anchor(sim.player).y
	sim.player.hp=maxi(1,roundi(float(sim.player.max_hp)*.25))
	check(is_equal_approx(game._plate_screen_anchor(sim.player).y,before_damage),"damage visuals cannot shift caption")
	sim.player.hp=original_hp
	# NPC heading changes must also leave their own label stationary relative to the hull.
	var npc=close[1]
	var npc_y=game._plate_screen_anchor(npc).y
	for heading in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
		npc.heading=heading
		check(is_equal_approx(game._plate_screen_anchor(npc).y,npc_y),"NPC caption remains attached across all directions")
	for i in 4:
		game._open_modal("Munition");game.ammo_rows[i+3].pressed.emit()
		check(sim.ammo_mode==i+3,"special ammunition retains its real selection action %d" % i)
		var preview: Texture2D=game._ammo_texture(i+3)
		check(preview is AtlasTexture and preview.region==Rect2(160,160,192,192),"special ammunition excludes the baked checkerboard %d" % i)
	game.status_age=5.0;game._refresh_ui()
	check(not game.status.visible,"idle status disappears after four seconds")
	sim.message="Kein Ziel im sichtbaren Bereich";game._refresh_ui()
	check(game.status.visible and game.status_age==0.0,"a new message becomes visible again")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
