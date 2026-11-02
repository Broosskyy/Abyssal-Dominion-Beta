extends Node
func _ready()->void:
	assert(WorldMapSystem.GRID_SIZE==Vector2i(6,6))
	for level in range(26,31):
		var found:=false
		for c in WorldMapSystem.SECTORS:
			if int(WorldMapSystem.SECTORS[c].level)==level:found=true
		assert(found)
	var p:=Pl26To30ProgressionCatalog.level(30);assert(p.pirate_trial);assert(p.trial_focus.has("corruption"))
	var c:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m115_corruption.json"));assert(c.opt_in)
	var inv:=PlayerInventory.new();assert(not inv.grant_abyss_progression_drop(25));assert(inv.grant_abyss_progression_drop(26));assert(inv.count("abyss_scale")==1)
	var a:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m115_bonusmap_abyss.json"));assert(int(a.eligibility_level)==26)
	print("M115_ABYSS_PROGRESSION_PASS")
