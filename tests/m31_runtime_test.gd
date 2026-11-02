extends SceneTree
var checks := 0
var failures: Array[String] = []
var game: Node

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label); print("FAIL: " + label)

func settle() -> void:
	for i in 12: await process_frame

func clear_shots() -> void:
	for shot in get_nodes_in_group("sector_projectiles"):
		shot.set_physics_process(false)
		shot.get_parent().remove_child(shot)
		shot.queue_free()

func run() -> void:
	var settings := ClientSettings.new()
	root.add_child(settings)
	settings.update_value("muted", true)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	var player := get_first_node_in_group("player") as ShipMotor
	player.set_physics_process(false)
	(player.get_node("PlayerInput") as PlayerShipInput).set_process(false)
	var world := get_first_node_in_group("world_map") as WorldMapSystem
	world.set_process(false)
	world.encounters.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	var progression := player.get_node("Progression") as PlayerProgression
	var inventory := player.get_node("Inventory") as PlayerInventory
	var voyage := player.get_node("Voyage") as VoyageProgress
	var weapons := player.get_node("Weapons") as ShipWeapons
	var missions := player.get_node("Missions") as MissionSystem
	var hud := get_first_node_in_group("hud") as GameHud
	check(not roster.choose_starter("chalupa"), "starter cannot be chosen twice")
	check(not voyage.can_enter(Vector2i(1, 0)), "Green Frontier initially locked")
	check(not voyage.auto_unlocked(), "AUTO initially locked")
	world._transition(Vector2i.RIGHT)
	check(world.current_sector == Vector2i.ZERO, "world border enforces trial gate")
	check(not voyage.start_trial(), "trial requires harbor and progression")
	# M32 starts small; use a migrated fleet fixture for the unchanged M31
	# per-design level/loadout regression below. New unlock rules have their own suite.
	roster.import_state({"owned_ship_ids": ["clipper", "barco_low"], "selected_ship_id": "clipper"})
	var port := PortInteraction.new()
	port.monitoring = false
	root.add_child(port)
	port.nearby_player = player
	player.set_meta("nearby_port", port)
	progression.level = 2
	progression.coins = 10000
	progression.shop_open = true
	check(progression.purchase_upgrade("hull"), "ship improvement at harbor")
	var old_level := roster.ship_level()
	roster.earn_ship_xp(150)
	check(roster.ship_level() == old_level + 1, "design gains own level")
	weapons.cannon_index = 2
	weapons.select_mode("harpoon")
	check(inventory.save_loadout("A", weapons), "save design A loadout")
	roster.preview_index = ShipCatalog.index_of("barco_low")
	check(roster.buy_or_equip_preview(), "equip migrated second design")
	check(roster.ship_level() == 1 and int(progression.upgrades.hull) == 0, "new design has independent level and upgrades")
	check(inventory.saved_loadouts.A.cannon == 1, "new design has independent A preset")
	weapons.cannon_index = 0
	weapons.select_mode("cannon")
	inventory.save_loadout("A", weapons)
	roster.preview_index = ShipCatalog.index_of("clipper")
	check(roster.buy_or_equip_preview(), "equip owned design")
	check(roster.ship_level() == 2 and int(progression.upgrades.hull) == 1, "original design progress restored")
	inventory.apply_loadout("A", weapons)
	check(weapons.cannon_index == 2 and weapons.weapon_mode == "harpoon", "original design preset restored")
	var ship_state := roster.export_state()
	var inventory_state := inventory.export_state()
	roster.import_state(ship_state)
	inventory.import_state(inventory_state)
	check(roster.export_state() == ship_state, "design state round-trip")
	check(inventory.export_state() == inventory_state, "per-design loadout round-trip")
	roster.earn_ship_xp(999999)
	check(roster.ship_level() == 10 and int(roster._record("clipper").xp) == 0, "design level cap 10")
	check(voyage.start_trial(), "trial starts after prerequisites")
	check(not voyage.start_trial(), "duplicate trial start rejected")
	check(not voyage.claim_trial(), "early trial claim rejected")
	for i in 3: missions.record_sink()
	for i in 2: missions.record_loot()
	port.activated_for_visit = false
	port.activate(player)
	port.activate(player)
	check(int(voyage.trial_counts.dock) == 1, "one dock credit per visit")
	check(voyage.claim_trial(), "completed trial claim")
	var coins_after := progression.coins
	check(not voyage.claim_trial() and progression.coins == coins_after, "no duplicate trial reward")
	check(voyage.can_enter(Vector2i(1, 0)) and voyage.auto_unlocked(), "trial unlocks map and AUTO")
	check(not voyage.can_enter(Vector2i(2, 0)), "later maps remain locked for new profiles")
	var voyage_state := voyage.export_state()
	voyage.import_state(voyage_state)
	check(voyage.trial_passed, "trial save restore")
	voyage.import_state({"trial_active": true})
	voyage.record("sink")
	voyage._on_sunk(player, null)
	check(not voyage.trial_active and int(voyage.trial_counts.sink) == 0, "sinking cancels trial attempt")
	voyage.import_state({}, true)
	check(voyage.can_enter(Vector2i(3, 2)), "legacy map access preserved")
	voyage.import_state(voyage_state)
	check(voyage.start_event(), "local hunt starts at harbor")
	check(not voyage.start_event(), "active event cannot restart")
	voyage.record("sink")
	voyage.record("loot")
	check(voyage.event_tokens == 15, "hunt token rewards")
	var repairs := inventory.count("repair")
	check(voyage.buy_event_repair() and inventory.count("repair") == repairs + 1 and voyage.event_tokens == 0, "event shop exact debit and reward")
	check(not voyage.buy_event_repair(), "insufficient tokens rejected")
	voyage._process(900)
	check(voyage.event_seconds == 0 and voyage.event_cooldown > 0, "event expires and cooldown remains")
	voyage.record("sink")
	check(voyage.event_tokens == 0, "no tokens after expiry")
	var now := int(Time.get_unix_time_from_system())
	var day := int(floor(float(now) / 86400.0))
	missions.day_index = day - 1
	missions.week_index = int(floor(float(day + 3) / 7.0)) - 1
	missions.daily_progress = MissionSystem.DAILY_GOALS.duplicate()
	missions.weekly_progress = MissionSystem.WEEKLY_GOALS.duplicate()
	missions.daily_claimed = true
	missions.weekly_claimed = true
	missions.sync_calendar(now)
	check(not missions.daily_claimed and missions.daily_progress.sink == 0, "UTC daily rollover")
	check(not missions.weekly_claimed and missions.weekly_progress.sink == 0, "Monday UTC weekly rollover")
	missions.daily_progress.sink = 2
	missions.sync_calendar(now - 8 * 86400)
	check(missions.daily_progress.sink == 2 and missions.day_index == day, "clock rollback cannot reset counters")
	missions.daily_progress = MissionSystem.DAILY_GOALS.duplicate()
	check(not missions.claim_daily().is_empty(), "daily reward available")
	coins_after = progression.coins
	check(missions.claim_daily().is_empty() and coins_after == progression.coins, "daily claim idempotent")
	var old_mission_state := {"daily_progress": {"sink": 2, "loot": 1, "dock": 0}, "weekly_progress": {}, "daily_claimed": true}
	missions.import_state(old_mission_state)
	check(missions.daily_progress.sink == 2 and missions.daily_claimed, "legacy counters anchor without reset")
	# Existing global upgrades migrate only to the selected design; no progress loss.
	progression.upgrades = {"hull": 4, "cannon": 2, "sails": 1}
	roster.import_state({"owned_ship_ids": ["clipper", "barco_low"], "selected_ship_id": "barco_low"})
	check(int(progression.upgrades.hull) == 4, "M30 selected ship upgrades retained")
	check(int(roster._record("clipper").upgrades.hull) == 0, "no duplicated legacy upgrades")
	inventory.import_state({"saved_loadouts": {"A": {"cannon": 2, "ammo": 1}}, "stock": {"iron": 777}})
	check(inventory.saved_loadouts.A.cannon == 2 and inventory.count("iron") == 777, "M30 inventory and presets retained")
	check(inventory.count("harpoon") == 40, "legacy harpoon starter stock")
	# Controlled combat fixture: no AI movement or random enemy attacks.
	progression.shop_open = false
	player.set_meta("in_safe_zone", false)
	player.position = Vector3(0, 0.55, 0)
	var enemy := ProceduralFactory.create_ship("M31Target", Vector3(8, 0.55, 0), Color.RED, false) as ShipMotor
	var health := ShipHealth.new()
	health.name = "Health"
	health.max_health = 100000
	enemy.add_child(health)
	game.add_child(enemy)
	enemy.set_physics_process(false)
	var targeting := player.get_node("Targeting") as TargetingSystem
	targeting.set_target(enemy)
	weapons.select_mode("cannon")
	weapons.cannon_index = 1
	weapons.ammo_index = 0
	weapons.last_shot_time = -99
	for heading in [0, 90, 180, 270]:
		player.rotation_degrees.y = heading
		check(weapons.attack_status() == "BEREIT", "attack independent of heading " + str(heading))
	weapons.toggle_auto_fire()
	check(weapons.auto_fire, "AUTO available after trial")
	weapons.auto_fire = false
	var initial_ammo := inventory.count("iron")
	check(weapons.fire_broadside(), "selected salvo fires")
	check(inventory.count("iron") == initial_ammo - inventory.volley_size(), "salvo consumes exact stock")
	check(not weapons.fire_broadside(), "reload prevents duplicate volley")
	var duration := weapons.last_reload_duration
	weapons.cannon_index = 0
	check(weapons.last_reload_duration == duration, "changing weapon does not shorten active reload")
	clear_shots()
	weapons.last_shot_time = -99
	enemy.set_meta("encounter_kind", "monster")
	check(weapons.attack_status() == "HARPUNE WÄHLEN", "monster requires harpoon")
	weapons.select_mode("harpoon")
	check(weapons.attack_status() == "BEREIT", "harpoon valid against monster")
	initial_ammo = inventory.count("harpoon")
	check(weapons.fire_broadside() and inventory.count("harpoon") == initial_ammo - 1, "harpoon consumes one")
	clear_shots()
	weapons.last_shot_time = -99
	enemy.set_meta("encounter_kind", "ship")
	check(weapons.attack_status() == "KANONE WÄHLEN", "harpoon rejected against ship")
	weapons.select_mode("cannon")
	enemy.position.x = 100
	check(weapons.attack_status() == "ZU WEIT", "range enforced")
	enemy.position.x = 8
	enemy.set_meta("in_safe_zone", true)
	check(not weapons.fire_broadside(), "safe target cannot be attacked")
	enemy.set_meta("in_safe_zone", false)
	targeting.set_target(null)
	check(not weapons.fire_broadside(false), "player cannot bypass target requirement")
	targeting.set_target(enemy)
	hud.open_menu("equipment")
	check(not weapons.fire_broadside(), "modal blocks attack")
	hud.close_menu()
	for page in ["progress", "equipment", "events", "shop", "quests"]:
		hud.open_menu(page)
		await settle()
		check(hud.command_deck.visible, "M31 page " + page)
	hud.close_menu()
	# Swept, target-bound hit; unrelated nearby ships must not receive damage.
	var shot := CannonProjectile.new()
	shot.render_visual = false
	shot.locked_target = enemy
	game.add_child(shot)
	shot.set_physics_process(false)
	shot.configure(player, Vector3(0, 0.85, 0), Vector3.RIGHT * 20, 100, 1.0)
	var hp := health.current_health
	shot._physics_process(0.5)
	check(shot.consumed and is_equal_approx(health.current_health, hp - 100), "swept target hit applies damage")
	await settle()
	for heading in [0, 90, 180, 270]:
		player.rotation_degrees.y = heading
		var aimed := CannonProjectile.new()
		aimed.render_visual = false
		aimed.locked_target = enemy
		game.add_child(aimed)
		aimed.set_physics_process(false)
		aimed.configure(player, player.global_position + Vector3.UP * 0.3, Vector3.RIGHT * 20, 100, 1.0)
		hp = health.current_health
		aimed._physics_process(0.5)
		check(is_equal_approx(health.current_health, hp - 100), "actual damage heading " + str(heading))
		await settle()
	var obstacle := StaticBody3D.new()
	var blocker := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1, 4, 4)
	blocker.shape = box
	obstacle.add_child(blocker)
	obstacle.position = Vector3(4, 0.8, 0)
	game.add_child(obstacle)
	await physics_frame
	var blocked := CannonProjectile.new()
	blocked.render_visual = false
	blocked.locked_target = enemy
	game.add_child(blocked)
	blocked.set_physics_process(false)
	blocked.configure(player, Vector3(0, 0.85, 0), Vector3.RIGHT * 20, 100, 1.0)
	hp = health.current_health
	blocked._physics_process(0.5)
	check(blocked.consumed and health.current_health == hp, "island collision blocks swept shot")
	obstacle.queue_free()
	await settle()
	# Full profile persistence writes only randomly named fixtures, never real saves.
	var state := game.get_node("GameState") as GameState
	var original_path := state.save_path
	var original_backup := state.backup_path
	state.save_path = "user://m31_profile_fixture_" + Crypto.new().generate_random_bytes(8).hex_encode() + ".json"
	state.backup_path = state.save_path + ".backup"
	root.set_meta("reconstruction_test_mode", false)
	check(state.save_now(), "full M31 profile write")
	check(state.save_now(), "full M31 backup write")
	root.set_meta("reconstruction_test_mode", true)
	var payload := state._read_valid_payload(state.save_path)
	check(payload.get("m31_version") == 1, "M31 save extension marker")
	check(payload.get("voyage", {}).get("trial_passed", false), "trial state in checksummed profile")
	check(payload.get("ship_roster", {}).has("designs"), "design records in checksummed profile")
	check(payload.get("inventory", {}).has("loadouts_by_ship"), "per-design equipment in profile")
	check(not state._read_valid_payload(state.backup_path).is_empty(), "backup validates")
	var legacy_payload := {"save_version": 1, "progression": {"coins": 1234, "level": 2}, "player": {"health": 333.5, "label": "spaces and \"quoted\" text"}}
	var legacy_envelope := {"payload": legacy_payload, "checksum": JSON.stringify(legacy_payload).sha256_text()}
	var legacy_text := JSON.stringify(legacy_envelope, "  ")
	state._write_text(state.save_path, legacy_text)
	check(state._read_valid_payload(state.save_path).get("progression", {}).get("coins", 0) == 1234, "legacy integer checksum validates without losing strings")
	state._write_text(state.save_path, legacy_text.replace("1234", "1337"))
	check(state._read_valid_payload(state.save_path).is_empty(), "modified legacy payload still rejected")
	var backup_bytes := FileAccess.get_file_as_string(state.backup_path)
	root.set_meta("reconstruction_test_mode", false)
	check(state.save_now(), "new save replaces invalid primary without copying it over good backup")
	root.set_meta("reconstruction_test_mode", true)
	check(FileAccess.get_file_as_string(state.backup_path) == backup_bytes, "good backup remains unchanged")
	state._loaded_payload = payload
	state._apply_loaded_state()
	check((player.get_node("Voyage") as VoyageProgress).trial_passed, "full profile application")
	state._loaded_payload = {"save_version": 1, "progression": {"level": 5, "coins": 1234, "upgrades": {"hull": 3}}, "ship_roster": {"owned_ship_ids": ["clipper", "chalupa"], "selected_ship_id": "chalupa"}, "world": {"sector": [2, 1]}, "player": {"position": [3, 0.55, 4]}, "missions": {}}
	state._apply_loaded_state()
	check(world.current_sector == Vector2i(2, 1) and voyage.legacy_access, "M30 map migration keeps existing access and location")
	check(roster.selected_ship_id == "chalupa" and int(progression.upgrades.hull) == 3 and progression.coins == 1234, "M30 profile migration preserves captain and selected ship")
	state.load_failed = true
	check(not state.save_now(), "unreadable save cannot be overwritten")
	state.load_failed = false
	for suffix in ["", ".backup", ".tmp"]:
		if FileAccess.file_exists(state.save_path + suffix): DirAccess.remove_absolute(state.save_path + suffix)
	state.save_path = original_path
	state.backup_path = original_backup
	await settle()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for type in ["AudioStreamPlayer", "AudioStreamPlayer3D"]:
		for audio in game.find_children("*", type, true, false): audio.stop()
	await create_timer(0.2).timeout
	game.queue_free()
	port.queue_free()
	settings.queue_free()
	await settle()
	print(JSON.stringify({"suite": "M31", "checks": checks, "failures": failures, "engine": Engine.get_version_info().string}))
	quit(0 if failures.is_empty() else 1)
