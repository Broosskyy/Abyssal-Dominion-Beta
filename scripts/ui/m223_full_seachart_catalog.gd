class_name M223FullSeaChartCatalog
extends RefCounted
## M223 full sea-chart presentation contract. Read-only classification only; routing,
## combat target authority and quest tracking stay in their existing runtimes.

const VIEW_SECTOR := "sector"
const VIEW_REGIONS := "regions"
const FILTERS := ["all", "mission", "harbor", "boss", "event", "loot"]

static func filter_label(id:String)->String:
	match id:
		"mission": return "MISSION"
		"harbor": return "HAFEN"
		"boss": return "BOSS"
		"event": return "EVENT"
		"loot": return "LOOT"
		_: return "ALLE"

static func kind_for(node:Node)->String:
	if node == null or not is_instance_valid(node): return ""
	if node.is_in_group("ports"): return "harbor"
	if node.is_in_group("loot"): return "loot"
	if node.is_in_group("event_interactables"): return "event"
	if node.is_in_group("enemies") and (bool(node.get_meta("is_admiral", false)) or str(node.get_meta("encounter_rank", "")) in ["boss", "admiral"]): return "boss"
	if node.is_in_group("enemies"): return "enemy"
	if node.is_in_group("world_poi_markers"): return "poi"
	return "poi"

static func visible_for_filter(kind:String, filter_id:String)->bool:
	if filter_id == "all": return true
	if filter_id == "mission": return kind == "tracked_objective"
	return kind == filter_id

static func action_labels(kind:String, tracked:=false)->Array[String]:
	match kind:
		"tracked_objective": return ["NICHT MEHR VERFOLGEN" if tracked else "VERFOLGEN", "ANSTEUERN"]
		"enemy", "boss": return ["ZIEL AUSWÄHLEN", "ANSTEUERN"]
		"harbor": return ["ANSTEUERN"]
		"loot", "event", "poi": return ["ANSTEUERN"]
		_: return []
