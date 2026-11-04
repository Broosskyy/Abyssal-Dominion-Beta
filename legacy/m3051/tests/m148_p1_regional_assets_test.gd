extends SceneTree

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _run() -> void:
	var catalog := P1RegionalAssetCatalog.new()
	root.add_child(catalog)
	await process_frame
	var status := catalog.summary()
	assert(status.valid and status.valid_glb == 24 and status.total == 24)
	assert(status.counts.ship == 9 and status.counts.monster == 7)
	assert(status.counts.flora == 4 and status.counts.island_module == 2 and status.counts.harbor == 2)
	assert(not status.live_activation)
	assert(P1RegionalAssetCatalog.runtime_id("NPC-SHIP-CRIMSON-001") == "npc_storm_raider")
	assert(P1RegionalAssetCatalog.runtime_id("HARBOR-MOURNING-PORT") == "harbor_ember")
	var seen := {}
	for value in P1RegionalAssetCatalog.config.get("assets", []):
		var row := P1RegionalAssetCatalog.entry(str(value.id))
		assert(not row.is_empty() and not seen.has(row.path))
		seen[row.path] = true
		assert(ResourceLoader.exists(row.path))
		var packed := load(row.path) as PackedScene
		assert(packed != null)
		var instance := packed.instantiate() as Node3D
		assert(instance != null and AssetVisualLibrary.visual_only(instance))
		instance.free()
	print("M148_P1_REGIONAL_ASSETS_PASS")
	quit()
