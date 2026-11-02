class_name CombatUiIconCatalog
extends RefCounted

static func slot(id: String) -> String:
	if id == "gravefire": return "m94_halloween_ammo"
	if id == "pumpkin": return "m301_pumpkin_ammo"
	if id == "gravewake_lantern": return "m94_halloween_event"
	if CombatCatalog.ammo_index_by_id(id) >= 0:
		return "ui_ammo_" + id
	if id in ["hunter_standard","barbed_chain","abyss_piercer"]:
		return "ui_payload_" + id
	if id in ["restoration_shell","ward_shell","event_restoration_shell"]:
		return "ui_support_" + id
	if id == "harpoon":
		return "hud_icon_harpoon"
	if id in ActionItemCatalog.item_ids() or id in ["powder","plates"]:
		return "ui_action_" + id
	return id

static func hud_slot(id: String, fallback_id: String = "") -> String:
	if id.begins_with("ammo_"):
		var suffix := id.trim_prefix("ammo_")
		if suffix.is_valid_int():
			var index := int(suffix)
			if index >= 0 and index < CombatCatalog.ammo_count():
				return slot(CombatCatalog.ammo_id(index))
	if id == "ammo_menu": return "hud_icon_ammo"
	var resolved := slot(id)
	return resolved if resolved != id or fallback_id.is_empty() else fallback_id

static func production_slot(id:String)->String:
	return P0HudIconRegistry.production_slot(id)
