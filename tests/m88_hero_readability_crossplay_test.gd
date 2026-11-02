extends Node
func _ready()->void:
	var harbor:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m71_havens_reach_composition.json"))
	var tiers:Dictionary={"landmark":0,"secondary":0,"dressing":0}
	for row in harbor.modules:tiers[str(row.get("visual_tier","dressing"))]+=1
	assert(int(tiers["landmark"])==3)
	var cross:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m88_crossplay_presentation_audit.json"))
	assert("device-specific damage" in cross.forbidden)
	var prod:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m88_asset_production_wave.json"))
	assert(prod.master_first_13.size()==13)
	print("M88_HERO_READABILITY_CROSSPLAY_PASS")
