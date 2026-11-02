extends SceneTree
## M304.8 test actual Godot scene with generated private artwork fixture.
## Gameplay and HP retain state when cosmetic skins change.
var failures: Array[String] = []

func check(value: bool, reason: String) -> void:
	if not value:
		failures.append(reason)

func _initialize() -> void:
	call_deferred("_run")

func _make_image(path: String, tint: Color) -> void:
	var image := Image.create(256, 192, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(30, 165):
		for x in range(35, 224):
			if absf(float(y - 98)) < (1.0 - absf(float(x - 125)) / 116.0) * 60.0:
				image.set_pixel(x, y, tint)
	check(image.save_png(ProjectSettings.globalize_path(path)) == OK, "test private texture created")

func _run() -> void:
	root.size = Vector2i(844, 390)
	var root_path := "user://abyssal_user_art/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_path + "ships"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_path + "ship_effect_variants"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_path + "ui"))
	_make_image(root_path + "ships/base.png", Color(0.75, 0.70, 0.55))
	_make_image(root_path + "ship_effect_variants/base_cosmetic.png", Color(0.20, 0.80, 0.75))
	for name in ["cannonball", "chain", "harpoon"]:
		_make_image(root_path + "ui/" + name + ".png", Color(0.55, 0.65, 0.85))
	var manifest := {
		"version": "M304.8",
		"actors": {
			"PlayerShip": {"name": "Test Intact Ship", "path": "ships/base.png", "world_length": 17.0},
			"NPC_0": {"name": "Test NPC", "path": "ships/base.png", "world_length": 13.0}
		}
	}
	var writer := FileAccess.open(root_path + "pack.json", FileAccess.WRITE)
	check(writer != null, "writable fixture manifest")
	if writer == null:
		_finish()
		return
	writer.store_string(JSON.stringify(manifest))
	writer.close()
	root.set_meta("m3035_graphic_mode", "private_sprite")
	var scene := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(scene != null, "M304.8 game scene loads")
	if scene == null:
		_finish()
		return
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check((game.get_script().resource_path.ends_with("m3048_user_ship_variants.gd") or game.get_script().resource_path.ends_with("m3049_mobile_user_art_import.gd")),
		"reference art integration is live in playable game")
	check(not game._private_reference_manifest.is_empty(), "user artpack discovered before game starts")
	var sprite: Node = game.ship.get_node_or_null("ShipSprite")
	check(sprite != null and sprite.has_method("set_hull_ratio"), "player uses transparent custom base art")
	if sprite != null:
		check(sprite.visual.frame == 0 and sprite.visual.hframes == 1, "custom ship has only healthy frame")
	var npc: Node3D = game.enemies[0]["node"]
	var npc_id: int = npc.get_instance_id()
	var ship_id: int = game.ship.get_instance_id()
	game.hull = 100
	game.gold = 95
	game.cannonballs = 110
	game._refresh()
	check(not game._cosmetic_ship_effects, "cosmetic skin initially off")
	check(game._custom_actor("PlayerShip")["path"] == "ships/base.png", "healthy base image selected")
	check(game._ammo_buttons[0].icon != null and game._ammo_buttons[1].icon != null and game._ammo_buttons[2].icon != null,
		"three real ammunition buttons use image icons")
	game._toggle_cosmetic_ship_effects()
	check(game._cosmetic_ship_effects, "user can enable separate cosmetic skins")
	check(game._custom_actor("PlayerShip")["path"] == "ship_effect_variants/base_cosmetic.png",
		"cosmetics choose separate image without relating it to hull status")
	check(game.hull == 100 and game.gold == 95 and game.cannonballs == 110,
		"enabling cosmetics does not alter health or resources")
	check(game.ship.get_instance_id() == ship_id and npc.get_instance_id() == npc_id,
		"player and enemy real gameplay actors are preserved")
	var after_toggle: Node = game.ship.get_node_or_null("ShipSprite")
	check(after_toggle != null and after_toggle.visual.frame == 0,
		"cosmetic skin remains intact fixed sprite")
	game.hull = 12
	game._refresh()
	check(game._custom_actor("PlayerShip")["path"] == "ship_effect_variants/base_cosmetic.png",
		"low HP does not switch skin or create a wreck picture")
	check(after_toggle.visual.frame == 0, "low HP does not select damaged atlas frame")
	game.hull = 100
	game._toggle_cosmetic_ship_effects()
	check(game._custom_actor("PlayerShip")["path"] == "ships/base.png", "restores healthy no-effect source")
	check(game.hull == 100, "remains healthy and intact after turnoff")
	var previous: Vector3 = game.ship.position
	game.route.clear()
	game._course(previous + Vector3(23.0, 0.0, 0.0))
	game._sail(0.016)
	check(game.ship.position.x > previous.x + 0.05, "instant click-to-sail retained")
	game._layout_hud()
	check(game._art_variants_button != null and game._pack_status != null,
		"new responsive options controls are real and usable")
	print("M3049_PANEL_DEBUG", str(game._options.get_global_rect()), " TOGGLE ", str(game._art_variants_button.get_global_rect()), " CLOSE ", str(game._options_close.get_global_rect()))
	check(game._options.get_global_rect().encloses(game._art_variants_button.get_global_rect()),
		"toggle lies entirely inside settings panel")
	check(game._options.get_global_rect().encloses(game._options_close.get_global_rect()),
		"settings close stays accessible")
	_finish()

func _finish() -> void:
	print(JSON.stringify({
		"status": "PASS" if failures.is_empty() else "FAIL",
		"version": "M304.8",
		"scope": "real private art pack parser, healthy ship always 1 frame, cosmetic skins independent of HP, ammo images, instant course and settings UI",
		"failed": failures
	}))
	quit(0 if failures.is_empty() else 1)
