extends Node
func _ready()->void:
	var audit:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m80_native_readiness_audit.json"))
	var c:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m80_fallback_consolidation.json"))
	assert(audit.status=="STATIC_SOURCE_READY_NATIVE_PENDING")
	assert((audit.selected_project_class_refs_missing as Array).is_empty())
	assert(c.converted_consumers.size()>=6)
	assert(FallbackPrimitiveLibrary.box(Vector3.ONE)==FallbackPrimitiveLibrary.box(Vector3.ONE))
	assert(WorldMarkerPriorityCatalog.priority("objective")>WorldMarkerPriorityCatalog.priority("wreck"))
	print("M80_NATIVE_READINESS_PASS")
