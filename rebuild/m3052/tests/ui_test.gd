extends SceneTree
var failures: Array[String]=[]
var count:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	check(game.ship_textures.size()==10 and game.atlas_textures.size()==16,"ten own ship designs and sixteen directional reference atlases loaded")
	check(game.skins.size()==26,"all 26 ship designs are selectable")
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,405)]:
		root.size=dimensions
		await process_frame
		game._layout()
		game.sim.select(2)
		game._refresh_ui()
		var controls: Array=[game.attack,game.repair,game.zoom_in,game.zoom_out,game.center_button]
		controls.append_array(game.ammo_buttons)
		for control: Control in controls:
			var rect=control.get_global_rect()
			check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=dimensions.x+1 and rect.end.y<=dimensions.y+1,"touch control inside viewport %s"%dimensions)
		for i in controls.size():
			for j in range(i+1,controls.size()):
				check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()),"independent touch targets %s / %s at %s"%[controls[i].name,controls[j].name,dimensions])
		check(not game.player_panel.get_global_rect().intersects(game.target_panel.get_global_rect()),"player and target cards do not overlap")
		game._open_modal("Werft")
		await process_frame
		check(game.modal_scroll.size.y>100 and game.modal_scroll.get_v_scroll_bar().max_value>game.modal_scroll.size.y,"shipyard uses actual scrollable content")
		game.modal.hide()
	var hp=int(game.sim.player.hp)
	var gold=int(game.sim.player.gold)
	var position: Vector2=game.sim.player.pos
	game._equip(8)
	check(int(game.sim.player.skin)==8 and int(game.sim.player.hp)==hp and int(game.sim.player.gold)==gold and game.sim.player.pos==position,"equipping design preserves position, hull and wallet")
	game.modal.hide()
	game.sim.select(2)
	game._toggle_fire()
	check(game.sim.firing,"fire control changes actual simulation state")
	game.ammo_buttons[1].pressed.emit()
	check(game.sim.ammo_mode==1,"ammo UI selects actual chain ammunition")
	game.sim.player.gold=543
	game._save_progress()
	game.sim.player.gold=0
	game._load_progress()
	check(int(game.sim.player.gold)==543 and int(game.sim.player.skin)==8,"guest save reloads wallet and ship design")
	var result={"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
