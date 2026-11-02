extends SceneTree

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _run() -> void:
	var catalog := ShipProductionArchitecture.new(); root.add_child(catalog)
	await process_frame
	var status := catalog.summary()
	assert(status.valid and status.regular_slots == 50 and status.prestige_slots == 5 and status.silhouette_families == 10)
	assert(status.final_glb_ready == 0 and status.production_glb_placeholders == 10 and status.runtime_fallbacks == 45)
	assert(ResourceLoader.exists(status.qa_scene))
	var qa := (load(status.qa_scene) as PackedScene).instantiate(); root.add_child(qa); await process_frame
	assert(qa.get_node_or_null("ship_main_53") != null and qa.get_node_or_null("prestige_p5") != null)
	qa.queue_free()
	var entries := ShipProductionArchitecture.all_entries()
	assert(entries.size() == 55)
	var paths := {}
	for row in entries: paths[str(row.path)] = true
	assert(paths.size() == 55)
	var cutter := ShipProductionArchitecture.entry("ship_main_53")
	var galleass := ShipProductionArchitecture.entry("ship_main_58")
	assert(cutter.family == "dread_cutter" and galleass.family == "iron_galleass")
	assert(not is_equal_approx(float(cutter.recipe.width), float(galleass.recipe.width)))
	var holder := Node3D.new(); root.add_child(holder)
	var visual := AssetVisualLibrary.install(holder,"ship_main_53")
	assert(visual != null and visual.get_meta("classification","") == "M153_W5_CLEAN_ROOM_GLB_PLACEHOLDER")
	assert(not bool(visual.get_meta("counts_as_final_glb",true)))
	assert((visual.find_children("*","MeshInstance3D",true,false) as Array).size() >= 8)
	var class100 := MainProgressionFleet.design("ship_main_100")
	var prestige := MainProgressionFleet.prestige_design(5)
	assert(class100.ship_mastery_levels == 10 and class100.silhouette_family == "dominion_sovereign")
	assert(prestige.prestige_rank == "P5" and prestige.unlock.meaning == "prestige_eligibility_only")
	var admin := AdminContentRegistry.new(); root.add_child(admin); await process_frame
	var ship_schema := admin.type_schema("ship")
	assert("asset_slot" in ship_schema.fields and "silhouette_profile" in ship_schema.fields and "lod2_path" in ship_schema.fields)
	print("M151_LATE_FLEET_PRODUCTION_PASS")
	quit()
