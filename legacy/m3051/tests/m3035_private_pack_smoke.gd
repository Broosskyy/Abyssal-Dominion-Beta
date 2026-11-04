extends SceneTree
## Historical M303.5 comparison prototype; current player flow uses M303.6.
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _run() -> void:
	var packed := load("res://scripts/classic/m3035_seabattles_core.gd") as GDScript
	if packed == null:
		quit(1)
		return
	var scene: Node3D = packed.new()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	check(scene.ship.get_node_or_null("ShipSprite/MultiDirectionShip") != null, "private ship atlas is loaded")
	check(scene.get_node_or_null("SeaBattlesReferenceOcean") != null, "source noise is used by ocean")
	check(scene.enemies[5].node.get_node_or_null("ShipSprite/MultiDirectionShip") != null, "private monster PNG is loaded")
	check(scene.get_node("Island_3").get_node_or_null("IslandVisual/IslandImage") != null, "private tropical island is loaded")
	evidence["private_actor_slots"] = ["PlayerShip", "NPC_0", "NPC_1", "NPC_2", "NPC_3", "NPC_4", "SeaMonster", "Island_3"]
	var start: Vector3 = scene.ship.position
	scene._course(Vector3(8, 0, 0))
	for i in 60:
		scene._sail(1.0 / 60.0)
	check(scene.ship.position.distance_to(start) > 2.0, "ship moves toward course")
	check(not scene._blocked(scene.ship.position), "ship stays clear of island colliders")
	var adapter: Node3D = scene.ship.get_node("ShipSprite")
	adapter.set_moving(false)
	adapter.set_heading(0.0)
	var frame_north: int = adapter.visual.frame
	adapter.set_heading(PI / 2.0)
	var frame_west: int = adapter.visual.frame
	check(frame_north != frame_west, "heading changes atlas frame")
	check(frame_north == 1, "four source headings use the declared 45 degree sector offset")
	evidence["heading_frames"] = [frame_north, frame_west]
	adapter.set_heading(0.0)
	adapter.set_moving(true)
	check(adapter.visual.frame == 5, "movement uses deployed sails, same heading")
	adapter.set_moving(false)
	check(adapter.visual.frame == 1, "idle uses furled sails, same heading")
	var creature: Node3D = scene.enemies[5].node.get_node("ShipSprite")
	creature.set_heading(0.0)
	var creature_before: int = creature.visual.frame
	creature._process(1.0 / 7.0 + 0.01)
	check(creature.visual.frame != creature_before, "monster advances animation row")
	evidence["source_layout"] = "Ship: 4 headings x 2 sail states. Monster: 4 headings x 8 animation phases."
	scene.target = 0
	scene.ship.position = scene.enemies[0].node.position + Vector3(8, 0, 0)
	var hp_before: int = scene.enemies[0].hp
	var ammo_before: int = scene.cannonballs
	scene._fire()
	check(scene.enemies[0].hp == hp_before - 24, "cannon damage remains unchanged")
	check(scene.cannonballs == ammo_before - 1, "cannon consumes one round")
	var had_smoke := false
	for node: Node in scene.get_children():
		if node is Sprite3D:
			had_smoke = true
	check(had_smoke, "successful shot spawns alpha smoke")
	for mode: String in ["seaofbones_sprite", "complete_3d", "placeholder_sprite"]:
		root.set_meta("m3035_graphic_mode", mode)
		var fallback: Node3D = packed.new()
		root.add_child(fallback)
		await process_frame
		check(fallback.ship.get_child_count() > 0, "fallback renders: " + mode)
		if mode == "seaofbones_sprite":
			check(fallback.ship.get_node_or_null("ShipSprite/MultiDirectionShip") != null, "previous SeaOfBones pack remains available")
			check(fallback.ASSET_BRIDGE.pack_config().get("package", "") == "com.seaofbones.game", "source pack selection is independent")
		else:
			check(fallback.ship.get_node_or_null("ShipSprite/MultiDirectionShip") == null, "fallback does not use private atlas: " + mode)
		fallback.queue_free()
		await process_frame
	evidence["engine"] = Engine.get_version_info().string
	evidence["failures"] = failures
	evidence["status"] = "PASS" if failures.is_empty() else "FAIL"
	evidence["scope"] = "Native scene smoke; course, movement, heading, damage, ammo, effects and fallback graphics. Screenshot review is separate."
	var output := OS.get_environment("M3035_QA_REPORT")
	if not output.is_empty():
		FileAccess.open(output, FileAccess.WRITE).store_string(JSON.stringify(evidence, "\t"))
	print(JSON.stringify(evidence))
	quit(0 if failures.is_empty() else 1)
