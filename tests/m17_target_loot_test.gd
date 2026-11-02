extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func check(value: bool, title: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: " + title)

func frames() -> void:
	for i in 5: await process_frame

func _run() -> void:
	for size in [Vector2(844, 390), Vector2(390, 844), Vector2(1280, 720)]:
		var safe := Rect2(Vector2(16, 10), size)
		var layout := NauticalLayout.calculate(safe)
		check(safe.encloses(layout.target_info), "target information inside inset safe area")
		for action: Rect2 in layout.actions.values():
			check(not action.intersects(layout.target_info), "target information avoids all action buttons")
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
			if child is EnemyShipAI or child is PlayerShipInput or child is ShipWeapons:
				child.set_process(false)
	var player := world.player
	var weapons: ShipWeapons = player.get_node("Weapons")
	var targeting: TargetingSystem = player.get_node("Targeting")
	var input: PlayerShipInput = player.get_node("PlayerInput")
	var inventory: PlayerInventory = player.get_node("Inventory")
	var health: ShipHealth = player.get_node("Health")
	var progression: PlayerProgression = player.get_node("Progression")
	var hud: GameHud = game.get_node("HUDLayer/GameHUD")
	var enemy: ShipMotor = get_nodes_in_group("enemies")[0]
	player.set_meta("in_safe_zone", false)
	enemy.set_meta("in_safe_zone", false)
	player.position = Vector3(0, 0.55, 0)
	enemy.position = Vector3(15, 0.55, 3)
	inventory.set_count("iron", 60)
	var stock := inventory.count("iron")
	weapons.toggle_auto_fire()
	weapons._process(0.2)
	check(not weapons.auto_fire and stock == inventory.count("iron"), "no target never arms or spends")
	targeting.set_target(player)
	check(targeting.target == null, "own ship cannot be selected as hostile")
	targeting.set_target(enemy)
	check(weapons.attack_status() == "BEREIT", "valid in-range target ready")
	var camera := root.get_camera_3d()
	camera.global_position = Vector3(0, 35, -30)
	camera.look_at(Vector3.ZERO)
	var point := camera.unproject_position(enemy.global_position + Vector3.UP)
	targeting.set_target(null)
	input.cancel_navigation()
	input._set_navigation_target(point)
	check(targeting.target == enemy and not input.has_navigation_target, "ship tap selects without sail command")
	targeting.set_target(null)
	var touch := InputEventScreenTouch.new()
	touch.index = 9
	touch.position = point
	touch.pressed = true
	input._unhandled_input(touch)
	touch = touch.duplicate()
	touch.pressed = false
	input._unhandled_input(touch)
	check(targeting.target == enemy and not input.has_navigation_target, "real touch routing selects target")
	weapons.toggle_auto_fire()
	weapons._process(0.1)
	check(weapons.auto_fire and inventory.count("iron") == stock - inventory.volley_size(), "auto fires real volley with real cost")
	var balls := get_nodes_in_group("sector_projectiles")
	check(balls.size() == inventory.volley_size(), "auto uses normal logical projectile count")
	for ball: CannonProjectile in balls:
		ball.set_physics_process(false)
		var expected := enemy.global_position - ball.global_position
		expected.y = 0
		check(ball.travel_velocity.normalized().dot(expected.normalized()) > 0.99, "aim points to selected ship")
		ball.queue_free()
	var after := inventory.count("iron")
	weapons._process(0.1)
	check(inventory.count("iron") == after, "reload prevents extra ammo consumption")
	enemy.position.x = 200
	weapons.last_shot_time = -99
	weapons._process(0.1)
	check(weapons.auto_fire and weapons.attack_status() == "ZU WEIT" and inventory.count("iron") == after, "range pause retains explicit lock without spending")
	enemy.position.x = 15
	enemy.set_meta("in_safe_zone", true)
	weapons._process(0.1)
	check(not weapons.auto_fire and inventory.count("iron") == after, "protected target disarms auto")
	enemy.set_meta("in_safe_zone", false)
	weapons.toggle_auto_fire()
	player.set_meta("in_safe_zone", true)
	weapons._process(0.1)
	check(not weapons.auto_fire and inventory.count("iron") == after, "own harbor disarms auto")
	player.set_meta("in_safe_zone", false)
	weapons.toggle_auto_fire()
	player.set_meta("inventory_open", true)
	weapons._process(0.1)
	check(not weapons.auto_fire, "arsenal disarms auto")
	player.set_meta("inventory_open", false)
	weapons.toggle_auto_fire()
	progression.shop_open = true
	weapons._process(0.1)
	check(not weapons.auto_fire, "shipyard disarms auto")
	progression.shop_open = false
	weapons.toggle_auto_fire()
	weapons.toggle_auto_fire()
	check(not weapons.auto_fire, "explicit second toggle stops auto")
	weapons.toggle_auto_fire()
	hud.toggle_global_map()
	check(not weapons.auto_fire, "map cancels auto immediately")
	hud.toggle_global_map()
	inventory.set_count("iron", 0)
	weapons.toggle_auto_fire()
	check(not weapons.auto_fire and weapons.attack_status() == "MUNITION LEER", "empty ammo cannot arm")
	inventory.set_count("iron", 60)
	weapons.toggle_auto_fire()
	var enemy_health: ShipHealth = enemy.get_node("Health")
	enemy_health.is_sunk = true
	targeting._process(0)
	check(targeting.target == null and not weapons.auto_fire, "sinking clears lock and auto")
	enemy_health.is_sunk = false
	targeting.set_target(enemy)
	weapons.toggle_auto_fire()
	enemy.queue_free()
	await frames()
	weapons._process(0)
	check(weapons.selected_target() == null and not weapons.auto_fire, "deleted target safely clears")
	var pickup := LootPickup.new()
	pickup.amount = 37
	game.add_child(pickup)
	pickup.position = Vector3(40, 0.9, 40)
	var before_coins := progression.coins
	check(pickup.is_in_group("loot") and pickup.has_node("LootVisual"), "chest has native visual and minimap membership")
	pickup._on_body_entered(player)
	pickup._on_body_entered(player)
	check(progression.coins == before_coins + 37, "duplicate contact grants coins only once")
	check(hud.recent_log[0].contains("37"), "loot log reports granted coins")
	var repair := LootPickup.new()
	repair.loot_type = "repair"
	repair.amount = 300
	game.add_child(repair)
	repair.position = Vector3(40, 0.9, 40)
	health.current_health = health.max_health - 50
	repair._on_body_entered(player)
	check(is_equal_approx(health.current_health, health.max_health), "repair clamps to max hull")
	check(hud.recent_log[0].contains("50"), "repair log reports actual health gain not nominal amount")
	var a := LootPickup.new()
	var b := LootPickup.new()
	game.add_child(a)
	game.add_child(b)
	var ma := a.get_node("LootVisual").get_child(0) as MeshInstance3D
	var mb := b.get_node("LootVisual").get_child(0) as MeshInstance3D
	check(ma.mesh == mb.mesh and ma.material_override == mb.material_override, "loot shares meshes and materials")
	a._process(46)
	check(a.is_queued_for_deletion(), "expired loot despawns")
	game.queue_free()
	await frames()
	await create_timer(0.25).timeout
	check(get_nodes_in_group("loot").is_empty(), "scene teardown removes loot")
	print("M17_ENGINE_TESTS: %d/%d passed" % [checks - failures, checks])
	quit.call_deferred(0 if failures == 0 else 1)
