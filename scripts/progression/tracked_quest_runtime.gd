class_name TrackedQuestRuntime
extends Node
## One explicit player-owned objective selection. This is presentation/navigation
## state only: quest progress and rewards remain in their existing runtimes.

signal changed

var tracked: Dictionary = {}


func _ready() -> void:
	add_to_group("tracked_quest_runtime")
	call_deferred("_connect_sources")


func _connect_sources() -> void:
	var missions := get_parent().get_node_or_null("Missions") as MissionSystem
	if missions != null and not missions.mission_changed.is_connected(_source_changed):
		missions.mission_changed.connect(_source_changed)
	var dynamic := get_parent().get_node_or_null("DynamicQuestRuntime") as DynamicQuestRuntime
	if dynamic != null and not dynamic.changed.is_connected(_source_changed):
		dynamic.changed.connect(_source_changed)
	var event := get_tree().get_first_node_in_group("event_runtime") as EventRuntime
	if event != null and not event.event_changed.is_connected(_source_changed):
		event.event_changed.connect(_source_changed)


func track(source: String, quest_id: String, objective_index := 0) -> bool:
	var candidate := {
		"source": source,
		"quest_id": quest_id,
		"objective_index": maxi(0, objective_index),
	}
	if M186ObjectiveNavigationCatalog.objective(get_tree(), get_parent() as ShipMotor, candidate).is_empty():
		return false
	tracked = candidate
	changed.emit()
	return true


func untrack() -> void:
	if tracked.is_empty(): return
	tracked.clear()
	changed.emit()


func is_tracked(source: String, quest_id: String, objective_index := 0) -> bool:
	return str(tracked.get("source", "")) == source and str(tracked.get("quest_id", "")) == quest_id and int(tracked.get("objective_index", 0)) == objective_index


func objective() -> Dictionary:
	if tracked.is_empty(): return {}
	return M186ObjectiveNavigationCatalog.objective(get_tree(), get_parent() as ShipMotor, tracked)


func status_card() -> Dictionary:
	var current := objective()
	if current.is_empty():
		return {"title":"KEIN ZIEL VERFOLGT", "state":"AUSWAHL OFFEN", "detail":"MENU > AUFTRÄGE öffnet die Zielauswahl.", "tone":"info"}
	var target := resolve_target()
	var route_text := "KARTENZIEL VERFÜGBAR" if target != null else "KEIN KARTENZIEL IN DIESEM SEKTOR"
	return {
		"title": str(current.get("label", "Auftragsziel")),
		"state": "%d/%d" % [int(current.get("current", 0)), int(current.get("target", 1))],
		"detail": "%s · %s" % [str(current.get("hint", "Ziel verfolgen")), route_text],
		"tone": "active" if target != null else "warning",
		"progress": float(current.get("current", 0)) / float(maxi(1, int(current.get("target", 1)))),
		"has_map_target": target != null,
	}


func resolve_target() -> Node3D:
	var current := objective()
	if current.is_empty(): return null
	return M186ObjectiveNavigationCatalog.resolve_target(get_tree(), get_parent() as ShipMotor, current)


func navigate_to_target() -> bool:
	var target := resolve_target()
	if target == null: return false
	var input := get_parent().get_node_or_null("PlayerInput") as PlayerShipInput
	if input == null: return false
	input.set_navigation_world_target(target.global_position, "tracked_objective")
	return true


func export_state() -> Dictionary:
	return {"schema": 1, "tracked": tracked.duplicate(true)}


func import_state(value: Dictionary) -> void:
	var saved: Variant = value.get("tracked", {})
	tracked = (saved as Dictionary).duplicate(true) if saved is Dictionary else {}
	if not tracked.is_empty() and objective().is_empty(): tracked.clear()
	changed.emit()


func _source_changed() -> void:
	if tracked.is_empty(): return
	# Core rotation should keep following the current core mission after a claim.
	if str(tracked.get("source", "")) == "core":
		var missions := get_parent().get_node_or_null("Missions") as MissionSystem
		if missions != null:
			tracked["quest_id"] = str(missions.current_mission().get("id", ""))
			tracked["objective_index"] = 0
	var current := objective()
	if current.is_empty() or (str(tracked.get("source", "")) != "core" and int(current.get("current", 0)) >= int(current.get("target", 1))):
		tracked.clear()
	changed.emit()
