extends SceneTree

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _run() -> void:
	var catalog := ProductionWaveCatalog.new()
	root.add_child(catalog)
	await process_frame
	var status := catalog.summary()
	assert(status.valid)
	assert(status.p1_glb_ready == 10 and status.p1_glb_total == 10)
	assert(status.p2_reserved == 20 and status.p3_reserved == 10 and status.p4_reserved == 10)
	assert(status.p_event_reserved and not status.live_activation)
	assert(ProductionWaveCatalog.wave_for_ship(1) == "P1")
	assert(ProductionWaveCatalog.wave_for_ship(10) == "P1")
	assert(ProductionWaveCatalog.wave_for_ship(11) == "P2")
	assert(ProductionWaveCatalog.wave_for_ship(30) == "P2")
	assert(ProductionWaveCatalog.wave_for_ship(31) == "P3")
	assert(ProductionWaveCatalog.wave_for_ship(40) == "P3")
	assert(ProductionWaveCatalog.wave_for_ship(41) == "P4")
	assert(ProductionWaveCatalog.wave_for_ship(50) == "P4")
	assert(ProductionWaveCatalog.runtime_id("SHIP-PROG-001") == "ship_main_01")
	assert(ProductionWaveCatalog.runtime_id("SHIP-PROG-010") == "ship_main_10")
	assert(ProductionWaveCatalog.runtime_id("SHIP-PROG-011") == "SHIP-PROG-011")
	var paths := {}
	for index in range(1, 11):
		var id := "ship_main_%02d" % index
		var row := ProductionWaveCatalog.entry(id)
		assert(not row.is_empty() and not paths.has(row.path))
		paths[row.path] = true
		assert(ResourceLoader.exists(row.path))
		var packed := load(row.path) as PackedScene
		assert(packed != null)
		var instance := packed.instantiate() as Node3D
		assert(instance != null and AssetVisualLibrary.visual_only(instance))
		instance.free()
	print("M147_PRODUCTION_WAVES_PASS")
	quit()
