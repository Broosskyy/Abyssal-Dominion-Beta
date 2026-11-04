extends SceneTree

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _run() -> void:
	var assets := P1RegionalAssetCatalog.new(); root.add_child(assets)
	var runtime := P1RegionalRuntimeCatalog.new(); root.add_child(runtime)
	await process_frame
	var status := runtime.summary()
	assert(status.valid and status.regions == 2 and status.platforms == 3)
	assert(status.server_authoritative and status.global_locked)
	var crimson := WorldRegionRegistry.by_id("crimson_sea")
	var drowned := WorldRegionRegistry.by_id("drowned_reach")
	assert(crimson.monster_slots.size() == 3 and drowned.monster_slots.size() == 4)
	var crimson_pool := DynamicSpawnPoolResolver.resolve(self, {}, crimson, [])
	assert("npc_storm_admiral" in crimson_pool.admiral_ids)
	assert("monster_krakenling_01" in crimson_pool.monster_ids)
	var crimson_table := DynamicSpawnTable.effective(self, "test-crimson", "crimson_sea", crimson_pool, {"slots":["raider","scout"]})
	assert(crimson_table.slot_count == 4 and crimson_table.admiral_kills_required == 8)
	assert(is_equal_approx(float(crimson_table.admiral_cooldown_seconds),45.0))
	assert(WorldVisualContentResolver.island_slots(self,"test-crimson",crimson,[])[0] == "island_module_crimson_coast_01")
	assert(P1RegionalRuntimeCatalog.nature_slots("drowned_reach").size() == 3)
	var hero := Node3D.new(); root.add_child(hero)
	P1RegionalPresentationAdapter.apply_entity(hero,"drowned_reach","drowned_admiral",true)
	assert(hero.get_meta("m149_region","") == "drowned_reach")
	assert(hero.get_node_or_null("M149RegionalAccent") != null)
	assert(str(hero.get_meta("m149_lod","")).begins_with("LOD"))
	print("M149_P1_REGIONAL_RUNTIME_PASS")
	quit()
