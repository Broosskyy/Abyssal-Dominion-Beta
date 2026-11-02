extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()


func _check(value: bool, title: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: " + title)


func _run() -> void:
	var store := LocalProfileStore.new()
	store.memory_only = true
	store.load_profiles()
	for invalid in ["", "ab", "../Corsair", "<script>", "Captain@sea.com", " twenty characters too long "]:
		_check(store.register_profile(invalid).is_empty(), "invalid name: " + invalid)
	var first := store.register_profile("Corsair One")
	_check(not first.is_empty(), "registration")
	_check(LocalProfileStore.valid_id(first.id), "safe random ID")
	_check(store.find_profile("corsair one").id == first.id, "case insensitive login")
	_check(store.register_profile("CORSAIR ONE").is_empty(), "duplicate name")
	_check(LocalProfileStore.save_path({"id": "../bad"}).is_empty(), "unsafe save path rejected")
	var second := store.register_profile("Corsair Two")
	_check(LocalProfileStore.save_path(first) != LocalProfileStore.save_path(second), "save isolation")
	for i in 6:
		store.register_profile("Captain%d" % i)
	_check(store.profiles.size() == 8, "capacity")
	_check(store.register_profile("NinthCaptain").is_empty(), "capacity enforced")
	var disk := LocalProfileStore.new()
	disk.path = "user://m13_test_%s.json" % Crypto.new().generate_random_bytes(8).hex_encode()
	_check(not disk.register_profile("DiskCaptain").is_empty(), "actual file write")
	var reloaded := LocalProfileStore.new()
	reloaded.path = disk.path
	reloaded.load_profiles()
	_check(reloaded.find_profile("DiskCaptain").id == disk.profiles[0].id, "registry reload")
	var writer := GameState.new()
	_check(writer._write_text(disk.path, "broken json"), "atomic writer")
	reloaded.load_profiles()
	_check(reloaded.register_profile("DoNotOverwrite").is_empty(), "corrupt registry protected")
	_check(FileAccess.get_file_as_string(disk.path) == "broken json", "corrupt bytes preserved")
	_check(DirAccess.remove_absolute(disk.path) == OK, "isolated test cleanup")
	writer.free()
	var app := load("res://scenes/entry.tscn").instantiate() as EntryFlow
	root.add_child(app)
	await process_frame
	_check(app.menu.screen == "splash", "boots to splash")
	_check(get_nodes_in_group("player").is_empty(), "no menu combat")
	app._action("continue", "")
	_check(app.menu.screen == "login", "splash to login")
	app._action("submit", "Missing")
	_check(app.menu.error_label.visible, "login error")
	app._action("register_tab", "")
	_check(app.menu.screen == "register", "register tab")
	app._action("submit", "LocalCaptain")
	_check(app.menu.screen == "home", "registered home")
	_check(app.session.display_name() == "LocalCaptain", "selected name")
	_check(app.menu.controls.has("play"), "Play button")
	app._action("play", "")
	var deadline := Time.get_ticks_msec() + 15000
	while not is_instance_valid(app.game) and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	_check(is_instance_valid(app.game), "actual scene loaded")
	_check(get_nodes_in_group("player").size() == 1, "one player")
	var state := app.game.get_node("GameState") as GameState
	_check(state.save_path == LocalProfileStore.save_path(app.session.profile), "runtime profile binding")
	app.return_home()
	await process_frame
	_check(app.menu.screen == "home" and not is_instance_valid(app.game), "return removes game")
	_check(get_nodes_in_group("player").is_empty(), "old player gone")
	app._action("logout", "")
	_check(not app.session.active(), "logout clears session")
	app._action("guest", "")
	_check(app.session.guest and app.session.profile.is_empty(), "guest isolated")
	app._action("play", "")
	deadline = Time.get_ticks_msec() + 15000
	while not is_instance_valid(app.game) and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	state = app.game.get_node("GameState") as GameState
	_check(state.transient_session, "guest saves disabled")
	_check(state.save_now(), "guest leave without writes")
	app.return_home()
	await process_frame
	app.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("M13_ENGINE_TESTS: %d/%d passed" % [checks - failures, checks])
	quit.call_deferred(0 if failures == 0 else 1)
