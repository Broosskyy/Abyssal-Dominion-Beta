extends SceneTree
## M304.3: exercise original procedural 3D fleet inside actual Godot map.
var failures: Array[String] = []

func check(ok: bool, reason: String) -> void:
	if not ok:
		failures.append(reason)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.set_meta("m3035_graphic_mode", "original_fleet")
	var scene_data := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(scene_data != null, "actual game scene loads")
	if scene_data == null:
		_finish()
		return
	var scene: Node3D = scene_data.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	check(scene._asset_mode == "original_fleet", "default original source mode")
	var has_original := false
	var current_script: Script = scene.get_script()
	while current_script != null:
		if current_script.resource_path.ends_with("m3043_original_fleet_ocean.gd"):
			has_original = true
			break
		current_script = current_script.get_base_script()
	check(has_original, "M304.3 3D fleet remains active through inherited M304.4 scene")
	var model: Node = scene.ship.get_node_or_null("OriginalVessel")
	check(model != null, "main ship is original 3D graphics")
	if model != null:
		check(model.profile == "brig", "starter has genuine brig model")
		check(model.get_node_or_null("ArtHull") != null and model.get_node_or_null("ArtRigging") != null,
			"original ship contains hull and detailed rigging")
		check(model.get_node("ArtHull").get_child_count() > 12, "ship has actual geometry and cannons")
		check(not model.get_node("DamageVisuals").visible, "100 percent hull never renders damage")
		for n in 60:
			model.set_moving(n % 2 == 0)
			model.set_hull_ratio(1.0)
			check(not model.get_node("DamageVisuals").visible, "healthy sailing never enters damaged state")
		model.set_hull_ratio(0.25)
		check(model.get_node("DamageVisuals").visible, "genuine HP damage switches visual state")
		model.set_hull_ratio(1.0)
		check(not model.get_node("DamageVisuals").visible, "repair restores intact visuals")
	var n_original := 0
	for enemy in scene.enemies:
		var actor: Node3D = enemy["node"]
		if actor.get_node_or_null("OriginalVessel") != null:
			n_original += 1
	check(n_original >= 11, "all NPC ship classes have original 3D models")
	var water: MeshInstance3D = scene.get_node_or_null("UnifiedOcean") as MeshInstance3D
	check(water != null and water.material_override is ShaderMaterial, "procedural ocean installed")
	var ship_id: int = scene.ship.get_instance_id()
	var position_before: Vector3 = scene.ship.position
	scene.gold = 45
	scene._purchase_or_equip(1)
	var frigate: Node = scene.ship.get_node_or_null("OriginalVessel")
	check(frigate != null and frigate.profile == "frigate", "purchase applies new full 3D frigate")
	check(scene.gold == 0 and scene._ship_class_index == 1, "purchase costs actual gold")
	check(scene.ship.get_instance_id() == ship_id and scene.ship.position == position_before,
		"new graphics preserve player identity and position")
	scene.hull = 61
	scene._refresh()
	scene._toggle_original_fleet()
	check(scene._asset_mode == "private_sprite", "original toggle activates reference sprites")
	scene._switch_graphics()
	check(scene._asset_mode == "seaofbones_sprite", "legacy reference toggle opens second pack")
	scene._switch_graphics()
	check(scene._asset_mode == "private_sprite", "legacy reference toggle returns to first pack")
	scene._toggle_original_fleet()
	check(scene._asset_mode == "original_fleet", "separate original button restores 3D art")
	check(scene.ship.get_node_or_null("OriginalVessel") != null, "original 3D visual restored")
	check(scene.hull == 61 and scene.gold == 0 and scene.ship.get_instance_id() == ship_id,
		"graphic switching never resets hull, currency or ship identity")
	check(scene.weapon_mode == "cannon", "ammo remains usable")
	check(scene._ammo_chain != null and scene._yard_panel != null, "legacy ammunition and shipyard still exist")
	_finish()

func _finish() -> void:
	print(JSON.stringify({
		"version": "M304.3",
		"status": "PASS" if failures.is_empty() else "FAIL",
		"scope": "original 3D fleet and ocean, true-HP damage state, shipyard model switching, in-place asset swap, stable M304.2 quickbar",
		"failed": failures
	}))
	quit(0 if failures.is_empty() else 1)
