extends Node
func _ready()->void:
	assert(WorldMapSystem.GRID_SIZE==Vector2i(8,6))
	for level in range(36,41):assert(not Pl36To40ProgressionCatalog.level(level).is_empty())
	assert(Pl36To40ProgressionCatalog.requires_trial(40))
	assert(not Pl36To40ProgressionCatalog.requires_trial(39))
	print("M121_VOID_PROGRESSION_PASS")
