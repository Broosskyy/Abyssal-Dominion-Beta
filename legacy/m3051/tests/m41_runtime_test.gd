extends Node

func _ready() -> void:
	var ids := ActionItemCatalog.item_ids()
	for id in ["repair", "boost", "veil", "storm_bolt", "infernal_barrel", "crystal_barrier", "armor_corrosive", "repair_blocker", "leviathan_hook", "recall_compass"]:
		assert(ids.has(id))
		assert(PlayerInventory.START_STOCK.has(id))
	assert(ActionItemCatalog.item("storm_bolt").target == "hostile")
	assert(ActionItemCatalog.item("leviathan_hook").target == "monster")
	assert(ActionItemCatalog.item("crystal_barrier").effect == "temporary_barrier")
	print("M41_RUNTIME_CONTRACT_PASS")
