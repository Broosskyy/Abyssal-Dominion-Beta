extends Node

func _ready() -> void:
	var modules := AdminModuleRegistry.new()
	add_child(modules)
	await get_tree().process_frame
	assert(modules.all_modules().size() == 18)
	assert(not modules.by_id("content").is_empty())
	assert(not modules.by_id("settings").is_empty())

	var registry := AdminContentRegistry.new()
	add_child(registry)
	await get_tree().process_frame
	for required_type in ["ship", "npc", "cannon", "ammo", "badge", "branding_asset", "sector", "poi"]:
		assert(required_type in registry.supported_types())
	var badge := registry.create_draft("badge", "BADGE-LOCAL-TEST", "Local Badge")
	badge["icon_slot"] = "UI-BADGE-LOCAL-TEST"
	assert(registry.validate_record(badge).is_empty())
	assert(registry.set_local_status("BADGE-LOCAL-TEST", "validated"))
	assert(not registry.set_local_status("BADGE-LOCAL-TEST", "active"))

	var snapshots := ContentSnapshotService.new()
	add_child(snapshots)
	assert(not snapshots.apply_verified_snapshot({"format":"abyssal-content-snapshot-v1"}, true))
	var valid := {"format":"abyssal-content-snapshot-v1", "environment":"TEST", "content_version":"m143-test", "generated_at":"2026-09-01T00:00:00Z", "records":[], "asset_slots":{}, "content_hash":"test", "signature":"server-test"}
	assert(not snapshots.apply_verified_snapshot(valid, false))
	assert(snapshots.apply_verified_snapshot(valid, true))
	assert(snapshots.server_verified)
	print("M143_UNIFIED_ADMIN_PASS")
