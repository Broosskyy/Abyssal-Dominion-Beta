extends Node
func _ready()->void:
	assert(StableContentSeed.from_parts(["SECTOR-001","v1","world"])==StableContentSeed.from_parts(["SECTOR-001","v1","world"]))
	assert(StableContentSeed.from_parts(["SECTOR-001","v1","world"])!=StableContentSeed.from_parts(["SECTOR-002","v1","world"]))
	var world:=WorldMapSystem.new();world.mark_poi_consumed("SECTOR-001::POI-WRECK-00")
	assert(world.poi_consumed("SECTOR-001::POI-WRECK-00"))
	var state:=world.export_poi_state();var restored:=WorldMapSystem.new();restored.import_poi_state(state)
	assert(restored.poi_consumed("SECTOR-001::POI-WRECK-00"))
	var p0:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m142_p0_vertical_slice_runtime.json"))
	assert((p0.get("starter_fleet",[]) as Array).size()==3)
	assert((p0.get("npc_visual_rotation",{}) as Dictionary).size()==5)
	print("M142_P0_RUNTIME_CLOSURE_PASS")
