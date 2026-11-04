class_name M206DeckEquipmentPresentationCatalog
extends RefCounted
## Visual-only deck/harpoon/equipment presentation. Gameplay authority stays in existing catalogs.
static func normal_deck_icon_slot(level:int)->String:
	return "ui_deck_level_%02d"%clampi(level,1,10)
static func special_deck_icon_slot(id:String)->String:
	return "ui_special_deck_"+id
static func special_deck_level_badge(level:int)->String:
	return "ui_special_deck_level_%d"%clampi(maxi(level,1),1,5)
static func harpoon_icon_slot(id:String)->String:
	return "ui_harpoon_"+id
static func equipment_icon_slot(id:String)->String:
	return "ui_ship_equipment_"+id
static func normal_deck_stage_label(level:int)->String:
	if level<=0:return "KEIN ZUSATZDECK"
	if level<=3:return "LEICHTER DECKSTAPEL"
	if level<=6:return "VERSTÄRKTER DECKSTAPEL"
	if level<=9:return "SCHWERER DECKSTAPEL"
	return "VOLL AUSGEBAUTER DECKSTAPEL"
