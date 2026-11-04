extends SceneTree
## Verifies original M304.5 meshes live in the actual existing game, not mockups.
var failures: Array[String] = []

func check(value: bool, reason: String) -> void:
	if not value:
		failures.append(reason)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.set_meta("m3035_graphic_mode", "original_fleet")
	var resource := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(resource != null, "production game scene parses")
	if resource == null:
		_finish()
		return
	var game: Node3D = resource.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var current_script: Script = game.get_script()
	var includes_original_world := false
	while current_script != null:
		if current_script.resource_path.ends_with("m3045_original_world_pass.gd"):
			includes_original_world = true
			break
		current_script = current_script.get_base_script()
	check(includes_original_world, "M304.5 original world persists in M304.6 inheritance")
	check(game._asset_mode == "original_fleet", "original fleet selected")
	check(game.ship.get_node_or_null("OriginalVessel") != null, "player retains first-party ship")
	var island_count := 0
	var biome_set: Dictionary = {}
	for child: Node in game.get_children():
		if not child.name.begins_with("Island_"):
			continue
		island_count += 1
		var land: Node = child.get_node_or_null("OriginalLandmass")
		check(land != null, "island %s is original and rendered" % child.name)
		if land != null:
			biome_set[str(land.biome)] = true
			check(land.get_node_or_null("OriginalCliffs") != null, "island cliffs exist")
			check(land.get_node_or_null("OriginalIslandDetails") != null, "island details exist")
	check(island_count >= 6, "all six old collision islands remain actual island objects")
	check(biome_set.size() >= 4, "at least four visually different biomes present")
	var monster_index := -1
	for i in game.enemies.size():
		if str(game.enemies[i].get("kind", "")) == "monster":
			monster_index = i
			break
	check(monster_index >= 0, "monster remains in combat array")
	if monster_index >= 0:
		var enemy: Node3D = game.enemies[monster_index]["node"]
		var art: Node = enemy.get_node_or_null("OriginalKraken")
		check(art != null, "Kraken is original 3D model")
		if art != null:
			check(art.get_node_or_null("OriginalKrakenBody") != null, "kraken has modeled body")
			check(art._tentacles.size() >= 6, "kraken has moving, modeled tentacles")
			art.set_hull_ratio(0.45)
			check(is_equal_approx(art._damage_ratio, 0.45), "kraken damage follows live HP")
	check(game._original_coast_effects.size() == game.islands.size(),
		"foam follows every island physical footprint")
	for foam: MeshInstance3D in game._original_coast_effects:
		check(foam.visible, "original coastal foam visible")
	var water: MeshInstance3D = game.get_node_or_null("UnifiedOcean") as MeshInstance3D
	check(water != null and water.material_override is ShaderMaterial, "animated water material installed")
	if water != null and water.mesh is PlaneMesh:
		check((water.mesh as PlaneMesh).subdivide_width >= 60, "ocean wave vertices are subdivided")
	var same_ship: int = game.ship.get_instance_id()
	game.hull = 100
	game._refresh()
	var hull: Node = game.ship.get_node_or_null("OriginalVessel")
	check(hull != null and not hull.get_node("DamageVisuals").visible,
		"ship never looks wrecked at 100% HP")
	game._toggle_original_fleet()
	check(game._asset_mode == "private_sprite", "switch from original to reference")
	for foam: MeshInstance3D in game._original_coast_effects:
		check(not foam.visible, "first-party shoreline overlay hidden in private reference mode")
	game._toggle_original_fleet()
	check(game._asset_mode == "original_fleet", "switch back to own world")
	check(game.ship.get_instance_id() == same_ship and game.hull == 100,
		"visual switching preserves player ship identity and health")
	for child: Node in game.get_children():
		if child.name.begins_with("Island_"):
			check(child.get_node_or_null("OriginalLandmass") != null,
				"island restored as original art after visual toggle")
	check(game._ammo_panel != null and game._yard_panel != null,
		"functional shipyard and ammunition UI survive integration")
	_finish()

func _finish() -> void:
	print(JSON.stringify({
		"status": "PASS" if failures.is_empty() else "FAIL",
		"version": "M304.5",
		"scope": "original islands, 4+ biomes, kraken tentacles, shoreline foam, wave mesh, intact healthy ship, original/reference toggle, inherited HUD",
		"failed": failures
	}))
	quit(0 if failures.is_empty() else 1)
