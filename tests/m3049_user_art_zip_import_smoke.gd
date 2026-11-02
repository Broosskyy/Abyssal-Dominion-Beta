extends SceneTree
## Real M304.9 tests: safe ZIP picker and curated asset import in the loaded game.
var failures: Array[String] = []

func check(value: bool, reason: String) -> void:
	if not value:
		failures.append(reason)

func _initialize() -> void:
	call_deferred("_run")

func _png(tint: Color) -> PackedByteArray:
	var image := Image.create(256, 192, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(45, 208):
		for y in range(35, 165):
			if absf(float(y - 98)) < 50.0 - absf(float(x - 127)) * 0.26:
				image.set_pixel(x, y, tint)
	return image.save_png_to_buffer()

func _zip(path: String, entries: Dictionary) -> void:
	var writer := ZIPPacker.new()
	check(writer.open(path) == OK, "ZIPPacker creates fixture")
	for name in entries.keys():
		check(writer.start_file(str(name)) == OK, "ZIP entry opened")
		check(writer.write_file(entries[name]) == OK, "ZIP entry written")
		check(writer.close_file() == OK, "ZIP entry closed")
	check(writer.close() == OK, "ZIP fixture closed")

func _run() -> void:
	root.size = Vector2i(844, 390)
	root.set_meta("m3035_graphic_mode", "private_sprite")
	var scene := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(scene != null, "playable game loads")
	if scene == null:
		_finish()
		return
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(game.get_script().resource_path.ends_with("m3049_mobile_user_art_import.gd"), "M304.9 is actual entry game")
	check(game._import_button != null and game._native_picker != null, "real import UI and file picker")
	check(game._native_picker.use_native_dialog and game._native_picker.access == FileDialog.ACCESS_FILESYSTEM, "Android storage document picker configured")
	check(game._safe_relative_path("ships/ship.png"), "safe PNG path allowed")
	check(not game._safe_relative_path("../ships/ship.png"), "ZIP traversal rejected")
	check(not game._safe_relative_path("ships/../../secret.png"), "nested traversal rejected")
	check(not game._safe_relative_path("ships/evil\\x.png"), "backslashes rejected")
	check(not game._safe_relative_path("C:/foo.png"), "drive path rejected")
	var manifest := {"version": "M304.9", "actors": {
		"PlayerShip": {"name": "User Player", "path": "ships/ship.png", "world_length": 16.0},
		"NPC_0": {"name": "User NPC", "path": "ships/foe.png", "world_length": 15.0}
	}}
	var fixture := "user://m3049_good.zip"
	_zip(fixture, {
		"pack.json": JSON.stringify(manifest).to_utf8_buffer(),
		"ships/ship.png": _png(Color(0.8, 0.6, 0.2)),
		"ships/foe.png": _png(Color(0.8, 0.3, 0.3)),
		"ui/cannonball.png": _png(Color(0.4, 0.4, 0.4)),
		"ui/harpoon.png": _png(Color(0.0, 0.6, 0.8)),
		"ui/chain.png": _png(Color(0.7, 0.6, 0.2)),
		"ship_effect_variants/ship_cosmetic.png": _png(Color(0.4, 0.8, 0.8))
	})
	var old_pos: Vector3 = game.ship.position
	var old_ship_id: int = game.ship.get_instance_id()
	var old_npc_id: int = (game.enemies[0]["node"] as Node3D).get_instance_id()
	game.hull = 79
	game.gold = 123
	game.cannonballs = 88
	var result: String = game._import_zip(fixture)
	check(result.contains("PNGs importiert"), "ZIP files imported with success")
	check(game._private_art_root == "user://abyssal_user_art/", "user art activates without APK rebuild")
	check(game._asset_mode == "private_sprite", "ship art renderer selected")
	check(game._private_reference_manifest["actors"]["PlayerShip"]["path"] == "ships/ship.png", "manifest loaded")
	var ship_visual: Node3D = game.ship.get_node_or_null("ShipSprite")
	check(ship_visual != null and ship_visual.has_method("set_hull_ratio"), "real transparent user player artwork in world")
	check(game._ammo_buttons[0].icon != null and game._ammo_buttons[1].icon != null and game._ammo_buttons[2].icon != null, "three functional ammunition buttons receive art")
	check(game.ship.get_instance_id() == old_ship_id and (game.enemies[0]["node"] as Node3D).get_instance_id() == old_npc_id, "no gameplay actor replaced")
	check(game.ship.position == old_pos and game.hull == 79 and game.gold == 123 and game.cannonballs == 88, "location HP money ammo unaffected")
	var bad_file := "user://m3049_traversal.zip"
	_zip(bad_file, {
		"pack.json": JSON.stringify(manifest).to_utf8_buffer(),
		"../evil.png": _png(Color.RED)
	})
	var prior_name: String = str(game._private_reference_manifest["actors"]["PlayerShip"]["name"])
	var rejected: String = game._import_zip(bad_file)
	check(rejected.contains("Unsicherer"), "path traversal rejected without installing")
	check(str(game._private_reference_manifest["actors"]["PlayerShip"]["name"]) == prior_name, "failed import leaves active pack")
	var collage := "user://m3049_concept_only.zip"
	_zip(collage, {"concept.png": _png(Color.BLUE)})
	check(game._import_zip(collage).contains("pack.json"), "concept collage rejected as game-ready asset pack")
	game._layout_hud()
	check(game._options.get_global_rect().encloses(game._import_button.get_global_rect()), "import button inside settings")
	check(game._options.get_global_rect().encloses(game._options_close.get_global_rect()), "close inside settings")
	check(not game._import_button.get_global_rect().intersects(game._options_close.get_global_rect()), "picker doesn't overlap close button")
	_finish()

func _finish() -> void:
	print(JSON.stringify({"status": "PASS" if failures.is_empty() else "FAIL", "version": "M304.9", "scope": "Android ZIP picker, validated curatorial PNG imports, anti-traversal, no reset, HUD usability", "failed": failures}))
	quit(0 if failures.is_empty() else 1)
