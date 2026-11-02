extends SceneTree

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _run() -> void:
	var batch := W5ProductionBatch.new(); root.add_child(batch); await process_frame
	var status := W5ProductionBatch.summary()
	assert(status.valid and status.ships == 10 and status.complete_lod_sets == 10 and status.lod_files == 30)
	assert(status.classification == "CLEAN_ROOM_GLB_PLACEHOLDER_NOT_FINAL_ART")
	var macro_bounds := []
	for row in W5ProductionBatch.all():
		assert(ResourceLoader.exists(row.lod0_path) and ResourceLoader.exists(row.lod1_path) and ResourceLoader.exists(row.lod2_path))
		var lod0 := (load(row.lod0_path) as PackedScene).instantiate() as Node3D
		var lod2 := (load(row.lod2_path) as PackedScene).instantiate() as Node3D
		root.add_child(lod0); root.add_child(lod2)
		for socket_name in W5ProductionBatch.required_sockets(): assert(lod0.find_child(str(socket_name), true, false) != null)
		var meshes0 := lod0.find_children("*", "MeshInstance3D", true, false).size()
		var meshes2 := lod2.find_children("*", "MeshInstance3D", true, false).size()
		assert(meshes0 > meshes2)
		macro_bounds.append(AssetVisualLibrary.bounds_of(lod0).size)
		lod0.queue_free(); lod2.queue_free()
	assert(macro_bounds[0].x < macro_bounds[3].x)
	assert(macro_bounds[5].x > macro_bounds[0].x and macro_bounds[6].y > macro_bounds[5].y)

	var holder := Node3D.new(); root.add_child(holder)
	var visual := AssetVisualLibrary.install(holder, "ship_main_53")
	assert(visual != null and visual.get_meta("classification", "") == "M153_W5_CLEAN_ROOM_GLB_PLACEHOLDER")
	assert(not bool(visual.get_meta("counts_as_final_glb", true)))
	assert(str(visual.get_meta("lod_path_selected", "")).ends_with("_lod1.glb"))
	var architecture := ShipProductionArchitecture.summary()
	assert(architecture.production_glb_placeholders == 10 and architecture.final_glb_ready == 0 and architecture.runtime_fallbacks == 45)
	assert(ResourceLoader.exists("res://scenes/qa/m153_w5_lod_qa.tscn"))
	var qa := (load("res://scenes/qa/m153_w5_lod_qa.tscn") as PackedScene).instantiate(); root.add_child(qa); await process_frame
	assert(qa.get_node_or_null("ship_main_51_LOD0") != null and qa.get_node_or_null("ship_main_60_LOD2") != null)
	print("M153_W5_LOD_BATCH_PASS")
	quit()
