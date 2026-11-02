extends Node
func _ready()->void:
	var integrity:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m81_integrity_closure.json"))
	assert(integrity.status=="SOURCE_INTEGRITY_CLOSED_NATIVE_PENDING")
	assert(int(BeginnerRules.SHIP_REWARDS.keys()[0]) in [2,3])
	assert(BeginnerRules.SHIP_REWARDS[2]=="clipper")
	assert(BeginnerRules.SHIP_REWARDS[3]=="chalupa")
	assert(not bool(integrity.beginner_progression.pre_version_m31.legacy_clipper_fabricated))
	assert(not bool(integrity.shipyard.unowned_main_design_purchase))
	assert(float(integrity.visual_budget.compact_phone_visibility_end)==28.0)
	print("M81_INTEGRITY_CLOSURE_PASS")
