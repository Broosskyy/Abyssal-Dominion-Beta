extends SceneTree

func _initialize()->void:
	root.set_meta("reconstruction_test_mode",true)
	_run.call_deferred()

func _run()->void:
	var integration:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/m155_system_integration.json"))
	assert(integration is Dictionary)
	assert(int(integration.bonusmaps.get("silver_gold_abyss_legendary",false))==1)
	assert(int(integration.cannons.roles)==7)
	assert(int(integration.loot.physical_clean_room_glbs)==5)
	var runway:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/m155_progression_runway.json"))
	assert(runway is Dictionary and int(runway.live_map_cap)==50)
	assert((runway.staged_next_band.levels as Array).size()==10)
	var cannon_data:=CombatCatalog.m155_progression_data()
	assert((cannon_data.get("upgrade_tiers",[]) as Array).size()==5)
	assert(CombatCatalog.preferred_ammo_ids(CombatCatalog.CANNONS[0]).size()>=3)
	for path in [
		"res://assets/production_placeholders/m155_loot/loot_coin_cache.glb",
		"res://assets/production_placeholders/m155_loot/loot_salvage_bundle.glb",
		"res://assets/production_placeholders/m155_loot/loot_tier_chest.glb",
		"res://assets/production_placeholders/m155_loot/loot_admiral_vault.glb",
		"res://assets/production_placeholders/m155_loot/repair_crate_m155.glb"]:
		assert(FileAccess.file_exists(path))
	var p:=ExtendedBonusMapProgress.new()
	p.kind="silver"
	root.add_child(p)
	p.import_state({"active":true,"wave":2,"wave_kills":2,"completions":3,"entry_receipt":{"item":"silver_chart_fragment","amount":999}})
	assert(p.active and p.wave==2 and p.completions==3)
	assert(p.entry_receipt.is_empty())
	var state:=p.export_state()
	assert(state.has("wave_kills") and not state.has("entry_receipt"))
	print("M155_SYSTEM_INTEGRATION_PASS")
	quit()
