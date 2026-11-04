extends Node
func _ready()->void:
	var budget:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m75_mobile_presentation_budget.json"))
	var audit:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m75_integrity_audit.json"))
	var layout:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m75_mobile_layout_qa.json"))
	assert(budget.profiles.size()==3)
	assert(audit.confirmed_fixes.size()>=6)
	assert(layout.representative_viewports.size()==5)
	assert(MobilePresentationBudget.int_value(Vector2(960,540),320.0,"world_poi",99)<=5)
	print("M75_INTEGRITY_PASS")
