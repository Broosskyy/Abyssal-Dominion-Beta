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
	VisualAssetCatalog.reload_catalog()
	check(VisualAssetCatalog.diagnostics.is_empty(), "catalog parses")
	check(VisualAssetCatalog.slots.models.size() == 18, "all 18 model slots catalogued")
	var wrapper := Node3D.new()
	root.add_child(wrapper)
	var collision := StaticBody3D.new()
	wrapper.add_child(collision)
	var socket := Marker3D.new()
	socket.position = Vector3(2, 0.5, 1)
	wrapper.add_child(socket)
	var audit := {}
	for id in AssetVisualLibrary.entries():
		var visual := AssetVisualLibrary.install(wrapper, id)
		check(visual != null, "GLB loads " + id)
		check(AssetVisualLibrary.visual_only(visual), "visual-only GLB " + id)
		check(wrapper.get_child_count() == 3 and socket.position == Vector3(2, 0.5, 1), "swap leaves wrapper/collision/socket " + id)
		var bounds: AABB = wrapper.get_meta("hud_visual_bounds")
		check(bounds.position.is_finite() and bounds.size.is_finite() and bounds.size.length() > 0, "finite mesh bounds " + id)
		var triangles := 0
		var surfaces := 0
		var normals := true
		for mesh: MeshInstance3D in visual.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var arrays := mesh.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normal_values: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				normals = normals and normal_values.size() == vertices.size()
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				triangles += int((indices.size() if not indices.is_empty() else vertices.size()) / 3)
				surfaces += 1
		check(normals, "normal data present " + id)
		check(surfaces > 0 and triangles > 0, "renderable mesh data " + id)
		var info := VisualAssetCatalog.info("models", id)
		check(info.status in ["active", "prepared"], "slot integration status " + id)
		audit[id] = {"status": info.status, "consumer": info.consumer, "triangles": triangles, "surfaces": surfaces,
			"bounds_m": [bounds.size.x, bounds.size.y, bounds.size.z], "bounds_min": [bounds.position.x, bounds.position.y, bounds.position.z], "normals_present": normals}
	for id in VisualAssetCatalog.slots.ui:
		var texture := VisualAssetCatalog.texture(id)
		check(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "UI image loads " + id)
		check(texture == VisualAssetCatalog.texture(id), "UI resource cached " + id)
	# Calibrate a distinctly different existing GLB in the actual ship wrapper.
	var settings := ClientSettings.new()
	root.add_child(settings)
	settings.update_value("muted", true)
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_process(false)
	var player := get_first_node_in_group("player") as ShipMotor
	player.set_physics_process(false)
	(player.get_node("PlayerInput") as PlayerShipInput).set_process(false)
	for enemy in get_nodes_in_group("enemies"): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var progress := player.get_node("Progression") as PlayerProgression
	var inventory := player.get_node("Inventory") as PlayerInventory
	var weapons := player.get_node("Weapons") as ShipWeapons
	var health := player.get_node("Health") as ShipHealth
	var saved_progress := progress.export_state()
	var saved_inventory := inventory.export_state()
	var hp := health.current_health
	var damage := weapons.damage
	var hitbox := player.get_node("ShipCollision") as CollisionShape3D
	var shape := hitbox.shape
	var shape_size: Vector3 = (shape as BoxShape3D).size
	var markers := player.find_children("*", "Marker3D", true, false)
	var positions := []
	for marker in markers: positions.append(marker.transform)
	var original_bounds: AABB = player.get_meta("hud_visual_bounds")
	VisualAssetCatalog.overrides.models.ship_small = {"path": AssetVisualLibrary.entries().harbor.path}
	var changed := AssetVisualLibrary.install(player, "ship_small")
	var changed_bounds: AABB = player.get_meta("hud_visual_bounds")
	check(changed.get_meta("source_path") == AssetVisualLibrary.entries().harbor.path, "different harbor GLB actually installed as visual replacement")
	check(changed.get_meta("classification") == "USER_REPLACEMENT", "replacement provenance")
	check(changed_bounds.size.x <= original_bounds.size.x + 0.01 and changed_bounds.size.z <= original_bounds.size.z + 0.01, "replacement fits original footprint")
	check(hitbox.shape == shape and (shape as BoxShape3D).size == shape_size, "shape resource and collision dimensions unchanged")
	check(progress.export_state() == saved_progress and inventory.export_state() == saved_inventory and health.current_health == hp and weapons.damage == damage, "visual swap cannot alter stats/inventory/health/damage")
	for i in markers.size(): check(markers[i].transform == positions[i], "gameplay socket preserved " + str(i))
	VisualAssetCatalog.overrides.models.ship_small = {"path": AssetVisualLibrary.entries().ship_large.path, "fit_reference": false, "scale": [0.5, 0.5, 0.5], "offset": [0, 2, 0], "rotation_degrees": [0, 90, 0]}
	changed = AssetVisualLibrary.install(player, "ship_small")
	var calibrated := changed.get_node("Model") as Node3D
	check(is_equal_approx(calibrated.position.y, 2) and is_equal_approx(calibrated.rotation_degrees.y, 90), "waterline/heading calibration")
	check(calibrated.scale.is_equal_approx(Vector3.ONE * 0.5), "model scale calibration")
	VisualAssetCatalog.overrides.models.ship_small = {"path": "res://assets/custom/missing.glb"}
	changed = AssetVisualLibrary.install(player, "ship_small")
	check(changed.get_meta("source_path") == AssetVisualLibrary.entries().ship_small.path, "missing model safely falls back")
	check(not VisualAssetCatalog.diagnostics.is_empty(), "bad override diagnosed")
	check(not VisualAssetCatalog.safe_path("res://assets/../scripts/test.tscn", ["glb"]), "scene/path traversal rejected")
	check(VisualAssetCatalog.vector([0, 1, 1], Vector3.ONE, 0.001, 1000) == Vector3.ONE, "zero scale rejected")
	check(VisualAssetCatalog.vector([1, "bad", 1], Vector3.ONE, 0.001, 1000) == Vector3.ONE, "invalid vector rejected")
	var invalid := Node3D.new()
	invalid.add_child(StaticBody3D.new())
	check(not AssetVisualLibrary.visual_only(invalid), "embedded collision rejected")
	invalid.free()
	VisualAssetCatalog.overrides.ui.cannon = {"path": VisualAssetCatalog.info("ui", "harpoon").path}
	VisualAssetCatalog.textures.clear()
	check(VisualAssetCatalog.texture("cannon") == VisualAssetCatalog.texture("harpoon"), "UI replacement follows slot without input changes")
	VisualAssetCatalog.overrides.ui.cannon = {"path": "res://assets/custom/missing.png"}
	VisualAssetCatalog.textures.clear()
	check(VisualAssetCatalog.texture("cannon").resource_path == VisualAssetCatalog.info("ui", "cannon").path, "missing UI safely falls back")
	VisualAssetCatalog.reload_catalog()
	AssetVisualLibrary.install(player, "ship_small")
	check(player.get_meta("hud_visual_bounds") == original_bounds, "restoring placeholder restores bounds")
	VisualAssetCatalog.overrides.ui.card = {"slice_margin": 20}
	var card := NauticalTheme.graphic_style("card")
	check(card.get_texture_margin(SIDE_LEFT) == 20 and card.get_content_margin(SIDE_LEFT) == 12, "nine-slice adapts art without changing content geometry")
	VisualAssetCatalog.overrides.ui.card = {"slice_margin": -9}
	check(VisualAssetCatalog.slice_margin("card") == 12, "invalid nine-slice falls back")
	VisualAssetCatalog.reload_catalog()
	var preview: Control = load("res://scenes/asset_preview.tscn").instantiate()
	root.add_child(preview)
	await settle()
	check(preview.choices.size() == VisualAssetCatalog.slots.models.size() + VisualAssetCatalog.slots.ui.size(), "preview lists every slot")
	for i in preview.choices.size():
		preview.show_asset(i)
		check(not preview.details.text.contains("FAILED"), "preview slot " + str(i))
	preview.queue_free()
	var file := FileAccess.open("res://docs/m33_asset_audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "visual_review": false, "models": audit}, "  "))
	file.close()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for type in ["AudioStreamPlayer", "AudioStreamPlayer3D"]:
		for audio in game.find_children("*", type, true, false): audio.stop()
	await create_timer(0.2).timeout
	game.queue_free()
	wrapper.queue_free()
	settings.queue_free()
	await settle()
	print(JSON.stringify({"suite": "M33", "checks": checks, "failures": failures, "engine": Engine.get_version_info().string}))
	quit(0 if failures.is_empty() else 1)
