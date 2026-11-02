class_name M222SeaChartInteractionCatalog
extends RefCounted
## M222 presentation/action vocabulary. It never creates world targets and never owns routing.

const GAMEPLAY_MINIMAP_SHAPE := "round"
const FULL_SEA_CHART_SHAPE := "rectangular"

static func action_label(kind:String, tracked:=false)->String:
	match kind:
		"tracked_objective": return "NICHT MEHR VERFOLGEN" if tracked else "ZIEL VERFOLGEN"
		"enemy": return "ZIEL AUSWÄHLEN"
		"harbor": return "HAFEN ANSTEUERN"
		"loot": return "BEUTE ANSTEUERN"
		_: return "ANSTEUERN"

static func navigation_intent(kind:String)->String:
	match kind:
		"tracked_objective": return "tracked_objective"
		"enemy": return "target"
		"harbor": return "harbor"
		"loot": return "loot"
		_: return "objective"

static func can_navigate(target:Node3D)->bool:
	return target != null and is_instance_valid(target) and target.is_inside_tree()
