extends Node
func _ready()->void:
	var safety:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m87_hud_gesture_safety.json"))
	assert(float(safety.touch_edge_guard)>=18.0)
	var profiles:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m71_island_composition_profiles.json"))
	assert(str(profiles.profiles.cliff_cove.silhouette)=="cliff_crescent")
	assert(str(profiles.profiles.thin_spit.silhouette)=="thin_hook")
	var harbor:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m71_havens_reach_composition.json"))
	var found_cart:=false
	for row in harbor.modules:
		if str(row.slot)=="prop_harbor_cart_01":found_cart=true
	assert(found_cart)
	var prod:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m87_asset_production_wave.json"))
	assert(prod.master_first_13.size()==13)
	print("M87_SAFE_AREA_ISLAND_POLISH_PASS")
