class_name M208UnifiedInterfaceCatalog
extends RefCounted
## Shared menu/navigation presentation rules. Gameplay/content remains identical on all platforms.

const PAGE_ICONS := {
	"home":"m208_menu_home", "progress":"m208_menu_progress", "quests":"m208_menu_quests",
	"equipment":"m208_menu_equipment", "shop":"m208_menu_shop", "harbor":"m208_menu_harbor",
	"bonusmaps":"m208_menu_progress", "events":"m208_menu_quests", "guild":"m208_menu_equipment",
	"rankings":"m208_menu_rankings", "achievements":"achievements", "bazaar":"shop", "log":"m208_menu_log", "help":"m208_menu_help",
	"systems":"m208_menu_help", "admin":"m208_menu_help"
}

const CATEGORY_ORDER := ["MUNITION", "HARPUNE", "AKTIV-ITEM", "AUSRÜSTUNG", "MATERIAL", "KARTEN & SIEGEL", "FORTSCHRITT", "VORRAT"]

static func page_icon_slot(id:String)->String:
	return str(PAGE_ICONS.get(id, "ui_menu_inventory"))

static func category_order(category:String)->int:
	var index := CATEGORY_ORDER.find(category)
	return index if index >= 0 else CATEGORY_ORDER.size()

static func category_hint(category:String)->String:
	return {
		"MUNITION":"Direkt im Kampf wechselbar · Bestand und Auswahl sofort sichtbar.",
		"HARPUNE":"Monster-/Spezialkampf · Payload und Vorrat getrennt lesbar.",
		"AKTIV-ITEM":"Sofortaktionen, Supplies und Cooldowns.",
		"AUSRÜSTUNG":"Schiffs- und Kampfmodule für Ausbau und Loadout.",
		"MATERIAL":"Crafting- und Upgrade-Ressourcen.",
		"KARTEN & SIEGEL":"Zugänge, Fragmente und besondere Freischaltungen.",
		"FORTSCHRITT":"Langfristige Navigation und Entwicklung.",
		"VORRAT":"Weitere lagerbare Ressourcen."
	}.get(category, "")

static func quickslot_kind_label(kind:String)->String:
	return {"ammo":"MUN", "item":"ITEM", "mode":"MODUS", "supply":"SUP"}.get(kind, "")
