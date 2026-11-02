extends Node
func _ready()->void:
	assert(WorldRegionRegistry.validate().is_empty())
	assert(WorldSectorRegistry.effective_all().size()>=50)
	assert(WorldMapSystem.new().sector_data.is_empty())
	assert(VisualQualityResolver.island_budget()>0)
	assert(ProductionPlaceholderContract.ship_silhouette("SHIP-PROG-001").get("silhouette","")!="")
	assert(ProductionPlaceholderContract.ship_silhouette("SHIP-PROG-050").get("silhouette","")!="")
	var first:=ProductionPlaceholderContract.ship_silhouette("SHIP-PROG-001")
	var second:=ProductionPlaceholderContract.ship_silhouette("SHIP-PROG-002")
	assert(first.get("silhouette")!=second.get("silhouette"))
	print("M138_RUNTIME_LOD_DIVERSITY_PASS")
