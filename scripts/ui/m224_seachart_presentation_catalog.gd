class_name M224SeaChartPresentationCatalog
extends RefCounted
## M224 presentation-only full sea-chart polish. This catalog never creates targets,
## changes routes, teleports, or mutates combat/progression values.

const MIN_ZOOM := 0.85
const MAX_ZOOM := 2.25
const LEGEND_KINDS := ["tracked_objective", "harbor", "boss", "event", "loot"]

static func clamp_pan(value:Vector2, zoom:float)->Vector2:
	var allowance := maxf(0.0, 0.54 * (zoom - 1.0) / maxf(zoom, 0.01))
	return Vector2(clampf(value.x,-allowance,allowance),clampf(value.y,-allowance,allowance))

static func kind_label(kind:String)->String:
	match kind:
		"tracked_objective": return "MISSION"
		"harbor": return "HAFEN"
		"boss": return "BOSS"
		"event": return "EVENT"
		"loot": return "LOOT"
		"enemy": return "GEGNER"
		_: return "POI"

static func marker_shape(kind:String)->String:
	match kind:
		"tracked_objective": return "diamond"
		"harbor": return "square"
		"boss": return "ring"
		"event": return "diamond"
		_: return "circle"

static func marker_radius(kind:String)->float:
	match kind:
		"tracked_objective": return 8.5
		"boss": return 8.0
		"harbor": return 6.8
		"event": return 6.3
		"loot": return 5.5
		_: return 4.8

static func marker_color(kind:String)->Color:
	match kind:
		"tracked_objective": return Color("66e3a4")
		"harbor": return Color("f1c75b")
		"boss": return Color("ffd267")
		"event": return Color("b46cff")
		"loot": return Color("7ee7ff")
		"enemy": return Color("e6392e")
		_: return Color("9db9c8")

static func status_label(node:Node,kind:String)->String:
	if node == null or not is_instance_valid(node): return "NICHT VERFÜGBAR"
	if kind == "tracked_objective": return "VERFOLGT"
	if kind == "boss": return "HOHE GEFAHR"
	if kind == "harbor": return "ANLAUFBAR"
	if kind == "loot": return "BERGUNG"
	if kind == "event": return "AKTIV"
	if kind == "enemy": return "FEINDLICH"
	return "ENTDECKT"
