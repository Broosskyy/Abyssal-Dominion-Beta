extends Node
func _ready() -> void:
	var contract := JSON.parse_string(FileAccess.get_file_as_string("res://data/m52_shipyard_contract.json"))
	var pipeline := JSON.parse_string(FileAccess.get_file_as_string("res://data/ship_card_render_pipeline.json"))
	assert(contract.shipyard.dedicated_3d_preview == true)
	assert(contract.shipyard.all_3_starter_and_50_main_designs_browsable == true)
	assert(contract.pipeline.runtime_thumbnail_capture_claimed == false)
	assert(pipeline.card_contract.recommended_resolution == [512,384])
	assert(ShipyardVisualResolver.model_slot_for("ship_main_01") == "ship_main_01")
	assert(ShipyardVisualResolver.fallback_model_slot_for("ship_main_01") != "")
	assert(ShipCardPipeline.card_slot("ship_main_01") == "ship_card_main_01")
	print("M52_SHIPYARD_CONTRACT_PASS")
