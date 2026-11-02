class_name M201ReferenceIconCatalog
extends RefCounted

const ROOT := "res://assets/production_placeholders/m201_reference/ui/"
const ICONS := {
	"combat": "icon_combat_m201.svg",
	"ammo": "icon_ammo_m201.svg",
	"harpoon": "icon_harpoon_m201.svg",
	"repair": "icon_repair_m201.svg",
	"shield": "icon_shield_m201.svg",
	"support": "icon_support_m201.svg",
	"quest": "icon_quest_m201.svg",
	"map": "icon_map_m201.svg",
}
static func path(logical_id:String)->String:
	var key:=logical_id
	if key.begins_with("ammo_"):key="ammo"
	if key.begins_with("support_"):key="support"
	return ROOT+str(ICONS.get(key,"")) if ICONS.has(key) else ""
static func rules()->Dictionary:
	return {"visual_master":"V3.8","palette":"navy_gold","high_contrast":true,"final_art":false,"cross_platform_asset_parity":true}
