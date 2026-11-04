extends Node
func _ready()->void:
	assert(WorldRegionRegistry.validate().is_empty())
	assert(WorldRegionRegistry.all().size()==10)
	assert(str(WorldRegionRegistry.for_level(1).get("display_name",""))=="Shattered Shores")
	assert(str(WorldRegionRegistry.for_level(50).get("canonical_harbor",""))=="Dominion Gate")
	assert(ProductionPlaceholderContract.audit().is_empty())
	assert(not ProductionPlaceholderContract.slot("SHIP-PROG-050").is_empty())
	assert(not ProductionPlaceholderContract.slot("ISLAND-BASE-020").is_empty())
	assert(not ProductionPlaceholderContract.slot("HARBOR-DOMINION-GATE").is_empty())
	assert(SectorGraph.validate_progression_path(1,50).is_empty())
	print("M137_WORLD_PRODUCTION_PASS")
