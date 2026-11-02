extends SceneTree
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		print("FAIL: " + label)

func run() -> void:
	check(GuildContracts.validate().is_empty(), "guild contracts validate")
	var contracts := GuildContracts.read_contracts()
	check(contracts.authority == "contract_only_local_prototype", "guild state is contract-only")
	check(contracts.live_authority_required == true, "live guild authority explicitly required")
	check(GuildContracts.has_permission("guild_master", "island_build"), "guild master island-build permission contract")
	check(not GuildContracts.has_permission("recruit", "treasury_spend"), "recruit cannot spend treasury by contract")
	var island := GuildContracts.read_island_slots()
	check(island.ownership_persistence == false, "M35 island slots do not fake ownership persistence")
	check(island.slots.size() == 12, "all 12 modular guild-island visual slots prepared")
	for id in ["island_base", "harbor", "guild_hall", "warehouse", "repair_station", "walls", "tower_cannon", "tower_mortar", "tower_chain", "tower_guardian", "decoration_layer", "event_layer"]:
		check(island.slots.has(id), "guild-island slot " + id)
	var neutral := Node.new()
	root.add_child(neutral)
	neutral.set_meta("passive_until_attacked", true)
	neutral.set_meta("provoked", false)
	check(EncounterRelation.status(neutral) == EncounterRelation.NEUTRAL, "passive beginner encounter presents neutral")
	neutral.set_meta("provoked", true)
	check(EncounterRelation.status(neutral) == EncounterRelation.HOSTILE, "provoked encounter presents hostile")
	neutral.queue_free()
	print(JSON.stringify({"suite": "M35", "checks": checks, "failures": failures, "engine": Engine.get_version_info().string}))
	quit(0 if failures.is_empty() else 1)
