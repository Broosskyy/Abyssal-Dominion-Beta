class_name M186ObjectiveNavigationCatalog
extends Node
## Resolves quest data to an existing world node. It never spawns a target,
## teleports the player or invents a route when the sector has no match.


static func objective(tree: SceneTree, player: ShipMotor, tracked: Dictionary) -> Dictionary:
	if player == null: return {}
	var source := str(tracked.get("source", ""))
	var quest_id := str(tracked.get("quest_id", ""))
	var index := maxi(0, int(tracked.get("objective_index", 0)))
	if source == "core": return _core_objective(player, quest_id)
	if source == "dynamic": return _dynamic_objective(tree, player, quest_id, index)
	if source == "event": return _event_objective(tree, quest_id)
	return {}


static func resolve_target(tree: SceneTree, player: ShipMotor, objective_data: Dictionary) -> Node3D:
	if player == null or tree == null: return null
	var candidates: Array[Node3D] = []
	for group_id in objective_data.get("target_groups", []):
		for node in tree.get_nodes_in_group(str(group_id)):
			var candidate := node as Node3D
			if candidate != null and is_instance_valid(candidate) and _matches(candidate, objective_data):
				candidates.append(candidate)
	var best: Node3D = null
	var best_distance := INF
	for candidate in candidates:
		var distance := player.global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


static func _core_objective(player: ShipMotor, quest_id: String) -> Dictionary:
	var missions := player.get_node_or_null("Missions") as MissionSystem
	if missions == null: return {}
	var mission := missions.current_mission()
	if str(mission.get("id", "")) != quest_id: return {}
	var kind := str(mission.get("kind", ""))
	return {
		"source":"core", "quest_id":quest_id, "objective_index":0,
		"label":str(mission.get("title", "Core-Auftrag")), "hint":missions.presentation_hint(),
		"kind":kind, "current":missions.progress, "target":int(mission.get("target", 1)),
		"target_groups":_groups_for_kind(kind),
	}


static func _dynamic_objective(tree: SceneTree, player: ShipMotor, quest_id: String, index: int) -> Dictionary:
	var runtime := player.get_node_or_null("DynamicQuestRuntime") as DynamicQuestRuntime
	if runtime == null: return {}
	var quest: Dictionary = {}
	for row in runtime.active_quests():
		if row is Dictionary and str(row.get("id", "")) == quest_id: quest = (row as Dictionary)
	if quest.is_empty(): return {}
	var rows: Array = quest.get("objectives", [])
	if index >= rows.size() or not rows[index] is Dictionary: return {}
	var row: Dictionary = rows[index]
	var state: Dictionary = runtime.progress.get(quest_id, {})
	var kind := str(row.get("kind", ""))
	return {
		"source":"dynamic", "quest_id":quest_id, "objective_index":index,
		"label":str(quest.get("name", quest_id)), "hint":str(row.get("label", _hint_for_kind(kind))),
		"kind":kind, "current":int(state.get(str(index), 0)), "target":int(row.get("target", 1)),
		"content_ids":row.get("content_ids", []), "content_tags":row.get("content_tags", []),
		"target_groups":row.get("target_groups", _groups_for_kind(kind)),
	}


static func _event_objective(tree: SceneTree, quest_id: String) -> Dictionary:
	var runtime := tree.get_first_node_in_group("event_runtime") as EventRuntime
	if runtime == null or not runtime.is_active(): return {}
	for row in runtime.quest_rows():
		if str(row.get("id", "")) != quest_id: continue
		var kind := str(row.get("kind", ""))
		var result := {
			"source":"event", "quest_id":quest_id, "objective_index":0,
			"label":str(row.get("label", quest_id)), "hint":_hint_for_kind(kind), "kind":kind,
			"current":int(runtime.quest_progress.get(quest_id, 0)), "target":int(row.get("target", 1)),
			"target_groups":_groups_for_kind(kind),
		}
		if kind == "event_explore": result["interaction_ids"] = ["event_halloween_wreck_01"]
		if kind in ["event_sink", "event_monster_hit"]: result["require_event_participant"] = true
		if kind == "event_monster_hit": result["encounter_kinds"] = ["monster"]
		return result
	return {}


static func _groups_for_kind(kind: String) -> Array[String]:
	if kind == "dock": return ["ports"]
	if kind == "loot": return ["loot"]
	if kind in ["sink", "event_sink", "event_monster_hit"]: return ["enemies"]
	if kind == "event_explore": return ["event_interactables"]
	return ["world_poi_markers"] if kind in ["interact", "explore", "objective"] else []


static func _hint_for_kind(kind: String) -> String:
	return {
		"sink":"Feindliches Ziel auf der Seekarte finden", "loot":"Beute auf der Seekarte bergen",
		"dock":"Nächsten Hafen anlaufen", "event_sink":"Ertrunkene Flotte jagen",
		"event_monster_hit":"Halloween-Monster mit Harpune treffen", "event_explore":"Eventort untersuchen",
	}.get(kind, "Auftragsziel in der Welt erfüllen")


static func _matches(node: Node3D, objective_data: Dictionary) -> bool:
	if node.is_queued_for_deletion(): return false
	var health := node.get_node_or_null("Health") as ShipHealth
	if health != null and health.is_sunk: return false
	if node is LootPickup and (node as LootPickup).collected: return false
	var content_ids: Array = objective_data.get("content_ids", [])
	if not content_ids.is_empty() and str(node.get_meta("content_id", "")) not in content_ids: return false
	var interaction_ids: Array = objective_data.get("interaction_ids", [])
	if not interaction_ids.is_empty() and str(node.get_meta("interaction_id", "")) not in interaction_ids: return false
	var encounter_kinds: Array = objective_data.get("encounter_kinds", [])
	if not encounter_kinds.is_empty() and str(node.get_meta("encounter_kind", "")) not in encounter_kinds: return false
	if bool(objective_data.get("require_event_participant", false)) and not bool(node.get_meta("event_participant", false)): return false
	var required_tags: Array = objective_data.get("content_tags", [])
	if not required_tags.is_empty():
		var tags: Array = node.get_meta("content_tags", [])
		var matched := false
		for tag in required_tags:
			if tag in tags: matched = true
		if not matched: return false
	return true
