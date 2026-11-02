extends SceneTree

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _run() -> void:
	var service := P0AssetSwapService.new()
	root.add_child(service)
	await process_frame
	var status := service.summary()
	assert(status.total == 14)
	assert(status.valid == 14)
	assert(status.replace_without_code)
	assert(P0VisualSlotResolver.runtime_id("SHIP-STARTER-001") == "ship_small")
	assert(P0VisualSlotResolver.runtime_id("NPC-SHIP-EARLY-004") == "npc_gunship_01")
	assert(P0VisualSlotResolver.runtime_id("ISLAND-P0-004") == "island_sandbar_long")
	assert(P0VisualSlotResolver.runtime_id("MON-KRAKEN-001") == "monster_early_01")
	var seen := {}
	for value in service.manifest.get("slots", []):
		var row := value as Dictionary
		var path := str(service.manifest.replacement_root) + str(row.file)
		assert(not seen.has(path))
		seen[path] = true
		assert(ResourceLoader.exists(path))
		var packed := load(path) as PackedScene
		assert(packed != null)
		var instance := packed.instantiate() as Node3D
		assert(instance != null and AssetVisualLibrary.visual_only(instance))
		instance.free()
	var visual := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	visual.add_child(mesh)
	P0VisualPolish.apply(visual, "npc_scout_01", true, false)
	assert(visual.get_meta("m146_visual_polish", "") == "mobile")
	assert(visual.get_meta("m146_gameplay_geometry_untouched", false))
	visual.free()
	print("M146_P0_ASSET_SWAP_PASS")
	quit()
