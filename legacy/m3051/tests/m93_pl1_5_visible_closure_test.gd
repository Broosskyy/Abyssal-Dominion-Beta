extends Node
func _ready()->void:
	var budget:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m93_mobile_visual_budget.json"))
	assert(int(budget.phone.wreck_props_max)==3)
	assert(int(budget.phone.monster_warning_props_max)==2)
	assert(int(budget.phone.island_secondary_details_max)==1)
	var next:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m94_admin_halloween_contract.json"))
	assert(bool(next.admin_mode.required))
	assert(bool(next.halloween_event.required))
	assert(str(next.halloween_event.working_id)=="halloween_abyss_01")
	var prod:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m93_asset_production_wave.json"))
	assert(prod.master_first_13.size()==13)
	print("M93_PL1_5_VISIBLE_CLOSURE_PASS")
