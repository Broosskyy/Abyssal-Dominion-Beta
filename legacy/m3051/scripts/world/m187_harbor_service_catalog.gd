class_name M187HarborServiceCatalog
extends RefCounted
## M187: Harbor is a local world POI. Global systems never require docking unless a published definition explicitly opts into harbor locality.

const GLOBAL_ANYWHERE := ["ships", "shipyard", "equipment", "loadouts", "itemshop", "quests", "events", "guild", "rankings", "achievements", "logbook", "progression"]
const LOCAL_SERVICES := ["dock_visit", "repair_service", "local_supply_market", "regional_vendor", "regional_crafting", "harbor_npc", "harbor_quest", "harbor_event_hook"]

static func is_global_system(id: String) -> bool:
	return id in GLOBAL_ANYWHERE

static func is_local_service(id: String) -> bool:
	return id in LOCAL_SERVICES

static func quest_requires_harbor(definition: Dictionary) -> bool:
	# Opt-in only: ordinary story/region/daily/weekly/event quests stay global.
	return bool(definition.get("requires_harbor", false)) or str(definition.get("quest_scope", "global")) == "harbor"

static func harbor_status(player: Node) -> Dictionary:
	if player == null or not player.has_meta("nearby_port"):
		return {"available": false, "port_name": "", "label": "AUF SEE", "detail": "Lokale Hafendienste werden erst in Hafennähe verfügbar."}
	var port = player.get_meta("nearby_port", null)
	if not is_instance_valid(port) or not port is PortInteraction or port.nearby_player != player:
		return {"available": false, "port_name": "", "label": "AUF SEE", "detail": "Kein gültiger Hafen in Reichweite."}
	var docked := bool(player.get_meta("m225_docked", false))
	return {"available": true, "port_name": port.port_name, "label": "ANGELEGT" if docked else "HAFEN IN REICHWEITE", "docked": docked, "detail": "Lokale Hafendienste aktiv; Ablegen bringt dich direkt zurück auf See." if docked else "Anlegen aktiviert lokale Dienste und setzt den Wiederkehrpunkt."}
