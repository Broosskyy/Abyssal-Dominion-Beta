extends SceneTree

var checks := 0
var failures := 0
var metrics := {}

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _check(value: bool, title: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: " + title)

func _frames() -> void:
	for i in 4:
		await process_frame

func _run() -> void:
	var old := ClientSettings.validate({"volume": 0.42, "quality": "low", "muted": true, "map_transition": false})
	_check(old.volume == 0.42 and old.quality == "low" and old.muted, "M14 preferences retained")
	_check(not old.only_own_damage and not old.single_visual_ball and old.effect_texts, "new defaults filled without migration write")
	_check(ClientSettings.validate({"single_visual_ball": "yes"}).single_visual_ball == false, "boolean validation")
	var settings := ClientSettings.new()
	root.add_child(settings)
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await _frames()
	var world: WorldMapSystem = game.get_node("WorldMapSystem")
	world.set_process(false)
	world.encounters.set_process(false)
	for ship in get_nodes_in_group("ships"):
		ship.set_physics_process(false)
		for node in ship.get_children():
			if node is EnemyShipAI or node is PlayerShipInput:
				node.set_process(false)
	var player: ShipMotor = world.player
	var enemy: ShipMotor = get_nodes_in_group("enemies")[0]
	player.set_meta("in_safe_zone", false)
	enemy.set_meta("in_safe_zone", false)
	var health: ShipHealth = enemy.get_node("Health")
	var feedback: CombatFeedback = game.get_node("CombatFeedback")
	feedback.set_process(false)
	feedback.clear()
	health.current_health = 1000
	health.armor = 0.2
	health.apply_damage(100, player, 0.0, 0.0)
	_check(is_equal_approx(health.current_health, 920), "armor gameplay unchanged")
	_check(feedback.entries.size() == 1 and is_equal_approx(feedback.entries[0].amount, 80), "feedback uses actual health loss")
	health.apply_damage(100, player)
	_check(feedback.entries.size() == 1 and is_equal_approx(feedback.entries[0].amount, 160), "rapid broadside hits merged")
	health.apply_damage(100, player, 0.0, 0.3, true)
	_check(feedback.entries.size() == 2, "critical separated from normal")
	_check(feedback.display_entries()[1].text.contains("KRIT") and feedback.display_entries()[1].text.contains("LANGSAM"), "actual critical and slow descriptors")
	settings.update_value("effect_texts", false)
	_check(not feedback.display_entries()[1].text.contains("KRIT") and feedback.display_entries()[1].text.begins_with("−"), "effects off keeps numeric damage")
	feedback.record_hit(player, enemy, 20, false)
	_check(feedback.entries.size() == 3, "incoming damage recorded by default")
	settings.update_value("only_own_damage", true)
	_check(feedback.display_entries().size() == 2, "own filter applies to existing records")
	feedback.record_hit(player, enemy, 20, false)
	_check(feedback.entries.size() == 3, "own filter suppresses new incoming records")
	feedback.clear()
	enemy.set_meta("in_safe_zone", true)
	health.apply_damage(100, player)
	_check(feedback.entries.is_empty(), "protected hit has no fake damage text")
	enemy.set_meta("in_safe_zone", false)
	health.apply_damage(0, player)
	_check(feedback.entries.is_empty(), "zero damage ignored")
	feedback.record_hit(null, player, 100, false)
	feedback.record_hit(enemy, player, NAN, false)
	_check(feedback.entries.is_empty(), "invalid event rejected")
	for index in 80:
		feedback.record_hit(enemy, player, 1, false)
		feedback._process(0.13)
	_check(feedback.entries.size() <= CombatFeedback.DESKTOP_LIMIT, "desktop event buffer bounded")
	feedback._process(2.0)
	_check(feedback.entries.is_empty(), "expired events removed")
	root.set_meta("touch_ui", true)
	# Alternating target IDs force distinct events without waiting for expiry.
	var targets: Array[Node3D] = []
	for index in 40:
		var target := Node3D.new()
		game.add_child(target)
		targets.append(target)
		feedback.record_hit(target, player, 1, false)
	_check(feedback.entries.size() == CombatFeedback.MOBILE_LIMIT, "mobile hard event cap")
	for target in targets:
		target.queue_free()
	await _frames()
	_check(feedback.display_entries().size() == CombatFeedback.MOBILE_LIMIT, "victim deletion does not invalidate snapshots")
	root.set_meta("touch_ui", false)
	var safe := Rect2(0, 0, 844, 390)
	var occupied: Array[Rect2] = [Rect2(300, 140, 160, 42)]
	var rect := CombatFeedback.place_label(Vector2(380, 200), Vector2(100, 26), safe, occupied)
	_check(rect.has_area() and safe.encloses(rect) and not rect.intersects(occupied[0]), "feedback avoids nameplate rectangle")
	_check(not CombatFeedback.place_label(Vector2(-5, 100), Vector2(100, 26), safe, []).has_area(), "offscreen feedback culled")
	_check(not CombatFeedback.place_label(Vector2(380, 200), Vector2(100, 26), safe, [safe]).has_area(), "blocked feedback hidden not stacked")
	var snapshots := []
	var weapons: ShipWeapons = player.get_node("Weapons")
	var inventory: PlayerInventory = player.get_node("Inventory")
	for reduced in [false, true]:
		settings.update_value("single_visual_ball", reduced)
		weapons.last_shot_time = -99
		health.current_health = 10000
		seed(150015)
		var before := inventory.count("iron")
		_check(weapons.fire_broadside(), "broadside fires " + str(reduced))
		var balls := get_nodes_in_group("sector_projectiles")
		var visible_count := 0
		var rows := []
		for ball: CannonProjectile in balls:
			ball.set_physics_process(false)
			if ball.render_visual:
				visible_count += 1
			_check(ball.find_children("*", "CollisionShape3D", true, false).size() == 1, "every logical ball retains collision")
			_check(ball.find_children("*", "MeshInstance3D", true, false).size() == (2 if ball.render_visual else 0), "invisible balls allocate no visual meshes")
			rows.append([ball.damage, ball.travel_velocity, ball.global_position, ball.critical_hit])
			ball._on_body_entered(enemy)
		var result := {"rows": rows, "ammo": before - inventory.count("iron"), "loss": 10000 - health.current_health}
		snapshots.append(result)
		_check(visible_count == (1 if reduced else inventory.volley_size()), "visible volley count")
		metrics["reduced" if reduced else "full"] = {"logical_balls": balls.size(), "visible_balls": visible_count, "ammo": result.ammo, "damage": result.loss}
		await _frames()
	_check(snapshots[0] == snapshots[1], "identical seeded damage, crits, velocity, origin and ammo")
	feedback.record_hit(enemy, player, 10, false)
	world._transition(Vector2i.RIGHT)
	_check(feedback.entries.is_empty(), "sector switch clears old feedback")
	await _frames()
	var fleet := Node3D.new()
	game.add_child(fleet)
	for index in 20:
		var ship := Node3D.new()
		fleet.add_child(ship)
		ship.add_child(ReferenceVisualAdapter.new())
	await _frames()
	var meshes := fleet.find_children("*", "MeshInstance3D", true, false)
	var materials := {}
	for mesh: MeshInstance3D in meshes:
		materials[mesh.material_override.get_instance_id()] = true
	metrics["clipper_fleet"] = {"ships": 20, "mesh_instances": meshes.size(), "unique_materials": materials.size()}
	_check(meshes.size() == 120, "20 intact six-part Clipper assemblies")
	_check(materials.size() == 4, "M16 fleet reuses four material profiles including distinct dark flags")
	var front := RecoveredMaterialCache.surface("", "", Color.WHITE, 0.6, false)
	var back := RecoveredMaterialCache.surface("", "", Color.WHITE, 0.6, true)
	_check(front != back and back.cull_mode == BaseMaterial3D.CULL_DISABLED, "cache separates double-sided sails")
	_check(RecoveredMaterialCache.coast() == RecoveredMaterialCache.coast(), "coast shader material shared")
	for index in 110:
		RecoveredMaterialCache.surface("", "", Color(float(index) / 110, 0.2, 0.3), 0.7)
	_check(RecoveredMaterialCache.count() <= RecoveredMaterialCache.LIMIT, "material cache bounded")
	_check(is_instance_valid(meshes[0].material_override), "eviction keeps in-use materials alive")
	game.queue_free()
	await _frames()
	_check(get_nodes_in_group("combat_feedback").is_empty(), "leaving game removes feedback service")
	settings.queue_free()
	await _frames()
	# Headless process_frame can run faster than audio worker cleanup in real time.
	# Allow teardown to settle before the process-wide resource leak check at exit.
	await create_timer(0.2).timeout
	var report := FileAccess.open("res://docs/m15_presentation_metrics.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"mode": "headless; counts and behavior, not FPS or visual QA", "metrics": metrics}, "\t"))
	report.close()
	print("M15_ENGINE_TESTS: %d/%d passed" % [checks - failures, checks])
	quit.call_deferred(0 if failures == 0 else 1)
