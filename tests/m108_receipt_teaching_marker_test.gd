extends Node
func _ready()->void:
	var qa:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m108_reward_receipt_qa.json"))
	assert(bool(qa.not_persistent_ledger))
	var marker:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m108_mobile_lod_marker_audit.json"))
	assert(not bool(marker.whole_hull_visibility_from_shadow_distance))
	var batch:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m108_p0_replacement_batch.json"))
	assert(batch.assets.size()==13)
	assert(int(batch.summary.native_pass)==0)
	assert(WorldMarkerPriorityCatalog.priority("guild_objective")==84)
	print("M108_RECEIPT_TEACHING_MARKER_PASS")
