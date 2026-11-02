extends SceneTree
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label); print("FAIL: " + label)

func settle() -> void:
	for i in 12: await process_frame

func run() -> void:
	var settings := ClientSettings.new()
	root.add_child(settings)
	settings.update_value("muted", true)
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	var player := get_first_node_in_group("player") as ShipMotor
	player.set_physics_process(false)
	(player.get_node("PlayerInput") as PlayerShipInput).set_process(false)
	var world := get_first_node_in_group("world_map") as WorldMapSystem
	world.set_process(false)
	world.encounters.set_process(false)
	for enemy in get_nodes_in_group("enemies"): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	var progress := player.get_node("Progression") as PlayerProgression
	var voyage := player.get_node("Voyage") as VoyageProgress
	var inventory := player.get_node("Inventory") as PlayerInventory
	var weapons := player.get_node("Weapons") as ShipWeapons
	var state := game.get_node("GameState") as GameState
	var health := player.get_node("Health") as ShipHealth
	check(roster.selected_ship_id == "barco_low" and roster.owned_ship_ids == ["barco_low"], "fresh game owns only small ship")
	check(roster.starter_chosen, "fresh start initialized once")
	check(not roster.choose_starter("clipper") and not roster.choose_starter("chalupa"), "no larger starter selection")
	check(HomeSummary.from_save({}).ship_id == "barco_low", "fresh home preview is small")
	check(voyage.map_level() == 1 and not voyage.auto_unlocked(), "fresh map tier and AUTO")
	check(not voyage.can_enter(Vector2i(-1, 0)), "invalid sector blocked")
	var port := PortInteraction.new()
	root.add_child(port)
	port.monitoring = false
	port.nearby_player = player
	player.set_meta("nearby_port", port)
	progress.shop_open = true
	progress.coins = 1000000
	progress.level = 99
	roster.earn_ship_xp(100000)
	for id in ["clipper", "chalupa"]:
		roster.preview_index = ShipCatalog.index_of(id)
		var before := progress.coins
		check(not roster.buy_or_equip_preview(), "gold cannot bypass starter unlock " + id)
		check(progress.coins == before and not roster.owns_ship(id), "locked purchase has no mutation " + id)
		check(roster.preview_status() == BeginnerRules.unlock_text(id), "shipyard explains unlock " + id)
	check(voyage.map_level() == 1 and roster.owned_ship_ids.size() == 1, "pirate XP and ship XP do not advance map or fleet")
	progress.level = 1
	progress.upgrades = {"hull": 0, "cannon": 0, "sails": 0}
	health.is_sunk = true
	check(not voyage.start_trial(), "sunk ship cannot start assignment")
	health.is_sunk = false
	check(voyage.start_trial(), "first assignment available without pirate-level gate")
	check(not voyage.start_trial() and not voyage.claim_trial(), "duplicate start and early claim blocked")
	voyage.record("dock")
	check(voyage.trial_counts.dock == 0, "docking before objectives is not return credit")
	voyage.record("sink")
	voyage._on_sunk(player, null)
	check(not voyage.trial_active and voyage.trial_counts.sink == 0 and voyage.completed_trials == 0, "sinking resets attempt not completed progression")
	# Exercise every beginner tier, reward, lock and save round-trip.
	var sectors := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(1, 1)]
	for tier in range(1, 6):
		check(voyage.map_level() == tier, "sequential tier " + str(tier))
		for sector in WorldMapSystem.SECTORS:
			check(voyage.can_enter(sector) == (int(WorldMapSystem.SECTORS[sector].level) <= tier), "gate " + str(tier) + "/" + str(sector))
		check(voyage.start_trial(), "start tier " + str(tier))
		world.current_sector = Vector2i(2, 1) # Wrong tier: no grinding easy/other maps.
		voyage.record("sink")
		voyage.record("loot")
		check(voyage.trial_counts.sink == 0 and voyage.trial_counts.loot == 0, "wrong map does not count " + str(tier))
		world.current_sector = sectors[tier - 1]
		for i in 3: voyage.record("sink")
		for i in 2: voyage.record("loot")
		check(not voyage.trial_ready(), "return required " + str(tier))
		var active_save := voyage.export_state()
		voyage.import_state(JSON.parse_string(JSON.stringify(active_save)))
		check(voyage.trial_active and voyage.trial_counts.sink == 3 and voyage.trial_counts.loot == 2, "active assignment round-trip " + str(tier))
		world.current_sector = Vector2i.ZERO # Return to any available harbor.
		port.activated_for_visit = false
		port.activate(player)
		port.activate(player)
		check(voyage.trial_ready() and voyage.trial_counts.dock == 1, "return counts once " + str(tier))
		player.remove_meta("nearby_port")
		check(not voyage.claim_trial(), "cannot claim at sea " + str(tier))
		player.set_meta("nearby_port", port)
		var coins := progress.coins
		var expected_coins := BeginnerRules.REWARD_COINS
		var expected_level := progress.level
		var expected_xp := progress.xp + BeginnerRules.REWARD_XP
		while expected_xp >= int(100.0 * pow(float(expected_level), 1.35)):
			expected_xp -= int(100.0 * pow(float(expected_level), 1.35))
			expected_level += 1
			expected_coins += 75 + expected_level * 15
		var selected := roster.selected_ship_id
		health.is_sunk = true
		check(not voyage.claim_trial(), "sunk ship cannot claim " + str(tier))
		health.is_sunk = false
		check(voyage.claim_trial(), "claim tier " + str(tier))
		check(progress.coins == coins + expected_coins, "exact reward including existing pirate level bonus " + str(tier))
		check(progress.level == expected_level and progress.xp == expected_xp, "exact XP and separate pirate level " + str(tier))
		check(not voyage.claim_trial() and progress.coins == coins + expected_coins, "no duplicate reward " + str(tier))
		check(not voyage.trial_active and voyage.trial_counts.sink == 0, "next assignment starts empty " + str(tier))
		check(roster.selected_ship_id == selected, "reward never switches ship mid-session " + str(tier))
		check(roster.owns_ship("clipper") == (tier >= 2) and roster.owns_ship("chalupa") == (tier >= 3), "starter reward order " + str(tier))
		var completed_save := voyage.export_state()
		voyage.import_state(JSON.parse_string(JSON.stringify(completed_save)))
		check(voyage.map_level() == tier + 1 and progress.coins == coins + expected_coins, "loading does not pay rewards twice " + str(tier))
		if tier == 2:
			progress.shop_open = true
			roster.preview_index = ShipCatalog.index_of("clipper")
			check(roster.buy_or_equip_preview() and progress.coins == coins + expected_coins, "earned medium equips free at harbor")
			check(roster.ship_level() == 1 and progress.upgrades.hull == 0, "earned design starts with own progress")
			check(voyage.start_trial(), "later attempt can start")
			voyage._on_sunk(player, null)
			check(voyage.completed_trials == 2 and roster.owns_ship("clipper"), "sinking preserves earned maps and ships")
	check(voyage.beginner_complete() and voyage.elite_progression_unlocked(), "elite boundary reached after tier five")
	check(not voyage.start_trial() and not voyage.can_enter(Vector2i(3, 1)), "no infinite beginner rewards or level-seven bypass")
	check(ShipCatalog.SHIPS.size() == 3, "elite ship fleet not fabricated")
	progress.shop_open = true
	roster.preview_index = ShipCatalog.index_of("chalupa")
	check(roster.buy_or_equip_preview(), "earned large can equip")
	check(roster.ship_level() == 1, "large independent ship level")
	# End-to-end save: both the earned fleet and map tier survive reload.
	var original_path := state.save_path
	var original_backup := state.backup_path
	state.save_path = "user://m32_fixture_" + Crypto.new().generate_random_bytes(8).hex_encode() + ".json"
	state.backup_path = state.save_path + ".backup"
	root.set_meta("reconstruction_test_mode", false)
	check(state.save_now(), "M32 real checksummed profile write")
	root.set_meta("reconstruction_test_mode", true)
	var payload := state._read_valid_payload(state.save_path)
	check(payload.get("m32_version") == 1 and payload.get("voyage", {}).get("completed_trials") == 5, "M32 marker and completion persisted")
	state._loaded_payload = payload
	state._apply_loaded_state()
	check(voyage.map_level() == 6 and roster.owned_ship_ids.size() == 3 and roster.selected_ship_id == "chalupa", "full M32 restore")
	# A real world-boundary transition can enter level six and rejects level seven.
	world.current_sector = Vector2i(1, 1)
	world._transition(Vector2i.RIGHT)
	check(world.current_sector == Vector2i(2, 1), "level-six boundary transition")
	world._transition(Vector2i.RIGHT)
	check(world.current_sector == Vector2i(2, 1), "level-seven boundary blocked")
	for enemy in get_nodes_in_group("enemies"): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	# M31 saves retain the selected ship, upgrades and loadouts; no forced downgrade.
	progress.upgrades = {"hull": 4, "cannon": 2, "sails": 1}
	roster.import_state({"owned_ship_ids": ["chalupa"], "selected_ship_id": "chalupa"})
	inventory.import_state({"loadouts_by_ship": {"chalupa": {"A": {"cannon": 2, "ammo": 1, "mode": "harpoon"}}}})
	var coins_before := progress.coins
	voyage.import_state({"trial_passed": true})
	check(voyage.completed_trials == 1 and voyage.map_level() == 2, "old passed trial migrates to first completion")
	check(roster.owns_ship("barco_low") and roster.owns_ship("chalupa") and not roster.owns_ship("clipper"), "pre-version migration keeps saved ships without fabricating canonical PL2 reward")
	check(roster.selected_ship_id == "chalupa" and progress.upgrades.hull == 4 and progress.coins == coins_before, "migration no downgrade or duplicate gold")
	check(inventory.saved_loadouts.A.cannon == 2 and inventory.saved_loadouts.A.mode == "harpoon", "migration retains design loadout")
	roster.import_state({"owned_ship_ids":["barco_low"],"selected_ship_id":"barco_low"})
	voyage.import_state({"beginner_version":1,"completed_trials":1})
	check(roster.owns_ship("clipper"), "v1 stage-one Clipper entitlement grandfathered")
	check(roster.owns_ship("clipper"), "explicit v1 migration retains Clipper entitlement")
	voyage.import_state({}, true)
	check(voyage.can_enter(Vector2i(3, 2)) and voyage.map_level() == 1 and not voyage.elite_progression_unlocked(), "legacy travel does not fabricate elite progression")
	for value in [null, "5", -4, true]:
		voyage.import_state({"beginner_version": 1, "completed_trials": value})
		check(voyage.completed_trials == 0, "invalid completion rejected " + str(value))
	voyage.import_state({"beginner_version": 1, "completed_trials": 999, "trial_active": true, "trial_counts": {"sink": 99}})
	check(voyage.completed_trials == 5 and not voyage.trial_active and voyage.trial_counts.sink == 0, "completion clamp and finished trial cleanup")
	# Home UI: real Controls show the small ship, not an OptionButton starter picker.
	var session := LocalSession.new()
	root.add_child(session)
	var menu := EntryScreen.new()
	menu.session = session
	menu.settings = settings
	root.add_child(menu)
	for guest in [false, true]:
		session.guest = guest
		menu.show_screen("home")
		await settle()
		check(not menu.controls.has("starter") and menu.home_data.ship_id == "barco_low", "no starter choice home guest=" + str(guest))
		check(menu.controls.has("play"), "play remains available guest=" + str(guest))
	menu.queue_free()
	session.queue_free()
	for suffix in ["", ".backup", ".tmp"]:
		if FileAccess.file_exists(state.save_path + suffix): DirAccess.remove_absolute(state.save_path + suffix)
	state.save_path = original_path
	state.backup_path = original_backup
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for type in ["AudioStreamPlayer", "AudioStreamPlayer3D"]:
		for audio in game.find_children("*", type, true, false): audio.stop()
	await create_timer(0.2).timeout
	game.queue_free()
	port.queue_free()
	settings.queue_free()
	await settle()
	print(JSON.stringify({"suite": "M32", "checks": checks, "failures": failures, "engine": Engine.get_version_info().string}))
	quit(0 if failures.is_empty() else 1)
