class_name P0HudIconRegistry
extends RefCounted
const SLOTS:Dictionary={
	"combat":"ICON-COMBAT",
	"ammo":"ICON-AMMO",
	"ammo_menu":"ICON-AMMO",
	"harpoon":"ICON-HARPOON",
	"repair":"ICON-REPAIR",
	"shield":"ICON-SHIELD",
	"support":"ICON-SUPPORT",
	"quest":"ICON-QUEST",
	"map":"ICON-MAP",
}
static func production_slot(logical_id:String)->String:
	if SLOTS.has(logical_id):return str(SLOTS[logical_id])
	if logical_id.begins_with("ammo_"):return "ICON-AMMO"
	if logical_id.begins_with("support_"):return "ICON-SUPPORT"
	return ""
static func min_touch_size()->float:return 48.0
static func mobile_rules()->Dictionary:return {"min_touch_target":48,"min_icon_px":24,"high_contrast_silhouette":true,"text_optional":true}

static func placeholder_path(logical_id:String)->String:return M201ReferenceIconCatalog.path(logical_id)
