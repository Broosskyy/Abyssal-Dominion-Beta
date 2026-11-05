extends SceneTree
const VISUALS=preload("res://ship_visuals.gd")
var checks:=0
var failures: Array[String]=[]
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false);game.elapsed=2.0
	var sim=game.sim
	sim.player.pos=Vector2(2400,1500);sim.player.path=[]
	var close: Array[Dictionary]=[sim.player]
	for i in 3:
		var npc=sim.npcs[i]
		npc.pos=sim.player.pos+Vector2(-35+i*46,28+i*11);npc.home=npc.pos;npc.path=[]
		close.append(npc)
	sim.npcs.assign(close.slice(1));sim.select(int(close[1].id))
	var before: Dictionary=sim.export_save().duplicate(true)
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,405),Vector2i(2340,1080)]:
		root.size=dimensions;await process_frame
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
				var center: Vector2=game.get_canvas_transform()*sim.player.pos
				var anchor=own.position+Vector2(own.size.x*.5,17*game._plate_pixels())
				check(anchor.is_equal_approx(center+Vector2(0,36*game._plate_pixels())),"name, health and decks share a fixed waterline anchor"+suffix)
			var specials_clear=true
			for i in game.special_buttons.size():
				var button: Button=game.special_buttons[i]
				if not button.visible:continue
				var rect=button.get_global_rect()
				specials_clear=specials_clear and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(rect)
				specials_clear=specials_clear and rect.size==game.ammo_buttons[0].get_global_rect().size
				for j in game.special_buttons.size():
					if i!=j:specials_clear=specials_clear and not rect.intersects(game.special_buttons[j].get_global_rect())
				for control: Control in [game.attack,game.page_button,game.target_cycle,game.loadout_button,game.ammo_selector,game.repair,game.supply_buttons.powder]:
					specials_clear=specials_clear and not rect.intersects(control.get_global_rect())
				for button_ammo: Button in game.ammo_buttons:specials_clear=specials_clear and not rect.intersects(button_ammo.get_global_rect())
			check(specials_clear,"special ammunition shares the safe combat grid at %s / profile %d" % [dimensions,profile])
	check(sim.export_save()==before,"caption layout and HUD refresh preserve the captain save")
	for i in 4:
		game.special_buttons[i].pressed.emit()
		check(sim.ammo_mode==i+3,"special ammunition retains its real selection action %d" % i)
		var preview: Texture2D=game._ammo_texture(i+3)
		check(preview is AtlasTexture and preview.region==Rect2(160,160,192,192),"special ammunition excludes the baked checkerboard %d" % i)
	game.status_age=5.0;game._refresh_ui()
	check(not game.status.visible,"idle status disappears after four seconds")
	sim.message="Kein Ziel im sichtbaren Bereich";game._refresh_ui()
	check(game.status.visible and game.status_age==0.0,"a new message becomes visible again")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
