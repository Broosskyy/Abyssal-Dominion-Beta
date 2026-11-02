extends Node
func _ready()->void:
	assert(WorldMapSystem.GRID_SIZE==Vector2i(7,6))
	for level in range(31,36):
		var found:=false
		for c in WorldMapSystem.SECTORS:
			if int(WorldMapSystem.SECTORS[c].level)==level:found=true
		assert(found)
	var p:=Pl31To35ProgressionCatalog.level(35);assert(p.pirate_trial);assert(p.trial_focus.has("world_boss_preparation"))
	var i:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m117_bonusmap_instances.json"));assert(i.instances.abyss.waves.size()==6)
	var inv:=PlayerInventory.new();assert(inv.grant_ancient_guardian_drop(30)==0);assert(inv.grant_ancient_guardian_drop(31)==1)
	print("M117_INSTANCE_PL31_35_PASS")
