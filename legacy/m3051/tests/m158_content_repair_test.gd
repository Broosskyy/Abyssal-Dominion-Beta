extends Node
func _ready()->void:
	assert(M158LegacyEncounterCatalog.band(6).get("id","")=="shoal_raiders")
	assert(M158LegacyEncounterCatalog.band(50).get("id","")=="abyssal_dominion")
	assert(M158LegacyEncounterCatalog.band(5).is_empty())
	assert(not M158LegacyEncounterCatalog.phase_profile(40).is_empty())
	var cannon:=CombatCatalog.cannon(6)
	var base:=M158CannonRuntime.modifiers(cannon,0,"spectral")
	var maxed:=M158CannonRuntime.modifiers(cannon,8,"spectral")
	assert(float(maxed.get("damage_mult",1.0))>float(base.get("damage_mult",1.0)))
	assert(float(maxed.get("range_mult",1.0))>=float(base.get("range_mult",1.0)))
	assert(M158BonusMapBossCatalog.row("legendary").get("boss_wave",0)==7)
	assert(M158HalloweenCatalog.phase(4).get("label","")=="The Drowned Crown")
