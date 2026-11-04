extends Node
func _ready()->void:
	assert(M157EncounterProfileCatalog.level(51).get("region","")=="dreadwater_march")
	assert(M157EncounterProfileCatalog.level(60).get("region","")=="iron_maw_reach")
	assert(not M157EncounterProfileCatalog.signature(55).is_empty())
	assert(not M157BonusMapRewardCatalog.map_row("legendary").is_empty())
	assert(M157BonusMapRewardCatalog.completion_summary("silver").length()>0)
