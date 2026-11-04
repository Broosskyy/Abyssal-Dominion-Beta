extends SceneTree
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func check(value: bool, title: String) -> void:
	checks += 1
	if not value: failures.append(title); print("FAIL: " + title)

func settle() -> void:
	for i in 12: await process_frame

func _run() -> void:
	check(ClientSettings.validate(null) == ClientSettings.DEFAULTS, "invalid settings use defaults")
	check(ClientSettings.validate({"fps_limit": 30.0}).fps_limit == 30, "JSON float fps accepted")
	check(ClientSettings.validate({"fps_limit": 99, "shadows": "yes"}).fps_limit == 60, "invalid fps rejected")
	check(ClientSettings.validate({"render_scale": 9}).render_scale == 1.25, "scale clamped")
	check(ClientSettings.validate({"camera_sensitivity": -9}).camera_sensitivity == 0.5, "sensitivity clamped")
	var disk := ClientSettings.new()
	disk.path = "user://m30_test_" + Crypto.new().generate_random_bytes(8).hex_encode() + ".json"
	check(disk.update_value("fps_limit", 30), "isolated settings persisted")
	check(disk.update_value("camera_sensitivity", 1.5), "isolated camera preference persisted")
	var reader := ClientSettings.new()
	reader.path = disk.path
	reader.load_settings()
	check(reader.values == disk.values, "settings disk round-trip")
	var writer := GameState.new()
	writer._write_text(disk.path, "broken settings fixture")
	reader.load_settings()
	check(not reader.update_value("muted", true), "corrupt settings protected")
	check(FileAccess.get_file_as_string(disk.path) == "broken settings fixture", "corrupt bytes preserved")
	for suffix in ["", ".backup", ".tmp"]:
		if FileAccess.file_exists(disk.path + suffix): DirAccess.remove_absolute(disk.path + suffix)
	writer.free()
	reader.free()
	disk.free()
	for size_value in [Vector2(844, 390), Vector2(1280, 720), Vector2(1920, 1080), Vector2(390, 844)]:
		var safe := Rect2(Vector2(13, 7), size_value)
		var layout := NauticalLayout.calculate(safe)
		check(layout.actions.has("arsenal") and layout.actions.has("recenter"), "arsenal/recenter " + str(size_value))
		for id in layout.actions:
			var rect: Rect2 = layout.actions[id]
			check(safe.encloses(rect), "safe action " + id + str(size_value))
			check(rect.size.x >= 48 and rect.size.y >= 48, "touch size " + id)
			check(not rect.intersects(layout.wheel), "wheel clear " + id)
			check(NauticalLayout.action_at(rect.get_center(), layout) == id, "hit test " + id)
			for other in layout.actions:
				if str(id) < str(other): check(not rect.intersects(layout.actions[other]), "no overlap " + id + "/" + other + str(size_value))
	var settings := ClientSettings.new()
	root.add_child(settings)
	check(settings.memory_only, "isolated test settings")
	check(settings.update_value("combat_volume", 0.3), "combat setting update")
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Combat"))), 0.3), "combat bus applied")
	var wrapper := Node3D.new()
	root.add_child(wrapper)
	var collision := StaticBody3D.new()
	collision.name = "GameplayCollision"
	wrapper.add_child(collision)
	for id in AssetVisualLibrary.entries():
		var visual := AssetVisualLibrary.install(wrapper, id)
		check(visual != null, "load GLB " + id)
		check(wrapper.get_node("GameplayCollision") == collision, "swap preserves collision " + id)
		check(wrapper.get_child_count() == 2, "swap leaves one visual " + id)
		check(wrapper.get_meta("hud_visual_bounds", AABB()).size.length() > 0.0, "bounds " + id)
	wrapper.queue_free()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	var player := get_first_node_in_group("player") as ShipMotor
	check(player != null and player.get_node_or_null("AssetVisual") != null, "player GLB integration")
	var adapters := player.get_children().filter(func(child): return child is ReferenceVisualAdapter)
	check(adapters.size() == 1, "one ship adapter")
	if not adapters.is_empty():
		settings.update_value("visual_assets", "recovered")
		adapters[0].apply_profile("clipper")
		check(player.get_node_or_null("RecoveredVisual_clipper") != null, "recovered reference retained")
		settings.update_value("visual_assets", "placeholder")
		adapters[0].apply_profile("clipper")
		check(player.get_node_or_null("AssetVisual") != null and player.get_node_or_null("RecoveredVisual_clipper") == null, "switch back leaves no duplicate model")
	var hud := get_first_node_in_group("hud") as GameHud
	var arsenal := get_first_node_in_group("arsenal_ui") as ArsenalPanel
	var camera := root.get_camera_3d() as IsometricCameraRig
	var input := player.get_node("PlayerInput") as PlayerShipInput
	hud.open_menu("home")
	check(hud.menu_open and hud.command_deck.visible, "native command menu")
	arsenal.toggle()
	check(not arsenal.shade.visible, "modal blocks arsenal")
	for page in ["quests", "events", "shop", "help", "guild", "chat", "rankings", "log"]:
		hud.open_menu(page)
		await settle()
		check(hud.command_deck.find_children("ContentScroll", "ScrollContainer", true, false).size() == 1, "scrollable page " + page)
	hud.close_menu()
	arsenal.toggle()
	check(arsenal.shade.visible, "arsenal opens after close")
	hud.open_menu("home")
	check(not hud.menu_open, "arsenal blocks command menu")
	arsenal.toggle()
	camera.pan_camera(Vector2.RIGHT, 0.5)
	check(camera.pan_offset.length() > 0.0, "wheel pans camera")
	camera.recenter()
	check(camera.pan_offset == Vector3.ZERO, "recenter")
	input.pending_action_finger = 2
	input.pending_hud_action = "fire"
	var cancelled := InputEventScreenTouch.new()
	cancelled.index = 2
	cancelled.canceled = true
	input._unhandled_input(cancelled)
	check(input.pending_action_finger == -1 and input.pending_hud_action == "", "cancelled touch clears pending fire")
	input.has_navigation_target = true
	input._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not input.has_navigation_target and input.steering_finger == -1, "focus loss clears inputs")
	settings.update_value("fps_limit", 30)
	settings.update_value("quality", "balanced")
	settings.update_value("render_scale", 0.8)
	check(Engine.max_fps == 30, "fps applied")
	check(is_equal_approx(root.scaling_3d_scale, PlatformProfile.BALANCED_SCALE * 0.8), "scale applied")
	settings.update_value("reduced_motion", true)
	var waters := game.find_children("WaterSurface", "MeshInstance3D", true, false)
	check(not waters.is_empty() and is_equal_approx(waters[0].material_override.get_shader_parameter("motion_scale"), 0.15), "reduced water motion")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for type in ["AudioStreamPlayer", "AudioStreamPlayer3D"]:
		for audio in game.find_children("*", type, true, false): audio.stop()
	await create_timer(0.15).timeout
	game.queue_free()
	settings.queue_free()
	await settle()
	var app := load("res://scenes/entry.tscn").instantiate() as EntryFlow
	root.add_child(app)
	await settle()
	for screen in ["splash", "login", "register", "home", "settings"]:
		app.menu.show_screen(screen)
		await settle()
		check(app.menu.screen == screen, "entry " + screen)
	app._action("guest", "")
	app._mount_game(load("res://scenes/main.tscn"))
	await settle()
	app.open_sea_settings()
	check(app.menu.visible and app.menu.screen == "settings", "settings accessible from sea")
	check(app.game.process_mode == Node.PROCESS_MODE_DISABLED, "sea suspended in settings")
	app._action("settings_back", "")
	check(not app.menu.visible and app.game.process_mode == Node.PROCESS_MODE_INHERIT, "resume sea")
	app.return_home()
	await settle()
	check(app.game == null and app.menu.screen == "home", "return home lifecycle")
	app.queue_free()
	await settle()
	print(JSON.stringify({"suite": "M30", "checks": checks, "failures": failures, "engine": Engine.get_version_info().string}))
	quit(0 if failures.is_empty() else 1)
