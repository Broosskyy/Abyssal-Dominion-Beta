extends Node
func _ready() -> void:
	var closure := JSON.parse_string(FileAccess.get_file_as_string("res://data/m69_pl1_5_closure_audit.json"))
	var debt := JSON.parse_string(FileAccess.get_file_as_string("res://data/m69_technical_debt_audit.json"))
	assert(closure.closure_state == "SOURCE_READY_BUT_NOT_NATIVE_ACCEPTED")
	assert(debt.fixed.size() >= 6)
	assert(TargetVisualCatalog.frame_slot(_neutral_probe()) == "hud_target_neutral")
	assert(TargetVisualCatalog.relation_label(_neutral_probe()) == "NEUTRAL")
	print("M69_CLOSURE_CLEANUP_PASS")

func _neutral_probe() -> Node3D:
	var node := Node3D.new()
	node.set_meta("passive_until_attacked",true)
	node.set_meta("provoked",false)
	add_child(node)
	return node
