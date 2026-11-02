class_name M209AssetProductionCatalog
extends RefCounted
## Production-facing sheet IDs. Runtime gameplay must not depend on generation-sheet coordinates.

const SHEET_MAX := 8
const SMALL_SIZE_CHECKS := [96, 64, 48]

static func validate_sheet_count(count:int)->bool:
	return count > 0 and count <= SHEET_MAX

static func authored_asset_rules()->Dictionary:
	return {
		"transparent_background": true,
		"generous_spacing": true,
		"distinct_silhouette": true,
		"individual_master_before_runtime_atlas": true,
		"gameplay_stats_in_art": false
	}
