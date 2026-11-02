extends SceneTree

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _run() -> void:
	var assets := P1RegionalAssetCatalog.new(); root.add_child(assets)
	var runtime := P1RegionalRuntimeCatalog.new(); root.add_child(runtime)
	var visual_catalog := P1RegionalVisualAcceptanceCatalog.new(); root.add_child(visual_catalog)
	var controller := P1RegionalEnvironmentController.new(); root.add_child(controller)
	await process_frame
	var status := visual_catalog.summary()
	assert(status.valid and status.regions == 2 and status.materials == 8)
	assert(ResourceLoader.exists(status.qa_scene))
	var holder := Node3D.new(); root.add_child(holder)
	assert(AssetVisualLibrary.install(holder,"npc_storm_raider") != null)
	P1RegionalPresentationAdapter.apply_entity(holder,"crimson_sea","ship",false)
	assert(holder.get_node("AssetVisual").get_meta("m150_material_variant","") == "crimson_sea:ship")
	var replacement_holder := Node3D.new(); root.add_child(replacement_holder)
	var replacement_visual := Node3D.new(); replacement_visual.name = "AssetVisual"; replacement_visual.set_meta("classification","USER_REPLACEMENT"); replacement_holder.add_child(replacement_visual)
	P1RegionalPresentationAdapter.apply_world_asset(replacement_holder,"drowned_reach","world")
	assert(not replacement_visual.has_meta("m150_material_variant"))
	var water := WaterSurface.new(); root.add_child(water); await process_frame
	water.apply_region_profile(P1RegionalVisualAcceptanceCatalog.region("crimson_sea").water)
	assert(is_equal_approx(float((water.material_override as ShaderMaterial).get_shader_parameter("wave_speed")),0.50))
	var progression: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/m150_master_ship_progression_guard.json"))
	assert(progression.starter_ships.count == 3 and progression.regular_ship_classes.count == 100 and progression.prestige_ship_classes.count == 5)
	print("M150_P1_REGIONAL_VISUAL_ACCEPTANCE_PASS")
	quit()
