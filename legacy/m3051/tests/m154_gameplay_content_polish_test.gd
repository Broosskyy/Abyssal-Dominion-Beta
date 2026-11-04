extends SceneTree
func _initialize()->void:
	root.set_meta("reconstruction_test_mode",true);_run.call_deferred()
func _run()->void:
	var expansion:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/m154_bonusmap_expansion.json"));assert(expansion is Dictionary)
	assert(expansion.maps.has("silver") and expansion.maps.has("legendary"));assert(expansion.maps.silver.waves.size()==4 and expansion.maps.legendary.waves.size()==4)
	var instances:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/m117_bonusmap_instances.json"));assert(instances.instances.has("silver") and instances.instances.has("legendary"))
	var waves:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/m118_bonusmap_waves.json"));assert(waves.silver.size()==4 and waves.legendary.size()==4)
	assert(CombatCatalog.CANNONS.size()>=7);var roles:=[]
	for row in CombatCatalog.CANNONS:roles.append(str(row.role))
	assert("marksman" in roles and "brawler" in roles and "endgame_siege" in roles)
	var parent:=Node3D.new();root.add_child(parent);var coin:=LootVisual.build(parent,false,false,"common","coins");var salvage:=LootVisual.build(parent,false,false,"rare","salvage_chest");assert(coin!=null and salvage!=null);assert(coin!=salvage)
	var polish:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/m154_gameplay_content_polish.json"));assert(polish.progression.bonusmaps.size()==4 and polish.admin.retain_unified_admin)
	print("M154_GAMEPLAY_CONTENT_POLISH_PASS");quit()
