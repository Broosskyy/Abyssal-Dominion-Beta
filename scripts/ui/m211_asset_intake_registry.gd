class_name M211AssetIntakeRegistry
extends RefCounted
## Production IDs -> stable runtime slots. Generated sheet coordinates never become runtime authority.

const SMALL_SIZE_CHECKS := [96, 64, 48]
const FAMILY_ORDER := ["ammo", "harpoon", "combat_item", "cannon", "deck", "special_deck", "ship_equipment", "hud", "menu", "loot"]

static func runtime_slot(family:String, asset_id:String)->String:
	match family:
		"ammo": return "ui_ammo_" + asset_id.trim_suffix("_shell")
		"harpoon": return M210InterfaceAssetRuntimeCatalog.item_slot(asset_id)
		"combat_item": return M210InterfaceAssetRuntimeCatalog.item_slot(asset_id)
		"cannon": return M210InterfaceAssetRuntimeCatalog.cannon_slot(asset_id)
		"deck":
			var level := int(asset_id.trim_prefix("deck_level_"))
			return M210InterfaceAssetRuntimeCatalog.deck_slot(level)
		"special_deck": return M210InterfaceAssetRuntimeCatalog.special_deck_slot(asset_id)
		"ship_equipment": return "ui_ship_equipment_" + asset_id
		"hud": return "hud_icon_" + asset_id
		"menu": return "m208_menu_" + asset_id
	return M210InterfaceAssetRuntimeCatalog.item_slot(asset_id)

static func authored_master_path(family:String,asset_id:String)->String:
	return "res://assets/production/authored_2d/source_masters/%s/%s.png"%[family,asset_id]

static func authored_runtime_path(family:String,asset_id:String)->String:
	return "res://assets/production/authored_2d/runtime/%s/%s.png"%[family,asset_id]

static func production_ready_rules()->Dictionary:
	return {"transparent":true,"isolated_master":true,"generous_padding":true,"small_size_checks":SMALL_SIZE_CHECKS,"sheet_coordinate_dependency":false}
