extends Node
func _ready()->void:
	assert(WorldMapSystem.GRID_SIZE==Vector2i(6,6))
	assert(int(WorldMapSystem.SECTORS[Vector2i(1,5)].level)==21)
	assert(int(WorldMapSystem.SECTORS[Vector2i(5,5)].level)==25)
	assert(Pl21To25ProgressionCatalog.requires_trial(25))
	var p:=PostBeginnerProgress.new();p.add_map_xp(25,999999);p.record_boss_clear(25)
	for i in range(Pl21To25ProgressionCatalog.hunter_required(25)):p.record_hunter(25)
	for i in range(Pl21To25ProgressionCatalog.region_required(25)):p.record_region_objective(25)
	p.record_status_objective(25);p.record_build_objective(25)
	assert(p.trial_ready(25));assert(p.claim_trial(25));assert(p.level_complete(25))
	var monsters:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m113_cursed_monster_encounters.json"))
	assert(monsters.encounters.size()==2)
	print("M113_PL21_25_MONSTER_PASS")
