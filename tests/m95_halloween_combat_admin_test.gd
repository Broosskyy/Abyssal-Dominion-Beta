extends Node
func _ready()->void:
	var e:=JSON.parse_string(FileAccess.get_file_as_string("res://data/event_framework.json"))
	assert(e.events.halloween_abyss_01.phases.size()==3)
	assert(HalloweenEventEncounters.DEFINITIONS.size()==5)
	for id in ["event_halloween_npc_sloop_01","event_halloween_npc_raider_01","event_halloween_admiral_01","event_halloween_monster_01","event_halloween_boss_01"]:
		assert(HalloweenEventEncounters.DEFINITIONS.has(id))
	var audit:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m95_halloween_combat_audit.json"))
	assert(bool(audit.combat.canonical_health))
	assert(bool(audit.combat.canonical_weapons))
	assert(bool(audit.combat.canonical_enemy_ai))
	assert(not bool(audit.event_progress.live_authority))
	assert(not bool(audit.admin.production_authority))
	var prod:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m95_asset_production_wave.json"))
	assert(prod.master_first_13.size()==13)
	print("M95_HALLOWEEN_COMBAT_ADMIN_PASS")
