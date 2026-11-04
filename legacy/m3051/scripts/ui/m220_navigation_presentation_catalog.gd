class_name M220NavigationPresentationCatalog
extends RefCounted
## Presentation-only navigation hierarchy for the M213+ zoomed-out master camera.
## It never creates destinations: all world targets must already exist or come
## from the captain's own Tap-to-Sail water position.

const INTENT_LABELS := {
	"tracked_objective":"MISSIONSZIEL",
	"objective":"MISSIONSZIEL",
	"harbor":"HAFEN",
	"loot":"BEUTE",
	"target":"ZIEL",
	"water":"KURS",
}

static func label(intent:String)->String:
	return str(INTENT_LABELS.get(intent,"KURS"))

static func priority(intent:String)->int:
	return {
		"tracked_objective":100,
		"objective":100,
		"harbor":92,
		"target":88,
		"loot":84,
		"water":70,
	}.get(intent,70)

static func course_alpha(distance:float)->float:
	return clampf(0.92 - maxf(0.0,distance-70.0)/180.0,0.54,0.92)

static func edge_label(intent:String,distance:float,detouring:bool)->String:
	var suffix := " · UMFAHRUNG" if detouring else ""
	return "%s · %.0fm%s" % [label(intent),distance,suffix]
