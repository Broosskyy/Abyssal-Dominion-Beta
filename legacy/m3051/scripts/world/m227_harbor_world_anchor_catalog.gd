class_name M227HarborWorldAnchorCatalog
extends RefCounted
## M227 visual/world-readability contract for harbor services. No service authority lives here.

const SERVICE_ANCHORS := {
	"shipyard": {"socket": "WorkshopSocket", "label": "WERFT", "shape": "gantry", "accent": Color("d2ad58"), "slot": "harbor_service_shipyard_anchor"},
	"market": {"socket": "MerchantSocket", "label": "MARKT", "shape": "awning", "accent": Color("67c7d8"), "slot": "harbor_service_market_anchor"},
	"repair": {"socket": "RepairYardSocket", "label": "REPARATUR", "shape": "repair_frame", "accent": Color("63d7a5"), "slot": "harbor_service_repair_anchor"},
	"arsenal": {"socket": "SupportPierSocket", "label": "ARSENAL", "shape": "battery", "accent": Color("df8f64"), "slot": "harbor_service_arsenal_anchor"},
}

static func descriptor(service_id:String)->Dictionary:
	return SERVICE_ANCHORS.get(service_id, {})

static func ordered_ids()->Array[String]:
	return ["shipyard", "repair", "market", "arsenal"]

static func service_for_socket(socket_name:String)->String:
	for service_id in SERVICE_ANCHORS:
		var d:Dictionary = SERVICE_ANCHORS[service_id]
		if str(d.get("socket", "")) == socket_name:
			return str(service_id)
	return ""
