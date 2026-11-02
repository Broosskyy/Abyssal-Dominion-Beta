extends SceneTree
## Historical M303.6 regression: instantiate its script directly because the active scene now runs M303.7.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if not value:
		failures.append(label)

func _run() -> void:
	# A stale comparison choice must not create a third player-facing mode.
	root.set_meta("m3035_graphic_mode", "complete_3d")
	var scene: Node3D = (load("res://scripts/classic/m3036_unified_sea_map.gd") as Script).new()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	check(scene._asset_mode == "private_sprite", "stale 3D comparison choice falls back to SeaBattles")
	check(scene._graphics_button == null, "no comparison button on the playfield")
	check(not scene._options.visible, "graphics choice starts inside a closed menu")
	check(scene._portrait.texture != null, "captain portrait is populated")
	check(not scene._hud_target_frame.visible, "empty target panel is hidden")
	check(not "M303.1" in scene.status.text, "legacy debug status removed")
	var start: Vector3 = scene.ship.position
	scene._course(start + Vector3(8,0,0))
	for i in 45:
		scene._sail(1.0 / 60.0)
	check(scene.ship.position.distance_to(start) > 1.0, "course movement still works")
	scene.target = 0
	scene.ship.position = scene.enemies[0].node.position + Vector3(8,0,0)
	var old_hp: int = scene.enemies[0].hp
	var old_ammo: int = scene.cannonballs
	scene._fire()
	check(scene.enemies[0].hp == old_hp - 24 and scene.cannonballs == old_ammo - 1, "combat rules unchanged")
	scene.hull = 67
	scene.gold = 92
	scene.kills = 2
	scene.firing = true
	scene.reload = 0.8
	scene.repair_cooldown = 9.0
	scene.pan = Vector3(4,0,3)
	scene._refresh()
	var state := [scene.ship.get_instance_id(), scene.ship.position, scene.ship.rotation, scene.route.duplicate(), scene.hull, scene.gold,
		scene.kills, scene.cannonballs, scene.harpoons, scene.target, scene.firing, scene.reload, scene.repair_cooldown, scene.pan,
		scene.enemies[0].node.get_instance_id(), scene.enemies[0].hp]
	var water_id: int = scene.get_node("UnifiedOcean").get_instance_id()
	var island_id: int = scene.get_node("Island_0/IslandVisual").get_instance_id()
	var hud_id: int = scene._ui_root.get_instance_id()
	scene._menu_button.pressed.emit()
	check(scene._options.visible, "menu opens from actual button signal")
	for expected: String in ["seaofbones_sprite", "private_sprite"]:
		scene._pack_button.pressed.emit()
		check(scene._asset_mode == expected, "only two sources are selectable")
		check(scene == current_scene, "source change keeps scene instance")
		var after := [scene.ship.get_instance_id(), scene.ship.position, scene.ship.rotation, scene.route.duplicate(), scene.hull, scene.gold,
			scene.kills, scene.cannonballs, scene.harpoons, scene.target, scene.firing, scene.reload, scene.repair_cooldown, scene.pan,
			scene.enemies[0].node.get_instance_id(), scene.enemies[0].hp]
		check(state == after, "source change preserves the entire live combat/navigation state")
		check(scene.get_node("UnifiedOcean").get_instance_id() == water_id, "water stays identical")
		check(scene.get_node("Island_0/IslandVisual").get_instance_id() == island_id, "coastline stays identical")
		check(scene._ui_root.get_instance_id() == hud_id, "HUD stays identical")
		check(scene.ship.get_node_or_null("ShipSprite/MultiDirectionShip") != null, "source sprite is installed")
		check(scene._portrait.texture != null and scene._hull_bar.value == 67, "portrait and live hull stay populated")
	scene._options_close.pressed.emit()
	check(not scene._options.visible, "menu closes without restarting the game")
	var result := {"status": "PASS" if failures.is_empty() else "FAIL", "engine": Engine.get_version_info().string,
		"failures": failures, "scope": "One HUD/world; two source packs; in-place swaps preserve scene, actor identities, position, route, camera, HP, ammo, target, firing, cooldowns, gold and kills; movement and real damage exercised."}
	var destination := OS.get_environment("M3036_QA_REPORT")
	if not destination.is_empty():
		FileAccess.open(destination, FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
