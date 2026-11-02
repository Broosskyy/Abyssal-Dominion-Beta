class_name M202MenuInteractionPolicy
extends RefCounted
## Visual-master interaction lock for command menus.
## Same information architecture on every platform; only responsive sizing/columns differ.

const PRIMARY_PAGES:Array[String] = ["home", "progress", "quests", "equipment", "shop", "harbor"]
const QUICK_LABELS := {
	"home":"ÜBERSICHT", "progress":"KARTEN", "quests":"AUFTRÄGE",
	"equipment":"SCHIFF", "shop":"MARKT", "harbor":"HAFEN"
}

static func touch_height(safe_size:Vector2)->float:
	return 58.0 if InputDeviceProfile.touch_like(safe_size) else 50.0

static func quick_columns(safe_size:Vector2)->int:
	# Identical destinations and order. Only presentation reflows responsively.
	if safe_size.x < 720.0: return 2
	if safe_size.x < 1180.0: return 3
	return 6

static func panel_width(safe_size:Vector2)->float:
	return minf(1040.0, safe_size.x - (16.0 if InputDeviceProfile.touch_like(safe_size) else 36.0))

static func primary_pages(available:Array[String])->Array[String]:
	var result:Array[String]=[]
	for id in PRIMARY_PAGES:
		if id in available: result.append(id)
	return result

static func quick_label(id:String)->String:
	return str(QUICK_LABELS.get(id,id.to_upper()))
