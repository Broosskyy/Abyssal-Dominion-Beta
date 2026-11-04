extends Node
func _ready() -> void:
	var acceptance := JSON.parse_string(FileAccess.get_file_as_string("res://data/m70_pl1_5_native_acceptance.json"))
	var content := JSON.parse_string(FileAccess.get_file_as_string("res://data/m70_world_content_slots.json"))
	var budget := JSON.parse_string(FileAccess.get_file_as_string("res://data/m70_mobile_content_graphics_budget.json"))
	assert(acceptance.required_sequence.size() >= 12)
	assert(content.models.size() == 10)
	assert(int(budget.touch.minimum_core_target_px) == 56)
	var slots := JSON.parse_string(FileAccess.get_file_as_string("res://data/visual_slots.json"))
	assert(slots.models.has("prop_lighthouse_01"))
	assert(slots.ui.has("m70_tutorial_sail"))
	print("M70_MOBILE_CONTENT_PASS")
