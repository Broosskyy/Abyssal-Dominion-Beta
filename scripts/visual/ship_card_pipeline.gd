class_name ShipCardPipeline
extends RefCounted
const PATH := "res://data/ship_card_render_pipeline.json"

static func contract() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

static func model_slot(ship_id: String) -> String:
	return ShipyardVisualResolver.model_slot_for(ship_id)

static func card_slot(ship_id: String) -> String:
	return ShipyardVisualResolver.card_slot_for(ship_id)

static func diagnostic(ship_id: String) -> Dictionary:
	var model_id := model_slot(ship_id)
	var card_id := card_slot(ship_id)
	var model_override: Variant = VisualAssetCatalog.overrides.get("models",{}).get(model_id,{})
	var card_override: Variant = VisualAssetCatalog.overrides.get("ui",{}).get(card_id,{})
	var model_path := str(model_override.get("path","")) if model_override is Dictionary else ""
	var card_path := str(card_override.get("path","")) if card_override is Dictionary else ""
	return {
		"ship_id":ship_id,
		"model_slot":model_id,
		"card_slot":card_id,
		"model_override":not model_path.is_empty() and ResourceLoader.exists(model_path),
		"card_override":not card_path.is_empty() and ResourceLoader.exists(card_path),
		"model_configured":not model_path.is_empty(),
		"card_configured":not card_path.is_empty(),
		"model_path":model_path,
		"card_path":card_path,
	}
