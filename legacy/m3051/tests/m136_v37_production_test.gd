extends Node
func _ready()->void:
	assert(ProductionPlaceholderContract.audit().is_empty())
	assert(not ProductionPlaceholderContract.slot("SHIP-STARTER-001").is_empty())
	assert(WorldSectorRegistry.runtime_data("SECTOR-001").get("level",0)==1)
	var high:=SectorGraph.sector_id_for_level(50);assert(not high.is_empty())
	var row:=WorldSectorRegistry.by_id(high);assert(str(row.get("port",""))=="Dominion Gate")
	assert(SectorGraph.validate_progression_path(1,50).is_empty())
	print("M136_V37_PRODUCTION_PASS")
