extends SceneTree
## Real world gameplay, not a rendered concept: more NPCs and actionable treasure.
var failures: Array[String] = []

func check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.set_meta("m3035_graphic_mode", "private_sprite")
	var packed := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(packed != null, "game loads")
	if packed == null:
		_done()
		return
	var scene: Node3D = packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	check(scene.enemies.size() == 12, "5 base ships + 1 monster + 3 M303.8 patrols + 3 new ship classes")
	for i in range(6, 9):
		var npc: Dictionary = scene.enemies[i]
		check(str(npc["kind"]) == "ship" and int(npc["hp"]) == 100, "extra NPC has combat state")
		var sprite: Node = npc["node"].get_node_or_null("ShipSprite")
		check(sprite != null and sprite.get("visual") != null, "extra NPC uses integrated private sprite")
	var player: Node3D = scene.ship
	var chest_position := Vector3(10.0, 0.65, 13.0)
	scene._create_loot(chest_position, 70)
	check(scene.loot_items.size() == 1, "real chest spawned")
	var loot: Node3D = scene.loot_items[0]["node"]
	check(loot.get_child_count() >= 5, "chest has detailed wood/brass physical meshes")
	# Player can tap treasure to sail toward it (rather than tapping only empty water).
	scene.route.clear()
	scene._world_click(scene.camera.unproject_position(chest_position))
	check(not scene.route.is_empty(), "tap chest sets navigable loot course")
	# The real proximity-collection mechanism then transfers gold once.
	var before_gold: int = scene.gold
	player.position = chest_position
	scene._collect_nearby_loot()
	check(scene.gold == before_gold + 70, "chest pays correct reward")
	check(scene.loot_items.is_empty(), "collected chest removed")
	scene._switch_graphics()
	for i in range(6, 9):
		var npc: Dictionary = scene.enemies[i]
		var sprite: Node = npc["node"].get_node_or_null("ShipSprite")
		check(sprite != null and sprite.get("visual") != null, "patrol art survives SeaOfBones switch")
	_done()

func _done() -> void:
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL",
		"version":"M303.8", "failed":failures,
		"scope":"three new reference-art NPC patrols, loot chest pickup, tap-to-sail, visual pack swap"}))
	quit(0 if failures.is_empty() else 1)
