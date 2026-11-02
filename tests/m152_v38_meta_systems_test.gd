extends SceneTree

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _run() -> void:
	var companions := CompanionCatalog.new(); root.add_child(companions)
	var artifacts := ArtifactCatalog.new(); root.add_child(artifacts)
	var afk_catalog := AfkRewardCatalog.new(); root.add_child(afk_catalog)
	await process_frame
	assert(CompanionCatalog.summary().valid and CompanionCatalog.all().size() == 6)
	assert(ArtifactCatalog.summary().valid and ArtifactCatalog.all().size() == 6)
	assert(AfkRewardCatalog.summary().valid and AfkRewardCatalog.profiles().size() == 4)
	assert(AfkRewardCatalog.cap_seconds() == 28800)

	var player := Node3D.new(); root.add_child(player); player.position = Vector3(4.0, 0.55, 3.0)
	var companion := CompanionRuntime.new(); companion.configure(player); root.add_child(companion)
	await process_frame
	assert(companion.visual_holder != null and companion.visual_holder.get_meta("gameplay_authority", true) == false)
	assert(companion.equip("COMPANION-SALVAGE-CRAB").ok)
	assert(not companion.equip("COMPANION-UNKNOWN").ok)

	var loadout := ArtifactLoadout.new(); root.add_child(loadout); await process_frame
	assert(loadout.equipped.size() == 2 and loadout.effect_preview().size() == 2)
	assert(loadout.effect_preview()[0].applied_to_gameplay == false)
	assert(not loadout.equip(["ARTIFACT-STAR-COMPASS", "ARTIFACT-TIDE-BULWARK", "ARTIFACT-WAR-CAPSTAN"]).ok)

	var preview_service := AfkRewardService.new(); root.add_child(preview_service); await process_frame
	var preview := preview_service.preview("AFK-PROFILE-HARBOR-OPS", 86400)
	assert(preview.ok and preview.seconds == 28800 and preview.capped)
	assert(preview.authority == "LOCAL_PREVIEW_ONLY" and preview.production_requires_trusted_server_time)
	var encoded := JSON.stringify(preview).to_lower()
	for forbidden in AfkRewardCatalog.forbidden(): assert(str(forbidden).to_lower() not in encoded)
	var service_player := ShipMotor.new(); root.add_child(service_player)
	var state := GameState.new(); root.add_child(state)
	var services := ServiceLocator.new(); root.add_child(services); services.configure(service_player, state)
	await process_frame
	var first_claim := preview_service.claim(preview, "M152-TEST-CLAIM")
	var duplicate_claim := preview_service.claim(preview, "M152-TEST-CLAIM")
	assert(first_claim.ok and not first_claim.duplicate and first_claim.authority == "LOCAL_PREVIEW_ONLY")
	assert(duplicate_claim.ok and duplicate_claim.duplicate)

	var admin := AdminContentRegistry.new(); root.add_child(admin); await process_frame
	assert(admin.supported_types().size() == 30)
	assert("companion" in admin.supported_types() and "artifact" in admin.supported_types() and "afk_reward_profile" in admin.supported_types())
	print("M152_V38_META_SYSTEMS_PASS")
	quit()
