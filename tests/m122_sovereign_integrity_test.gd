extends Node
func _ready()->void:
	assert(WorldMapSystem.GRID_SIZE==Vector2i(9,6))
	for level in range(41,46):assert(not Pl41To45ProgressionCatalog.level(level).is_empty())
	assert(Pl41To45ProgressionCatalog.requires_trial(45))
	assert(not Pl41To45ProgressionCatalog.requires_trial(44))
	var post:=PostBeginnerProgress.new()
	post.import_state({"void_elite_chains":{40:2},"sovereign_prestige":{41:1}})
	assert(int(post.void_elite_chains.get(40,0))==2)
	assert(int(post.sovereign_prestige.get(41,0))==1)
	print("M122_SOVEREIGN_INTEGRITY_PASS")
