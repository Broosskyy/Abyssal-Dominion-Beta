extends SceneTree

var checks := 0
var failures := 0
var layouts := []

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _check(value: bool, title: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: " + title)

func _settle() -> void:
	for i in 8:
		await process_frame

func _run() -> void:
	_check(HomeSummary.from_save({}).ship_id == "clipper", "new captain defaults to Clipper")
	for id in ["clipper", "barco_low", "chalupa"]:
		var summary := HomeSummary.from_save({"ship_roster": {"selected_ship_id": id, "owned_ship_ids": [id]}, "world": {"sector": [2, 1]}})
		_check(summary.ship_id == id, "owned selection " + id)
		_check(summary.sector_name == "3-2 Dominus Regina", "saved sector " + id)
	_check(HomeSummary.from_save({"ship_roster": {"selected_ship_id": "chalupa", "owned_ship_ids": ["clipper"]}}).ship_id == "clipper", "unowned selection rejected")
	_check(HomeSummary.from_save({"ship_roster": {"selected_ship_id": "missing", "owned_ship_ids": ["missing"]}}).ship_id == "clipper", "unknown selection rejected")
	for invalid in [null, [], "bad", {"sector": [999, 9]}, {"sector": ["bad", 1]}]:
		_check(HomeSummary.from_save({"world": invalid, "ship_roster": invalid}).sector_name == "1-1 Novice Tide", "invalid summary safe")
	_check(ClientSettings.validate(null) == ClientSettings.DEFAULTS, "settings defaults")
	_check(ClientSettings.validate({"volume": 20}).volume == 1.0, "volume upper clamp")
	_check(ClientSettings.validate({"volume": -20}).volume == 0.0, "volume lower clamp")
	_check(ClientSettings.validate({"volume": "bad", "muted": "yes", "quality": "ultra", "map_transition": 0}) == ClientSettings.DEFAULTS, "typed validation")
	var disk := ClientSettings.new()
	disk.path = "user://m14_test_%s.json" % Crypto.new().generate_random_bytes(8).hex_encode()
	_check(disk.update_value("volume", 0.23), "write isolated settings")
	_check(disk.update_value("muted", true), "write mute")
	_check(disk.update_value("quality", "low"), "write quality")
	var loaded := ClientSettings.new()
	loaded.path = disk.path
	loaded.load_settings()
	_check(loaded.values == disk.values, "disk round trip")
	_check(loaded.reset_defaults(), "reset settings only")
	_check(loaded.values == ClientSettings.DEFAULTS, "reset values")
	var writer := GameState.new()
	_check(writer._write_text(disk.path, "broken json"), "isolated corruption fixture")
	loaded.load_settings()
	_check(loaded.values == ClientSettings.DEFAULTS and not loaded.error.is_empty(), "corrupt fallback")
	_check(not loaded.update_value("muted", true), "corrupt settings write protected")
	_check(FileAccess.get_file_as_string(disk.path) == "broken json", "corrupt original preserved")
	_check(DirAccess.remove_absolute(disk.path) == OK, "isolated fixture removed")
	writer.free()
	disk.free()
	loaded.free()
	var app := load("res://scenes/entry.tscn").instantiate() as EntryFlow
	root.add_child(app)
	await _settle()
	_check(app.settings.memory_only, "tests never write actual device settings")
	app._action("guest", "")
	for extent in [Vector2i(1600, 900), Vector2i(844, 390), Vector2i(915, 412), Vector2i(390, 844)]:
		root.size = extent
		await _settle()
		var play: Control = app.menu.controls.play
		var rect := play.get_global_rect()
		_check(rect.position.y >= 0 and rect.end.y <= extent.y, "Play above fold " + str(extent))
		_check(rect.position.x >= 0 and rect.end.x <= extent.x, "Play horizontal fit " + str(extent))
		for id in ["play", "settings", "logout"]:
			_check(app.menu.controls[id].size.y >= 48, "touch height " + id + str(extent))
		layouts.append({"viewport": [extent.x, extent.y], "snapshot": app.menu.debug_snapshot()})
		app._action("settings", "")
		await _settle()
		_check(app.menu.controls.has("quality") and app.menu.controls.has("settings_back"), "settings reachable " + str(extent))
		app._action("settings_back", "")
		await _settle()
	app._action("logout", "")
	app.menu.name_field.text = "TypedCaptain"
	root.size = Vector2i(844, 390)
	await _settle()
	_check(app.menu.name_field.text == "TypedCaptain", "rotation keeps typed name")
	app._action("guest", "")
	app._action("settings", "")
	await _settle()
	app.menu.controls.muted.button_pressed = true
	_check(AudioServer.is_bus_mute(0), "UI mute reaches audio bus")
	app.menu.controls.volume.value = 36
	_check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.36), "UI volume reaches audio bus")
	app.menu.controls.map_transition.button_pressed = false
	_check(not ClientSettings.show_map_transition(self), "UI map preference applied")
	app.menu.controls.quality.item_selected.emit(3)
	_check(app.settings.values.quality == "high", "UI quality applied")
	app._action("settings_back", "")
	for id in ["clipper", "barco_low", "chalupa"]:
		var preview := EntryShipPreview.new()
		preview.ship_id = id
		app.menu.add_child(preview)
		await _settle()
		var meshes := preview.find_children("*", "MeshInstance3D", true, false)
		_check(not meshes.is_empty(), "real preview meshes " + id)
		var cameras := preview.find_children("*", "Camera3D", true, false)
		_check(cameras.size() == 1 and cameras[0].size > 0 and is_finite(cameras[0].size), "finite fitted camera " + id)
		_check(not preview.find_children("RecoveredVisual_" + id, "Node3D", true, false).is_empty(), "correct preview family " + id)
		preview.queue_free()
		await _settle()
	for cycle in 5:
		app.start_game()
		var deadline := Time.get_ticks_msec() + 15000
		while not is_instance_valid(app.game) and Time.get_ticks_msec() < deadline:
			await process_frame
		await _settle()
		_check(is_instance_valid(app.game) and get_nodes_in_group("player").size() == 1, "one player cycle " + str(cycle))
		var profiles := app.game.find_children("*", "PlatformProfile", true, false)
		_check(profiles.size() == 1, "one quality controller")
		var platform: PlatformProfile = profiles[0]
		_check(platform.quality_tier == "high", "manual high applied on game mount")
		platform._fps_samples.assign([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0])
		platform._process(2.0)
		_check(platform.quality_tier == "high", "manual preference resists adaptation")
		app.settings.update_value("quality", "low")
		_check(platform.quality_tier == "low", "live low setting")
		app.settings.update_value("quality", "auto")
		_check(platform.quality_preference == "auto" and platform._fps_samples.is_empty(), "auto resets sampler")
		app.settings.update_value("quality", "high")
		var world := get_first_node_in_group("world_map") as WorldMapSystem
		world._transition(Vector2i.RIGHT)
		_check(world.current_sector == Vector2i(1, 0), "hidden transition still changes sector")
		app.return_home()
		await _settle()
		_check(get_nodes_in_group("player").is_empty(), "no player leak cycle " + str(cycle))
		_check(get_nodes_in_group("client_settings").size() == 1, "one persistent settings service")
	app.settings.reset_defaults()
	app.queue_free()
	await _settle()
	var report := FileAccess.open("res://docs/m14_layout_validation.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"rendering": "headless; geometry checks only, NOT visual acceptance", "layouts": layouts}, "\t"))
	report.close()
	print("M14_ENGINE_TESTS: %d/%d passed" % [checks - failures, checks])
	quit.call_deferred(0 if failures == 0 else 1)
