extends Node
func _ready() -> void:
	var c := JSON.parse_string(FileAccess.get_file_as_string("res://data/m59_core_hud_visual_contract.json"))
	assert(c.mobile_first == true)
	assert(c.minimum_touch_target_dp >= 52)
	assert(c.slots.combat_ring.size() == 2)
	for id in ["hud_combat_ring","hud_combat_ring_active","hud_quickslot_frame","hud_target_frame","hud_bar_hull","hud_bar_shield","hud_ammo_selector_frame","hud_picker_row","hud_picker_row_selected"]:
		assert(not VisualAssetCatalog.info("ui",id).is_empty())
	print("M59_CORE_HUD_VISUAL_PASS")
