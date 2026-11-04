class_name M231EncounterZoneFeedbackCatalog
extends RefCounted

## Presentation-only proximity/readability layer for the existing M229/M230 encounter semantics.
## These radii are HUD-awareness thresholds, never aggro, weapon, collision or navigation ranges.
const ENTER_RADIUS := {"elite":18.0, "territory":26.0, "boss":30.0}
const EXIT_HYSTERESIS := 5.0
const MESSAGE_SECONDS := 2.4
const CHANGE_COOLDOWN := 1.0

static func danger_read(node:Node3D)->String:
	if node == null:return "standard"
	return str(node.get_meta("m229_danger_read","standard"))

static func awareness_radius(node:Node3D)->float:
	return float(ENTER_RADIUS.get(danger_read(node),0.0))

static func is_relevant(node:Node3D)->bool:
	return awareness_radius(node)>0.0

static func zone_key(node:Node3D)->String:
	if node == null:return ""
	return "%s:%s" % [danger_read(node),str(node.get_instance_id())]

static func enter_label(node:Node3D)->String:
	match danger_read(node):
		"territory": return "MONSTER-REVIER BETRETEN"
		"boss": return "ADMIRAL-PRÄSENZ"
		"elite": return "ELITE-GEFAHRENZONE"
	return ""

static func leave_label(read:String)->String:
	match read:
		"territory": return "MONSTER-REVIER VERLASSEN"
		"boss": return "ADMIRAL-BEREICH VERLASSEN"
		"elite": return "ELITE-GEFAHRENZONE VERLASSEN"
	return ""

static func regional_hint(node:Node3D)->String:
	if node == null:return ""
	var temperament:=str(node.get_meta("m228_region_temperament",""))
	var formation:=str(node.get_meta("m229_formation_read",""))
	if temperament.is_empty() and formation.is_empty():return ""
	return "%s%s%s" % [temperament.replace("_"," ").to_upper()," · " if not temperament.is_empty() and not formation.is_empty() else "",formation.replace("_"," ").to_upper()]

static func nearest_relevant(player:Node3D, enemies:Array)->Dictionary:
	if player == null:return {}
	var best:Node3D=null
	var best_distance:=INF
	for value in enemies:
		var node:=value as Node3D
		if node==null or not is_relevant(node):continue
		var health:=node.get_node_or_null("Health")
		if health!=null and bool(health.get("is_sunk")):continue
		var distance:=player.global_position.distance_to(node.global_position)
		if distance<best_distance:
			best=node;best_distance=distance
	if best==null:return {}
	return {"node":best,"distance":best_distance,"radius":awareness_radius(best),"read":danger_read(best),"key":zone_key(best)}
