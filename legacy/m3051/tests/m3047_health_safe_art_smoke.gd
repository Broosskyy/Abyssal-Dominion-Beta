extends SceneTree
## M304.7 verified artifact row: healthy SeaBattles ship has full sails.
## Also test new safe top-down source-image import without shipping user artwork.
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.set_meta("m3035_graphic_mode","private_sprite")
	var packed := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(packed != null, "playable M304.7 scene loads")
	if packed == null:
		_finish()
		return
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var inherited: Script = game.get_script()
	var includes_m3047 := false
	while inherited != null:
		if inherited.resource_path.ends_with("m3047_user_reference_art_mode.gd"):
			includes_m3047 = true
			break
		inherited = inherited.get_base_script()
	check(includes_m3047, "health-safe art loader persists through M304.8")
	var examined := 0
	for node: Node3D in [game.ship, game.enemies[0]["node"], game.enemies[1]["node"], game.enemies[2]["node"]]:
		var adapter: Node = node.get_node_or_null("ShipSprite")
		check(adapter != null, "ship sprite has source adapter")
		if adapter == null:
			continue
		var sprite: Sprite3D = adapter.visual
		check(sprite != null and sprite.vframes == 2, "real SeaBattles 4x2 ship atlas exists")
		if sprite == null:
			continue
		examined += 1
		for step in 64:
			adapter.set_moving(step % 2 == 0)
			adapter.set_heading(float(step) * TAU / 64.0)
			check(sprite.frame >= sprite.hframes and sprite.frame < sprite.hframes * 2,
				"healthy frame must show deployed sails, not visually wreck-like furled row")
		check(adapter._verified_full_sail_row == 1,
			"row 1 assigned ONLY after visual inspection of SeaBattles reference sheet")
	check(examined >= 4, "player plus 3 NPC classes were graphically checked")
	game.hull = 100
	game._refresh()
	var healthy: Node = game.ship.get_node_or_null("ShipSprite")
	check(healthy.visual.frame >= healthy.visual.hframes, "full HP uses correct sails")
	game.hull = 35
	game._refresh()
	check(healthy.visual.frame >= healthy.visual.hframes,
		"HP changes never select furled/wreck-looking reference row")
	game.hull = 100
	game._refresh()
	check(healthy.visual.frame >= healthy.visual.hframes, "repair fully restores healthy depiction")

	# Local synthetic transparent texture stands in for the user's *separate*
	# high-quality reference PNGs, which are not placed in public GitHub.
	var local_root := "user://abyssal_user_art/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(local_root + "ships"))
	var texture := Image.create(256, 128, false, Image.FORMAT_RGBA8)
	texture.fill(Color(0,0,0,0))
	for y in range(25,102):
		for x in range(30,227):
			if absf(float(y - 64)) < (1.0 - absf(float(x - 128))/105.0) * 35.0:
				texture.set_pixel(x,y,Color(0.52,0.32,0.18,1.0))
	check(texture.save_png(ProjectSettings.globalize_path(local_root+"ships/test.png")) == OK,
		"synthetic top-down test texture saved")
	var manifest: Dictionary = {"actors":{"PlayerShip":{"name":"Test Ship","path":"ships/test.png","world_length":15.0}}}
	var writer := FileAccess.open(local_root+"pack.json", FileAccess.WRITE)
	check(writer != null, "synthetic actor manifest created")
	if writer != null:
		writer.store_string(JSON.stringify(manifest))
		writer.close()
	game._find_private_art_pack()
	check(not game._private_reference_manifest.is_empty(), "private reference pack discovered")
	var stable_ship_id: int = game.ship.get_instance_id()
	game._replace_visual(game.ship, game.SHIP, 0.9, "PlayerShip", game.CAPTAIN_ATLAS)
	var top_view: Node = game.ship.get_node_or_null("ShipSprite")
	check(top_view != null and top_view.has_method("set_hull_ratio"),
		"original reference top-down sprite replaces old atlas without touching gameplay ship")
	if top_view != null:
		check(top_view.visual.frame == 0 and top_view.visual.hframes == 1 and top_view.visual.vframes == 1,
			"single intact top-view cannot ever show alternate wreck frame")
		for step in 80:
			top_view.set_heading(float(step) * 0.09)
			top_view.set_moving(step % 2 == 0)
			top_view.set_hull_ratio(float(step % 101) / 100.0)
			check(top_view.visual.frame == 0, "sailing and HP never corrupt intact top-down art")
	check(game.ship.get_instance_id() == stable_ship_id,
		"source-image import preserves ship ID and physics")
	check(game._ammo_panel != null and game._yard_panel != null,
		"ammo/shipyard still functional with user visual pack")
	_finish()

func _finish() -> void:
	print(JSON.stringify({
		"version":"M304.7","status":"PASS" if failures.is_empty() else "FAIL",
		"scope":"verified full-sail row 1 at any HP or heading, custom top-down import, UI and ship identity",
		"failed":failures
	}))
	quit(0 if failures.is_empty() else 1)
