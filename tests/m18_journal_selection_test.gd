extends SceneTree

var checks := 0
var failures := 0
var completions: Array[Dictionary] = []

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func check(value: bool, title: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: " + title)

func frames() -> void:
	for index in 6: await process_frame

func _run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames()
	var world: WorldMapSystem = game.get_node("WorldMapSystem")
	world.set_process(false)
	world.encounters.set_process(false)
	for ship in get_nodes_in_group("ships"):
		ship.set_physics_process(false)
		for child in ship.get_children():
			if child is EnemyShipAI or child is PlayerShipInput or child is ShipWeapons: child.set_process(false)
	var player := world.player
	player.set_meta("in_safe_zone", false)
	var missions: MissionSystem = player.get_node("Missions")
	var progression: PlayerProgression = player.get_node("Progression")
	var weapons: ShipWeapons = player.get_node("Weapons")
	var input: PlayerShipInput = player.get_node("PlayerInput")
	var health: ShipHealth = player.get_node("Health")
	var inventory: PlayerInventory = player.get_node("Inventory")
	var targeting: TargetingSystem = player.get_node("Targeting")
	var journal: CaptainJournal = game.get_node("HUDLayer/CaptainJournal")
	var arsenal: ArsenalPanel = game.get_node("HUDLayer/ArsenalPanel")
	var hud: GameHud = game.get_node("HUDLayer/GameHUD")
	root.content_scale_size = Vector2i.ZERO
	for extent in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = extent
		await frames()
		journal.opener.pressed.emit()
		await frames()
		check(journal.shade.visible and player.get_meta("journal_open", false), "mission button opens real modal")
		check(root.get_visible_rect().encloses(journal.panel.get_global_rect()), "journal fits viewport " + str(extent))
		for button in [journal.close_button, journal.mission_tab, journal.harbor_tab]:
			check(button.size.y >= 48, "sticky control touch height")
			check(journal.panel.get_global_rect().encloses(button.get_global_rect()), "sticky control reachable")
		check(not journal.close_button.get_global_rect().intersects(journal.mission_tab.get_global_rect()), "close and tabs do not overlap")
		journal.show_page("harbor")
		await frames()
		check(journal.harbor_page.visible and not journal.mission_page.visible, "harbor tab swaps content")
		journal.close()
	weapons.auto_fire = true
	input.has_navigation_target = true
	journal.show_page("missions")
	check(not weapons.auto_fire and not input.has_navigation_target, "journal stops navigation and auto")
	var stock := inventory.count("iron")
	weapons.last_shot_time = -99
	check(not weapons.fire_broadside() and stock == inventory.count("iron"), "journal blocks manual fire and ammo cost")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(200, 400)
	input._unhandled_input(event)
	check(not input.has_navigation_target, "modal click cannot sail")
	arsenal.toggle()
	hud.toggle_global_map()
	check(not arsenal.shade.visible and not hud.global_map_open, "journal excludes arsenal and map hotkeys")
	journal.close()
	check(not player.get_meta("journal_open", false) and not weapons.auto_fire, "close releases modal without restarting attack")
	check(not weapons.fire_broadside(), "close-button key cannot leak through as a shot")
	arsenal.toggle()
	journal.show_page("missions")
	check(not journal.shade.visible, "journal cannot overlap arsenal")
	arsenal.toggle()
	missions.import_state({"mission_index": 0, "progress": 2, "completed_count": 4})
	missions.mission_completed.connect(func(result: Dictionary): completions.append(result))
	var coins := progression.coins
	missions.record_sink()
	check(completions.size() == 1 and completions[0].coins == 180, "completion emits one actual reward event")
	check(progression.coins == coins + 180 and missions.mission_index == 1 and missions.progress == 0, "payout and next mission remain atomic")
	missions.record_sink()
	check(completions.size() == 1 and progression.coins == coins + 180, "wrong next event does not double pay")
	check(hud.recent_log[0].contains("180"), "completion reward visible in log")
	journal.show_page("missions")
	journal._refresh()
	check(journal.mission_rows[0].title.text.contains("Bergung"), "journal follows actual mission rotation")
	check(journal.completed.text.contains("5") and journal.completed.text.contains("180"), "journal shows lifetime count and session completion")
	var saved := missions.export_state()
	missions.import_state(saved)
	check(missions.completed_count == 5 and missions.last_completed.is_empty(), "legacy save retained; session receipt not replayed")
	journal.show_page("harbor")
	check(journal.dock_button.disabled, "cannot dock away from harbor")
	journal.dock()
	check(journal.shade.visible and not progression.shop_open, "unavailable dock action has no side effects")
	var port := PortInteraction.new()
	port.port_name = "Testhafen"
	port.spawn_position = Vector3(500, 0.55, 480)
	game.add_child(port)
	port._on_body_entered(player)
	journal._refresh()
	check(not journal.dock_button.disabled and journal.harbor_summary.text.contains("Testhafen"), "real nearby harbor enables docking")
	health.current_health = 100
	journal.dock()
	check(not journal.shade.visible and progression.shop_open and health.current_health == health.max_health, "dock delegates repair and existing shipyard")
	check(health.respawn_position == port.spawn_position, "dock assigns actual checkpoint")
	progression.shop_open = false
	journal.show_page("harbor")
	journal.supplies()
	check(arsenal.shade.visible and not journal.shade.visible, "supplies transfers to existing arsenal")
	arsenal.toggle()
	port._on_body_exited(player)
	port.queue_free()
	# Isolate ray selection from the sector's islands and other ships.
	player.position = Vector3(500, 0.55, 480)
	var enemy: ShipMotor = get_nodes_in_group("enemies")[0]
	enemy.position = Vector3(500, 0.55, 500)
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.global_position = Vector3(500, 12, 475)
	camera.look_at(enemy.global_position)
	await physics_frame
	await frames()
	var point := camera.unproject_position(enemy.global_position)
	check(targeting.pick_at(point, camera) == enemy, "ray selects direct hull")
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(12, 12, 2)
	collision.shape = shape
	wall.add_child(collision)
	game.add_child(wall)
	wall.global_position = camera.global_position.lerp(enemy.global_position, 0.5)
	await physics_frame
	await frames()
	check(targeting.pick_at(point, camera) == null, "foreground physical island/pier blocks selection behind it")
	wall.queue_free()
	await physics_frame
	await frames()
	check(targeting.pick_at(point, camera) == enemy, "selection works after occluder removed")
	journal.show_page("missions")
	health.is_sunk = true
	journal._process(0.3)
	check(not journal.shade.visible and not player.get_meta("journal_open", false), "sinking dismisses journal while world keeps running")
	health.is_sunk = false
	game.queue_free()
	await frames()
	await create_timer(0.25).timeout
	check(get_nodes_in_group("captain_journal").is_empty(), "journal lifetime bound to scene")
	print("M18_ENGINE_TESTS: %d/%d passed" % [checks - failures, checks])
	quit.call_deferred(0 if failures == 0 else 1)
