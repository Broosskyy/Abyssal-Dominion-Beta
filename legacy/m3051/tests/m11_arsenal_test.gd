extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: " + label)


func _run() -> void:
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	var world := scene.get_node("WorldMapSystem") as WorldMapSystem
	var ship := world.player
	world.set_process(false)
	world.encounters.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.get_node("EnemyAI").set_process(false)
	ship.set_physics_process(false)
	var input_node := ship.get_node("PlayerInput") as PlayerShipInput
	input_node.set_process(false)
	var inventory := ship.get_node("Inventory") as PlayerInventory
	var progression := ship.get_node("Progression") as PlayerProgression
	var roster := ship.get_node("ShipRoster") as PlayerShipRoster
	var weapons := ship.get_node("Weapons") as ShipWeapons
	var health := ship.get_node("Health") as ShipHealth
	var ui := scene.get_node("HUDLayer/ArsenalPanel") as ArsenalPanel
	var state := scene.get_node("GameState") as GameState
	ship.set_meta("in_safe_zone", false)
	_check(inventory.count("iron") == 120 and inventory.volley_size() == 3, "starting supplies and capacity")
	_check(not inventory.consume("unknown") and not inventory.consume("iron", -1), "invalid consumption rejected")
	_check(not inventory.purchase("iron"), "at-sea purchase denied")
	_check(not inventory.purchase_cannon() and not inventory.purchase_deck(), "at-sea equipment denied")
	var stamp := weapons.last_shot_time
	ship.set_meta("in_safe_zone", true)
	_check(not weapons.fire_broadside(), "safe-zone firing blocked")
	_check(weapons.last_shot_time == stamp and inventory.count("iron") == 120, "blocked shot spends nothing")
	ship.set_meta("in_safe_zone", false)
	ui.toggle()
	_check(ui.shade.visible and ship.get_meta("inventory_open"), "arsenal opens")
	_check(not input_node.has_navigation_target and ship.current_speed == 0, "arsenal stops navigation")
	_check(not weapons.fire_broadside(), "modal firing blocked")
	input_node.use_speed_ability()
	_check(inventory.count("boost") == 3, "modal blocks consumable hotkey")
	_check(ui.rows.iron.buy.disabled, "at-sea buy button disabled")
	var hud := scene.get_node("HUDLayer/GameHUD") as GameHud
	hud.toggle_global_map()
	_check(not hud.global_map_open, "map cannot overlap arsenal")
	ui.toggle()
	_check(not ship.get_meta("inventory_open"), "arsenal closes")
	health.is_sunk = true
	_check(not weapons.fire_broadside(), "sunk firing blocked")
	input_node.use_speed_ability()
	input_node.use_repair()
	_check(inventory.count("boost") == 3 and inventory.count("repair") == 3, "sunk consumables preserved")
	health.is_sunk = false
	progression.shop_open = true
	_check(not weapons.fire_broadside(), "shipyard firing blocked")
	progression.shop_open = false
	var before := get_nodes_in_group("sector_projectiles").size()
	_check(weapons.fire_broadside(), "first broadside succeeds")
	_check(inventory.count("iron") == 117, "three rounds consumed")
	_check(get_nodes_in_group("sector_projectiles").size() == before + 3, "three actual projectiles created")
	_check(not weapons.fire_broadside() and inventory.count("iron") == 117, "cooldown cannot spend ammo twice")
	inventory.set_count("iron", 2)
	weapons.last_shot_time = -99
	_check(not weapons.fire_broadside(), "insufficient volley rejected")
	_check(inventory.count("iron") == 2 and weapons.last_shot_time == -99, "failed volley is atomic")
	var port := PortInteraction.new()
	scene.add_child(port)
	port.nearby_player = ship
	ship.set_meta("nearby_port", port)
	progression.coins = 2000
	_check(inventory.purchase("iron") and inventory.count("iron") == 62, "harbor ammunition purchase")
	_check(progression.coins == 1970, "exact ammunition price")
	_check(inventory.purchase_cannon() and inventory.owned_cannons == 4, "cannon ownership")
	_check(inventory.volley_size() == 3, "deck limits owned cannons")
	_check(inventory.purchase_deck() and inventory.volley_size() == 4, "deck unlocks fourth cannon")
	_check(progression.coins == 1640, "equipment costs applied")
	before = get_nodes_in_group("sector_projectiles").size()
	_check(weapons.fire_broadside(), "upgraded broadside succeeds")
	_check(get_nodes_in_group("sector_projectiles").size() == before + 4 and inventory.count("iron") == 58, "four projectiles and four rounds")
	progression.shop_open = true
	roster.preview_index = 1
	_check(roster.buy_or_equip_preview(), "switch to purchased Barco")
	_check(inventory.deck_level() == 0 and inventory.volley_size() == 3, "decks belong to each hull")
	roster.preview_index = 0
	roster.buy_or_equip_preview()
	_check(inventory.deck_level() == 1 and inventory.volley_size() == 4, "returning hull retains deck")
	progression.shop_open = false
	progression.coins = 0
	var snapshot := inventory.export_state()
	_check(not inventory.purchase("boost") and not inventory.purchase_cannon() and not inventory.purchase_deck(), "no-money transactions denied")
	_check(inventory.export_state() == snapshot, "failed purchases preserve inventory")
	progression.coins = 5000
	inventory.set_count("iron", PlayerInventory.MAX_STOCK)
	_check(not inventory.purchase("iron") and progression.coins == 5000, "full stock does not charge")
	port.nearby_player = null
	_check(not inventory.at_port() and not inventory.purchase("boost"), "stale nearby-port metadata rejected")
	port.nearby_player = ship
	health.current_health = health.max_health
	input_node.use_repair()
	_check(inventory.count("repair") == 3, "full hull does not waste repair")
	health.current_health -= 300
	input_node.use_repair()
	_check(inventory.count("repair") == 2 and is_equal_approx(health.current_health, health.max_health - 60), "repair heals and consumes once")
	state._dirty = false
	input_node.use_speed_ability()
	_check(inventory.count("boost") == 2 and state._dirty, "boost consumed and save marked dirty")
	_check(is_equal_approx(ship.effective_speed(), ship.cruise_speed * 1.45), "boost effective speed")
	input_node.use_speed_ability()
	_check(inventory.count("boost") == 2, "boost cooldown prevents repeat charge")
	ship.add_speed_effect("chain_slow", 0.72, 2.5)
	ship.add_speed_effect("chain_slow", 0.72, 2.5)
	_check(is_equal_approx(ship.effective_speed(), ship.cruise_speed * 1.45 * 0.72), "chain slow refreshes without multiplicative stacking")
	ship.cruise_speed = 10
	ship.tick_speed_effects(4.0)
	_check(is_equal_approx(ship.effective_speed(), 10), "effect expiry preserves upgraded base")
	inventory.set_count("repair", 8)
	inventory.set_count("iron", 0)
	inventory.resupply_basics()
	_check(inventory.count("repair") == 8 and inventory.count("iron") == 120, "resupply preserves purchased repair surplus")
	snapshot = inventory.export_state()
	inventory.import_state(snapshot)
	_check(snapshot == inventory.export_state(), "inventory save roundtrip")
	inventory.import_state({"stock": {"iron": -4, "repair": "bad", "boost": 1e25}, "owned_cannons": 900, "deck_levels": {"clipper": 999, "invalid": 5}})
	_check(inventory.count("iron") == 0 and inventory.count("repair") == 3 and inventory.count("boost") == 9999, "corrupt stock sanitized")
	_check(inventory.owned_cannons == 6 and inventory.deck_level() == 3 and not inventory.deck_levels.has("invalid"), "corrupt equipment sanitized")
	inventory.import_state({"stock": [], "deck_levels": "bad", "owned_cannons": null})
	_check(inventory.count("iron") == 120 and inventory.owned_cannons == 3, "wrong save types safely default")
	state._loaded_payload = {"player": {"repair_charges": 1}}
	state._apply_loaded_state()
	_check(inventory.count("repair") == 1, "M10 repair-count migration")
	state._loaded_payload = {"inventory": {"stock": {"repair": 9, "iron": 44}}}
	state._apply_loaded_state()
	_check(inventory.count("repair") == 9 and inventory.count("iron") == 44, "M11 inventory overrides legacy repair field")
	ui.toggle()
	ui._select_ammo("explosive")
	_check(weapons.ammo_index == 1 and ui.rows.explosive.select.text == "Selected", "UI ammo selection updates weapons")
	for id in ["iron", "explosive", "repair", "boost", "cannon", "deck", "shield", "gunpowder"]:
		_check(load(ArsenalPanel.ICON_ROOT + id + ".png") is Texture2D, "original icon imports: " + id)
	for viewport_size in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = viewport_size
		await process_frame
		await process_frame
		ui._layout()
		await process_frame
		var bounds := ui.panel.get_global_rect()
		var safe := ui._safe_rect()
		_check(bounds.position.x >= safe.position.x and bounds.end.x <= safe.end.x + 1.0, "arsenal fits viewport width: " + str(viewport_size))
		_check(bounds.position.y >= safe.position.y and bounds.end.y <= safe.end.y + 1.0, "arsenal fits viewport height: " + str(viewport_size))
	ui.toggle()
	print("M11_ENGINE_TESTS: %d/%d passed" % [checks - failures, checks])
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
