extends Node
func _ready()->void:
	var r:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m77_beginner_progression_reconciliation.json"))
	assert(r.status=="RECONCILED")
	assert(int(r.canonical.medium.reward_after_beginner_assignment)==2)
	assert(int(r.canonical.large.reward_after_beginner_assignment)==3)
	assert(BeginnerRules.SHIP_REWARDS[2]=="clipper")
	assert(BeginnerRules.SHIP_REWARDS[3]=="chalupa")
	print("M77_PROGRESSION_RECONCILIATION_PASS")
