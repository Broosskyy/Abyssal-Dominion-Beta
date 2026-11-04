extends SceneTree

var failures := 0
var checks := 0


func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()


func _run() -> void:
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	var world := scene.get_node("WorldMapSystem") as WorldMapSystem
	var director := world.encounters
	var player := world.player
	world.set_process(false)
	director.set_process(false)
	player.set_physics_process(false)
	player.get_node("PlayerInput").set_process(false)
	director._process(0.2)
	_check(director.active_slots.size() == 4, "four initial NPC slots")
	for asset in ["tropical_island_04", "tropical_island_01", "snow_island_02"]:
		_check(load("res://assets/recovered_test/m8/islands/%s_coast.obj" % asset) is Mesh, "coast mesh loads: " + asset)
	var port: Node = get_first_node_in_group("ports")
	_check(port != null and port.has_node("RecoveredWoodenPier"), "recovered pier attached")
	_check(port != null and port.has_node("RecoveredLighthouse"), "recovered lighthouse attached")
	_check(is_instance_valid((player.get_node("PlayerInput") as PlayerShipInput).navigation_marker), "navigation marker created")
	var progression := player.get_node("Progression") as PlayerProgression
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	progression.coins = 2000
	progression.shop_open = true
	roster.preview_index = 1
	_check(roster.buy_or_equip_preview(), "M9 Barco purchase")
	_check(progression.coins == 1400 and roster.selected_ship_id == "barco_low", "M9 price and selection")
	_check(is_equal_approx(player.cruise_speed, 8.2), "M9 ship speed applied")
	roster.buy_or_equip_preview()
	_check(progression.coins == 1400, "M9 owned ship is not charged twice")
	roster.preview_index = 2
	_check(roster.buy_or_equip_preview() and progression.coins == 200, "M9 Chalupa purchase")
	_check(player.has_node("RecoveredVisual_chalupa"), "M9 live mesh swap")
	roster.preview_index = 0
	roster.buy_or_equip_preview()
	progression.shop_open = false
	_check(not roster.buy_or_equip_preview(), "M9 selection blocked at sea")
	var victim := director.active_slots[0] as ShipMotor
	var health := victim.get_node("Health") as ShipHealth
	var xp_before := progression.xp
	var expected_xp: int = int(victim.get_meta("encounter_profile").xp)
	health.apply_damage(100000.0, player)
	health.apply_damage(100000.0, player)
	_check(progression.xp == xp_before + expected_xp, "one reward for duplicate lethal hits")
	_check(health.is_sunk and not health.auto_respawn, "director owns NPC respawn")
	_check(not victim.is_physics_processing(), "sink animation not overwritten by motor")
	_check(director.pending_slots.size() == 1, "one replacement scheduled")
	director._process(0.1)
	_check(director.active_slots.size() == 3, "replacement not immediate")
	for index in range(3):
		director._process(11.0)
		victim = director.active_slots[0] as ShipMotor
		(victim.get_node("Health") as ShipHealth).apply_damage(100000.0, player)
	director._process(0.2)
	_check(is_instance_valid(director.admiral_ship), "admiral at four tropical kills")
	var first_admiral := director.admiral_ship
	director._process(0.2)
	_check(director.admiral_ship == first_admiral, "admiral cannot duplicate")
	(first_admiral.get_node("Health") as ShipHealth).apply_damage(100000.0, player)
	_check(int(director.sector_states["0,0"].kills) == 0, "admiral resets counter")
	_check(float(director.sector_states["0,0"].cooldown) == 45.0, "admiral cooldown")
	var restored := EncounterDirector.new()
	restored.import_state(director.export_state())
	_check(restored.export_state()["0,0"] == director.export_state()["0,0"], "encounter save roundtrip")
	restored.free()
	await process_frame
	var old_content := world.sector_content
	world.restore_sector(Vector2i(1, 0))
	_check(not old_content.is_inside_tree(), "old sector immediately detached")
	director._process(0.2)
	_check(director.pending_slots.is_empty(), "new sector has no old respawn timers")
	for y in range(3):
		for x in range(4):
			world.restore_sector(Vector2i(x, y))
			director._process(0.2)
			_check(director.active_slots.size() == 4, "population in sector %d,%d" % [x, y])
			for ship in director.active_slots.values():
				_check(_spawn_is_clear(ship, director), "spawn clearance in sector %d,%d" % [x, y])
			await process_frame
	print("M10_ENGINE_TESTS: %d/%d passed" % [checks - failures, checks])
	_stop_audio(scene)
	await create_timer(0.25).timeout
	scene.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit(0 if failures == 0 else 1)


func _stop_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
		node.stop()
		node.stream = null
	for child in node.get_children():
		_stop_audio(child)


func _spawn_is_clear(ship: ShipMotor, director: EncounterDirector) -> bool:
	for node in director.content.get_children():
		if node == ship:
			continue
		var minimum := 0.0
		var position: Vector3 = node.position if node is Node3D else Vector3.ZERO
		if node.is_in_group("islands"):
			minimum = float(node.get_meta("island_radius")) + 4.5
		elif node.is_in_group("ports"):
			position += Vector3(0.0, 0.0, 5.0)
			minimum = 15.0
		elif node.is_in_group("ships"):
			minimum = 9.0
		if director._flat_distance(ship.position, position) < minimum:
			return false
	return director._flat_distance(ship.position, director.player.position) >= 12.0


func _check(condition: bool, title: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + title)
