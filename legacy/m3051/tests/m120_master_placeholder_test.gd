extends Node
func _ready()->void:
	var ids:=M120PlaceholderAudit.all_ship_ids()
	assert(ids.size()==53)
	assert(ids.has("SHIP-STARTER-001"))
	assert(ids.has("SHIP-PROG-050"))
	assert(M120PlaceholderAudit.missing_contracts().is_empty())
	var d:=M120PlaceholderAudit.data()
	assert(d.get("main_progression",[]).size()==50)
	print("M120_MASTER_PLACEHOLDER_PASS")
