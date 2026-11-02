extends Node
func _ready()->void:
	var s1:=ProductionPlaceholderContract.ship_silhouette("SHIP-STARTER-001")
	var s2:=ProductionPlaceholderContract.ship_silhouette("SHIP-STARTER-002")
	var s3:=ProductionPlaceholderContract.ship_silhouette("SHIP-STARTER-003")
	assert(not s1.is_empty() and not s2.is_empty() and not s3.is_empty())
	assert(s1.get("silhouette")!=s2.get("silhouette") and s2.get("silhouette")!=s3.get("silhouette"))
	for i in range(1,6):
		assert(not ProductionPlaceholderContract.ship_silhouette("NPC-SHIP-EARLY-%03d"%i).is_empty())
	assert(P0HudIconRegistry.production_slot("ammo_menu")=="ICON-AMMO")
	assert(P0HudIconRegistry.min_touch_size()>=48.0)
	var p0:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m140_p0_replacement_readiness.json"))
	assert(str(p0.get("milestone",""))=="M141")
	assert((p0.get("assets",[]) as Array).size()==22)
	print("M141_P0_PRODUCTION_POLISH_PASS")
