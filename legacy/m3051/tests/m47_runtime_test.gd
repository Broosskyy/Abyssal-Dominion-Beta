extends Node
func _ready() -> void:
	var contract := JSON.parse_string(FileAccess.get_file_as_string("res://data/m47_runtime_contract.json"))
	assert(WorldMapSystem.GRID_SIZE == Vector2i(4, 4))
	assert(WorldMapSystem.SECTORS.has(Vector2i(2, 3)))
	assert(int(WorldMapSystem.SECTORS[Vector2i(2, 3)].level) == 15)
	assert(MainProgressionFleet.data().designs.size() == 50)
	assert(SupportPayloadCatalog.harpoon_payloads().size() == 3)
	assert(SupportPayloadCatalog.support_ammo().size() == 3)
	assert(contract.runtime_features.support_fire_runtime == true)
	print("M47_RUNTIME_CONTRACT_PASS")
