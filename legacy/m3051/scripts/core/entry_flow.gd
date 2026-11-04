class_name EntryFlow
extends Node

const GAME_SCENE := "res://scenes/main.tscn"
var session: LocalSession
var menu: EntryScreen
var layer: CanvasLayer
var game: Node
var _loading := false
var _debug_clock := 0.0
var settings: ClientSettings


func _ready() -> void:
	add_to_group("entry_flow")
	DisplayServer.window_set_title("Abyssal Dominion")
	settings = ClientSettings.new()
	add_child(settings)
	var hud_layout_store:=HudLayoutStore.new()
	add_child(hud_layout_store)
	session = LocalSession.new()
	add_child(session)
	if VisualQA.requested():
		session.guest = true
		get_tree().root.set_meta("reconstruction_test_mode", true)
		_mount_game(load(GAME_SCENE) as PackedScene)
		return
	get_tree().root.content_scale_size = Vector2i.ZERO
	layer = CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	menu = EntryScreen.new()
	menu.session = session
	menu.settings = settings
	menu.action_requested.connect(_action, CONNECT_DEFERRED)
	layer.add_child(menu)
	get_tree().auto_accept_quit = false


func _action(action: String, value: String) -> void:
	if _loading:
		return
	match action:
		"continue", "login_tab": menu.show_screen("login")
		"register_tab": menu.show_screen("register")
		"submit":
			var result := session.store.register_profile(value) if menu.screen == "register" else session.store.find_profile(value)
			if result.is_empty():
				menu.show_error(session.store.error if menu.screen == "register" else "Profil nicht gefunden. Bitte zuerst lokal registrieren oder als Gast testen.")
				return
			session.guest = false
			session.profile = result
			menu.show_screen("home")
		"guest":
			session.logout()
			session.guest = true
			menu.show_screen("home")
		"logout":
			session.logout()
			menu.show_screen("login")
		"play": start_game()
		"settings": menu.show_screen("settings")
		"hud_layout":
			if is_instance_valid(game):
				menu.hide()
				game.process_mode=Node.PROCESS_MODE_INHERIT
				var player:=get_tree().get_first_node_in_group("player")
				if player!=null: player.set_meta("settings_open",false)
				var hud:=get_tree().get_first_node_in_group("hud") as GameHud
				if hud!=null: hud.open_hud_layout_editor()
			else:
				menu.show_error("HUD-Anordnung kann während einer Seesitzung angepasst werden.")
		"settings_back":
			if is_instance_valid(game):
				menu.hide()
				game.process_mode = Node.PROCESS_MODE_INHERIT
				var player := get_tree().get_first_node_in_group("player")
				if player != null: player.set_meta("settings_open", false)
			else: menu.show_screen("home")
		"import_legacy":
			if session.import_legacy():
				menu.show_screen("home")
			else:
				menu.show_error("Übernahme nicht möglich. Vorhandene Spielstände bleiben unverändert.")


func start_game() -> void:
	if not session.active() or _loading or is_instance_valid(game):
		return
	menu.show_screen("loading")
	if bool(get_tree().root.get_meta("qa_video_sync_load", false)):
		_loading = true
		call_deferred("_qa_video_mount_game")
		return
	var error := ResourceLoader.load_threaded_request(GAME_SCENE)
	if error != OK:
		menu.show_screen("home")
		menu.show_error("Spielszene konnte nicht geladen werden. Fehler %d." % error)
		return
	_loading = true


func _process(delta: float) -> void:
	if _loading:
		var progress := []
		var status := ResourceLoader.load_threaded_get_status(GAME_SCENE, progress)
		if not progress.is_empty():
			menu.loading_bar.value = float(progress[0]) * 100.0
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_loading = false
			_mount_game(ResourceLoader.load_threaded_get(GAME_SCENE) as PackedScene)
		elif status in [ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
			_loading = false
			menu.show_screen("home")
			menu.show_error("Laden fehlgeschlagen. Bitte Web-Build prüfen und erneut versuchen.")
	_debug_clock += delta
	if OS.is_debug_build() and OS.has_feature("web") and _debug_clock > 0.2:
		_debug_clock = 0.0
		var snapshot := {"screen": "sea", "controls": {}}
		if is_instance_valid(menu) and menu.visible:
			snapshot = menu.debug_snapshot()
		var extent := get_viewport().get_visible_rect().size
		snapshot["viewport"] = [extent.x, extent.y]
		JavaScriptBridge.eval("window.sfEntryState = " + JSON.stringify(snapshot) + ";")


func _qa_video_mount_game() -> void:
	_loading = false
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		if is_instance_valid(menu):
			menu.show_screen("home")
			menu.show_error("Spielszene konnte nicht geladen werden (QA sync).")
		return
	_mount_game(packed)


func _mount_game(scene: PackedScene) -> void:
	if scene == null:
		if is_instance_valid(menu):
			menu.show_screen("home")
			menu.show_error("Spielszene fehlt.")
		return
	get_tree().root.content_scale_size = Vector2i(1280, 720)
	game = scene.instantiate()
	add_child(game)
	if is_instance_valid(menu):
		menu.hide()
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.set_meta("captain_name", session.display_name())
	var state := game.get_node_or_null("GameState") as GameState
	if state != null and state.load_failed:
		var hud := get_tree().get_first_node_in_group("hud") as GameHud
		if hud != null: hud.note("Spielstand nicht lesbar. Speicherung geschützt; Originaldateien bleiben erhalten.")


func return_home() -> void:
	if not is_instance_valid(game):
		return
	var state := game.get_node_or_null("GameState") as GameState
	if state != null and not state.save_now():
		var hud := get_tree().get_first_node_in_group("hud") as GameHud
		if hud != null: hud.note("Speicherfehler — Spiel bleibt geöffnet. Erneut versuchen.")
		return
	get_tree().paused = false
	get_tree().root.set_meta("app_suspended", false)
	for type in ["AudioStreamPlayer", "AudioStreamPlayer3D"]:
		for audio in game.find_children("*", type, true, false):
			audio.stop()
	remove_child(game)
	game.queue_free()
	game = null
	get_tree().root.content_scale_size = Vector2i.ZERO
	menu.show()
	menu.show_screen("home")

func open_sea_settings() -> void:
	if not is_instance_valid(game) or not is_instance_valid(menu): return
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player != null:
		(player.get_node("PlayerInput") as PlayerShipInput).cancel_navigation()
		player.stop_ship()
		player.set_meta("settings_open", true)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	menu.show_screen("settings")
	menu.show()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(game):
			var state := game.get_node_or_null("GameState") as GameState
			if state != null and not state.save_now():
				var hud := get_tree().get_first_node_in_group("hud") as GameHud
				if hud != null: hud.note("Speicherfehler — Beenden abgebrochen.")
				return
		get_tree().quit()
