extends Node
func _ready()->void:
	var guide:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m76_first_session_guidance.json"))
	var qa:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m76_first_session_qa.json"))
	var reconciliation:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m76_beginner_progression_reconciliation.json"))
	assert(guide.steps.size()==3)
	assert(qa.sequence.size()==8)
	assert(reconciliation.status=="OPEN_RECONCILIATION_REQUIRED")
	assert(BeginnerRules.START_SHIP=="barco_low")
	print("M76_FIRST_SESSION_PASS")
