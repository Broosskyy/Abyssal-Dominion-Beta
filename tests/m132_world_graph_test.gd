extends Node
func _ready()->void:
	assert(WorldSectorRegistry.validate().is_empty())
	assert(WorldSectorRegistry.all().size()>=51)
	var first:=WorldSectorRegistry.by_id("SECTOR-001")
	assert(int(first.get("pirate_level",0))==1)
	var roles:=CapstoneEncounterRoles.data()
	for level in [40,45,50]:
		var row:Dictionary=(roles.levels as Dictionary).get(str(level),{})
		assert(str(row.get("boss_slot",""))!=str(row.get("hunter_slot","")))
	var errors:=ContentBehaviorEngine.validate_components([
		{"kind":"aoe_damage","amount":10,"radius":4},
		{"kind":"target_denial","duration":4},
		{"kind":"repair_block","duration":3},
		{"kind":"recall"}
	])
	assert(errors.is_empty())
	print("M132_WORLD_GRAPH_PASS")
