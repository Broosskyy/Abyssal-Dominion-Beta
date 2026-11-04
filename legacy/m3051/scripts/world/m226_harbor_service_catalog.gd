class_name M226HarborServiceCatalog
extends RefCounted
## M226 harbor readability/service presentation only. Existing world, economy and menu systems stay authoritative.

const SERVICES := ["shipyard", "repair", "market", "arsenal", "undock"]

static func label(service_id:String)->String:
	match service_id:
		"shipyard": return "WERFT"
		"repair": return "REPARATUR"
		"market": return "MARKT"
		"arsenal": return "ARSENAL"
		"undock": return "ABLEGEN"
		_: return service_id.to_upper()

static func repair_label(player:Node)->String:
	if player == null: return "REPARATUR"
	var inventory:=player.get_node_or_null("Inventory") as PlayerInventory
	if inventory == null: return "REPARATUR"
	var quote:=inventory.harbor_repair_quote()
	if quote < 0: return "REPARATUR"
	if quote == 0: return "RUMPF OK"
	return "REPARATUR · %d" % quote

static func can_use(player:Node)->bool:
	return player != null and bool(player.get_meta("m225_docked", false)) and player.has_meta("nearby_port")
