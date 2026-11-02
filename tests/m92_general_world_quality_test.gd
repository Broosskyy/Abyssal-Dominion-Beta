extends Node
func _ready()->void:
	var perf:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m92_world_quality_performance.json"))
	assert(int(perf.wreck.context_object_cap)==3)
	assert(int(perf.monster_warning.context_object_cap)==2)
	assert(not bool(perf.harbor.service_truth_from_visibility))
	assert(bool(perf.p0_npc.quad_mesh_cache))
	assert(bool(perf.markers.total_budget_unchanged))
	var harbor:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m71_havens_reach_composition.json"))
	assert(str(harbor.milestone)=="M92")
	var island:=GuildIslandComposer.create(Vector3.ZERO,2)
	var tower:=GuildIslandComposer.tower_rows(island)[0]
	assert(not bool(tower.live_damage))
	var prod:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m92_asset_production_wave.json"))
	assert(prod.master_first_13.size()==13)
	print("M92_GENERAL_WORLD_QUALITY_PASS")
