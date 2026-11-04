extends SceneTree
## M304.4 live HUD and ammunition marketplace integration, tested in actual scene.
var failures: Array[String] = []

func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.set_meta("m3035_graphic_mode", "original_fleet")
	var packed := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(packed != null, "M304.4 actual scene loads")
	if packed == null:
		_finish()
		return
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var current_script: Script = game.get_script()
	var has_m3044 := false
	while current_script != null:
		if current_script.resource_path.ends_with("m3044_naval_hud_ammo_shop.gd"):
			has_m3044 = true
			break
		current_script = current_script.get_base_script()
	check(has_m3044, "M304.4 functional HUD remains active via M304.5 inheritance")
	check(game._ammo_panel != null and game._ammo_overlay != null and game._ammo_menu_button != null,
		"functional ammunition inventory constructed")
	check(game._ammo_buttons.size() == 3 and game._restock_buttons.size() == 3,
		"three independent ammo choices and three real-money-free gold restocks")
	check(not game._ammo_panel.visible and not game._ammo_overlay.visible, "ammo UI initially closed")
	check(game._yard_buttons.size() == 3 and game._yard_buttons[1].icon != null,
		"shipyard cards use original vector ship graphics")
	check(game._dock_quick_button != null and game._speed_info != null,
		"game has a quick shipyard launcher and live heading readout")
	check(game.ship.get_node_or_null("OriginalVessel") != null, "original 3D ships retained")
	game.gold = 150
	game._refresh()
	var old_cannon: int = game.cannonballs
	game._buy_ammunition(0)
	check(game.cannonballs == old_cannon + 50 and game.gold == 135,
		"buying 50 cannonballs costs exactly 15 in-game gold")
	var old_harpoon: int = game.harpoons
	game._buy_ammunition(1)
	check(game.harpoons == old_harpoon + 25 and game.gold == 117,
		"buying 25 harpoons costs exactly 18 in-game gold")
	var old_chain: int = game.chainballs
	game._buy_ammunition(2)
	check(game.chainballs == old_chain + 15 and game.gold == 97,
		"buying chainshots uses existing 20-gold shipyard economy")
	game.gold = 0
	game._buy_ammunition(0)
	check(game.cannonballs == old_cannon + 50 and game.gold == 0,
		"insufficient money cannot purchase ammunition")
	game._toggle_ammo_inventory()
	check(game._ammo_panel.visible and game._ammo_overlay.visible, "ammo launcher opens blocking modal")
	game._equip_from_ammo_inventory(1)
	check(game.weapon_mode == "harpoon" and not game._ammo_panel.visible and not game._ammo_overlay.visible,
		"ammo choice really selects harpoon and closes modal")
	game._toggle_ammo_inventory()
	game._toggle_shipyard()
	check(game._yard_panel.visible and not game._ammo_panel.visible and not game._ammo_overlay.visible,
		"shipyard remains functional and replaces ammo inventory")
	game._toggle_options()
	check(game._options.visible and not game._ammo_panel.visible,
		"settings and ammo modal never conflict")
	game._toggle_options()
	game._toggle_shipyard()
	for resolution: Vector2i in [Vector2i(844, 390), Vector2i(1280, 720), Vector2i(690, 330)]:
		root.size = resolution
		await process_frame
		game._layout_hud()
		var input_buttons: Array[Button] = [game._ammo_cannon, game._ammo_harpoon, game._ammo_chain,
			game._hud_controls["repair"], game.attack_button, game._ammo_menu_button, game._dock_quick_button]
		for i in input_buttons.size():
			for j in range(i + 1, input_buttons.size()):
				var a: Button = input_buttons[i]
				var b: Button = input_buttons[j]
				if a.visible and b.visible:
					check(not a.get_global_rect().intersects(b.get_global_rect()),
						"touch action overlap at %s: %s vs %s" % [resolution, a.name, b.name])
		check(not game._hud_status_frame.get_global_rect().intersects(game._hud_player_frame.get_global_rect()),
			"status vs captain card at %s" % resolution)
		check(not game._hud_status_frame.get_global_rect().intersects(game._hud_mini_frame.get_global_rect()),
			"status vs minimap at %s" % resolution)
		game._toggle_ammo_inventory()
		check(game._ammo_panel.visible, "responsive ammo panel opens at %s" % resolution)
		var panel: Rect2 = game._ammo_panel.get_global_rect()
		for btn: Button in game._restock_buttons:
			check(panel.encloses(btn.get_global_rect()), "restock button inside panel at %s: %s" % [resolution, btn.name])
		check(panel.encloses(game._ammo_close.get_global_rect()), "close button stays inside panel at %s" % resolution)
		game._toggle_ammo_inventory()
	_finish()

func _finish() -> void:
	print(JSON.stringify({
		"status": "PASS" if failures.is_empty() else "FAIL",
		"version": "M304.4",
		"scope": "genuine illustrated shipyard, three ammo selectors, spendable gold restock, exclusive modal, responsive 690/844/1280 controls",
		"failed": failures
	}))
	quit(0 if failures.is_empty() else 1)
