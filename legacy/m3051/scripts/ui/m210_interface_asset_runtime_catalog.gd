class_name M210InterfaceAssetRuntimeCatalog
extends RefCounted
## Single presentation resolver for authored/placeholder 2D assets. Gameplay never depends on art.

const CATEGORY_TABS := ["ALLE", "MUNITION", "HARPUNE", "AKTIV-ITEM", "AUSRÜSTUNG", "MATERIAL", "KARTEN & SIEGEL", "FORTSCHRITT", "VORRAT"]
const COMBAT_FAMILIES := {
	"ammo":"MUNITION", "harpoon":"HARPUNE", "item":"AKTIV-ITEM", "supply":"VORRAT", "mode":"HARPUNE"
}

static func item_slot(id:String)->String:
	return M204InventoryPresentationCatalog.icon_slot(id)

static func cannon_slot(cannon_id:String)->String:
	return M205CannonPresentationCatalog.cannon_icon_slot(cannon_id)

static func deck_slot(level:int)->String:
	return M206DeckEquipmentPresentationCatalog.normal_deck_icon_slot(maxi(1, level))

static func special_deck_slot(id:String)->String:
	return M206DeckEquipmentPresentationCatalog.special_deck_icon_slot(id)

static func category(id:String)->String:
	return M204InventoryPresentationCatalog.category(id)

static func combat_kind_label(kind:String)->String:
	return COMBAT_FAMILIES.get(kind, kind.to_upper())

static func authored_replacement_safe()->bool:
	return true # slot replacement cannot grant stats, collision, rewards or unlocks
