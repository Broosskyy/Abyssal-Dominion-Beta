extends Node
func _ready() -> void:
	var catalog:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m72_poi_catalog.json"))
	var wave:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m72_asset_production_wave.json"))
	var instancing:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m72_nature_instancing_contract.json"))
	assert(catalog.types.size()==6)
	assert(catalog.pl1_5_mix.size()==5)
	assert(wave.recommended_next_assets.size()==10)
	assert(bool(instancing.families[0].batch_candidate))
	var slots:=JSON.parse_string(FileAccess.get_file_as_string("res://data/visual_slots.json"))
	assert(slots.models.has("poi_wreck_site_01"))
	assert(slots.ui.has("m72_poi_salvage"))
	print("M72_POI_CONTENT_PASS")
