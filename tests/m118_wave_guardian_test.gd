extends Node
func _ready()->void:
	var d:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m118_bonusmap_waves.json"))
	assert(d.gold.size()==5);assert(d.abyss.size()==6);assert(d.abyss[5].kind=="guardian")
	var g:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m118_ancient_guardians.json"))
	assert(g.encounters.size()==3);assert(g.world_boss_prep.level==35)
	var inv:=PlayerInventory.new();inv.set_count("legendary_fragment",5);inv.set_at_port(true)
	var forge:=LegendaryFragmentForge.new();assert(forge.craft(inv));assert(inv.count("ancient_relic_core")==1)
	print("M118_WAVE_GUARDIAN_PASS")
