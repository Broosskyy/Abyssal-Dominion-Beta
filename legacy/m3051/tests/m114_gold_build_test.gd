extends Node
func _ready()->void:
	var d:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m114_bonusmap_gold.json"))
	assert(int(d.eligibility_level)==18);assert(int(d.structure.waves)==5);assert(d.rules.has("does not bypass Pirate Trials"))
	var b:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m114_build_specializations.json"))
	assert(int(b.unlock_level)==21);assert(b.profiles.size()>=6)
	var inv:=PlayerInventory.new()
	assert(not inv.grant_gold_bonusmap_fragment(17));assert(inv.grant_gold_bonusmap_fragment(18))
	assert(inv.count("gold_chart_fragment")==1)
	assert(inv.count("silver_chart_fragment")==0)
	var p:=Pl21To25ProgressionCatalog.level(25);assert(p.trial_focus.has("status"));assert(p.trial_focus.has("build_specialization"))
	print("M114_GOLD_BUILD_PASS")
