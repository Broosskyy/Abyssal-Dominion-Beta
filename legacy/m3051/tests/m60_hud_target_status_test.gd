extends Node
func _ready() -> void:
	var c := JSON.parse_string(FileAccess.get_file_as_string("res://data/m60_hud_target_status_contract.json"))
	var q := JSON.parse_string(FileAccess.get_file_as_string("res://data/m60_mobile_hud_qa_presets.json"))
	assert(c.features.target_relation_frames.size() == 5)
	assert(q.presets.size() == 5)
	assert(q.presets[0].min_touch_dp >= 52)
	for id in ["hud_target_neutral","hud_target_hostile","hud_target_elite","hud_target_admiral","hud_target_monster","hud_icon_attack","hud_icon_repair","hud_icon_harpoon","hud_icon_target","hud_icon_hull","hud_icon_shield","hud_icon_ammo"]:
		assert(not VisualAssetCatalog.info("ui",id).is_empty())
	print("M60_HUD_TARGET_STATUS_PASS")
