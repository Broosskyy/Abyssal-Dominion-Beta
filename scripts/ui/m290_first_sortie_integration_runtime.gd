class_name M290FirstSortieIntegrationRuntime
extends Node
## Bridges existing local-development gameplay events into the M289 readiness observer.
## It is presentation/QA telemetry only and never drives movement, combat, rewards or progression.
signal changed
signal sortie_stage_observed(stage_id: String, observation: Dictionary)

const STAGES := ["HARBOR_START", "UNDOCK", "TAP_TO_SAIL", "TARGET_CONTACT", "CANNON_COMBAT", "HARPOON_MONSTER", "REPAIR_OR_SHIELD", "LOOT_RECOVERY", "QUEST_COMPLETION", "SHIP_DEFEAT", "RESPAWN", "HARBOR_RETURN"]
const CORE_STAGES := ["HARBOR_START", "UNDOCK", "TAP_TO_SAIL", "TARGET_CONTACT", "CANNON_COMBAT", "HARPOON_MONSTER", "REPAIR_OR_SHIELD", "LOOT_RECOVERY", "QUEST_COMPLETION", "HARBOR_RETURN"]
const OPTIONAL_QA_STAGES := ["SHIP_DEFEAT", "RESPAWN"]
const PRESENTATION := {
	"HARBOR_START": {"label":"HAFENSTART", "hint":"Haven's Reach und Startbereich prüfen", "target":"HARBOR"},
	"UNDOCK": {"label":"ABLEGEN", "hint":"Den Hafen verlassen", "target":"OPEN_WATER"},
	"TAP_TO_SAIL": {"label":"KURS SETZEN", "hint":"Freies Wasser antippen", "target":"OPEN_WATER"},
	"TARGET_CONTACT": {"label":"ZIEL ERFASSEN", "hint":"Ein Schiff auswählen", "target":"SHIP"},
	"CANNON_COMBAT": {"label":"KANONENSALVE", "hint":"Schiff mit Kanonen angreifen", "target":"SHIP"},
	"HARPOON_MONSTER": {"label":"MONSTERJAGD", "hint":"Monster mit Harpune angreifen", "target":"MONSTER"},
	"REPAIR_OR_SHIELD": {"label":"SCHADEN KONTROLLIEREN", "hint":"Reparatur/Schild auslösen · Wirkung ungeprüft", "target":"PLAYER"},
	"LOOT_RECOVERY": {"label":"BERGUNG", "hint":"Beute lokal aufsammeln", "target":"LOOT"},
	"QUEST_COMPLETION": {"label":"AUFTRAG", "hint":"Ein Auftragsziel abschließen", "target":"OBJECTIVE"},
	"SHIP_DEFEAT": {"label":"NIEDERLAGE LESEN", "hint":"Untergang und Cleanup prüfen", "target":"PLAYER"},
	"RESPAWN": {"label":"RÜCKKEHR", "hint":"Respawn und Schutz prüfen", "target":"PLAYER"},
	"HARBOR_RETURN": {"label":"HAFENRÜCKKEHR", "hint":"In Haven's Reach anlegen", "target":"HARBOR"},
}

var player: ShipMotor
var world_map: WorldMapSystem
var readiness: M289PlayableVerticalSliceRuntime
var observations: Dictionary = {}
var last_server_revision := -1
var last_server_tick := -1
var environment := "LOCAL_DEVELOPMENT"
var visual_rig: M290FirstSortieVisualRig
var sailing_observer: M294SailingObservationRuntime


func _ready() -> void:
	add_to_group("first_sortie_integration")
	environment = str(get_tree().root.get_meta("environment_id", "LOCAL_DEVELOPMENT")).to_upper()
	set_process(true)


func configure(player_value: ShipMotor, world_map_value: WorldMapSystem, readiness_value: M289PlayableVerticalSliceRuntime) -> void:
	player = player_value
	world_map = world_map_value
	readiness = readiness_value
	_bind_existing_gameplay_events()
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)
	visual_rig = M290FirstSortieVisualRig.new()
	visual_rig.name = "M290FirstSortieVisualRig"
	add_child(visual_rig)
	sailing_observer = M294SailingObservationRuntime.new()
	sailing_observer.name = "M294SailingObservationRuntime"
	add_child(sailing_observer)
	sailing_observer.configure(player)
	sailing_observer.changed.connect(_on_sailing_observation_changed)
	call_deferred("_prime_world_ready")
	changed.emit()


func _on_sailing_observation_changed() -> void:
	changed.emit()


func _bind_existing_gameplay_events() -> void:
	if player == null: return
	var input := player.get_node_or_null("PlayerInput") as PlayerShipInput
	var targeting := player.get_node_or_null("Targeting") as TargetingSystem
	var weapons := player.get_node_or_null("Weapons") as ShipWeapons
	var health := player.get_node_or_null("Health") as ShipHealth
	var missions := player.get_node_or_null("Missions") as MissionSystem
	if input != null:
		if not input.navigation_intent_created.is_connected(_on_navigation_intent): input.navigation_intent_created.connect(_on_navigation_intent)
		if not input.repair_intent_created.is_connected(_on_repair_intent): input.repair_intent_created.connect(_on_repair_intent)
	if targeting != null and not targeting.target_changed.is_connected(_on_target_changed): targeting.target_changed.connect(_on_target_changed)
	if weapons != null and not weapons.presentation_salvo_fired.is_connected(_on_salvo_fired): weapons.presentation_salvo_fired.connect(_on_salvo_fired)
	if health != null:
		if not health.ship_sunk.is_connected(_on_player_sunk): health.ship_sunk.connect(_on_player_sunk)
		if not health.ship_respawned.is_connected(_on_player_respawned): health.ship_respawned.connect(_on_player_respawned)
	if missions != null and not missions.mission_completed.is_connected(_on_mission_completed): missions.mission_completed.connect(_on_mission_completed)
	for node in get_tree().get_nodes_in_group("loot"):
		_bind_loot(node)
	for node in get_tree().get_nodes_in_group("ports"):
		var interaction := node.get_node_or_null("PortInteraction")
		if interaction != null: _bind_port_interaction(interaction)


func _on_tree_node_added(node: Node) -> void:
	if node is LootPickup: _bind_loot(node)
	elif node is PortInteraction:
		_bind_port_interaction(node)
		call_deferred("_prime_world_ready")


func _bind_loot(node: Node) -> void:
	var loot := node as LootPickup
	if loot != null and not loot.presentation_collected.is_connected(_on_loot_collected):
		loot.presentation_collected.connect(_on_loot_collected)


func _bind_port_interaction(node: Node) -> void:
	var port := node as PortInteraction
	if port != null and not port.docking_state_changed.is_connected(_on_docking_state_changed):
		port.docking_state_changed.connect(_on_docking_state_changed)
	if port != null and not port.harbor_proximity_changed.is_connected(_on_harbor_proximity_changed):
		port.harbor_proximity_changed.connect(_on_harbor_proximity_changed)


func _prime_world_ready() -> void:
	if environment != "LOCAL_DEVELOPMENT" or world_map == null: return
	if world_map.current_stable_sector_id() == "SECTOR-001" and _home_port() != null:
		_observe_local("HARBOR_START", {"home_sector":"SECTOR-001", "truth":"WORLD_CONTENT_PRESENT"})


func _on_navigation_intent(target: Vector3, intent: String) -> void:
	if intent == "water" and player != null and not bool(player.get_meta("m225_docked", false)):
		_observe_local("TAP_TO_SAIL", {"intent":intent, "target":[target.x, target.z], "confirmation":"NAVIGATION_INTENT_ONLY"})


func _on_repair_intent(mode: String) -> void:
	_observe_local("REPAIR_OR_SHIELD", {"mode":mode})


func _on_target_changed(target: ShipMotor) -> void:
	if target != null:
		_observe_local("TARGET_CONTACT", {"target_id":str(target.name), "kind":str(target.get_meta("encounter_kind", "ship"))})


func _on_salvo_fired(mode: String, target: ShipMotor) -> void:
	if mode == "cannon" and target != null and str(target.get_meta("encounter_kind", "ship")) != "monster":
		_observe_local("CANNON_COMBAT", {"target_id":str(target.name), "confirmation":"PRESENTATION_FIRE_ONLY"})
	elif mode == "harpoon" and target != null and str(target.get_meta("encounter_kind", "ship")) == "monster":
		_observe_local("HARPOON_MONSTER", {"target_id":str(target.name), "confirmation":"PRESENTATION_FIRE_ONLY"})


func _on_loot_collected(receipt: Dictionary) -> void:
	_observe_local("LOOT_RECOVERY", receipt)


func _on_mission_completed(result: Dictionary) -> void:
	_observe_local("QUEST_COMPLETION", {"mission_id":str(result.get("id", "")), "source":"MISSION_SYSTEM"})


func _on_player_sunk(ship: ShipMotor, _attacker: Node3D) -> void:
	if ship == player: _observe_local("SHIP_DEFEAT", {"entity_id":str(ship.name), "source":"SHIP_HEALTH"})


func _on_player_respawned(ship: ShipMotor) -> void:
	if ship == player: _observe_local("RESPAWN", {"entity_id":str(ship.name), "source":"SHIP_HEALTH"})


func _on_docking_state_changed(docked: bool, port_name: String) -> void:
	if port_name != "Haven's Reach": return
	if not docked:
		_observe_local("UNDOCK", {"port_name":port_name, "source":"PORT_INTERACTION_EXPLICIT_UNDOCK"})
	elif observations.has("UNDOCK") and observations.has("TAP_TO_SAIL"):
		_observe_local("HARBOR_RETURN", {"port_name":port_name, "source":"PORT_INTERACTION"})


func _on_harbor_proximity_changed(nearby: bool, ship: ShipMotor, port_name: String) -> void:
	if not nearby and ship == player and port_name == "Haven's Reach" and observations.has("HARBOR_START") and observations.has("TAP_TO_SAIL"):
		_observe_local("UNDOCK", {"port_name":port_name, "source":"HARBOR_PROXIMITY_EXIT"})


func _observe_local(stage_id: String, payload: Dictionary) -> bool:
	if environment != "LOCAL_DEVELOPMENT" or stage_id not in STAGES or observations.has(stage_id): return false
	var observation := {"stage_id":stage_id, "source":"LOCAL_DEVELOPMENT", "authority":"QA_OBSERVATION_ONLY", "server_verified":false, "payload":payload.duplicate(true)}
	if readiness == null or not readiness.observe_local_slice_event(stage_id, payload): return false
	observations[stage_id] = observation
	sortie_stage_observed.emit(stage_id, observation.duplicate(true))
	changed.emit()
	return true


func ingest_server_stage_receipt(receipt: Dictionary, server_verified: bool) -> bool:
	if not server_verified or readiness == null or str(receipt.get("source", "")) != "SERVER": return false
	var revision := int(receipt.get("qa_revision", -1))
	var tick := int(receipt.get("server_tick", -1))
	var stage_id := str(receipt.get("stage_id", "")).to_upper()
	if stage_id not in STAGES or revision <= last_server_revision or tick < last_server_tick: return false
	if not readiness.ingest_server_slice_observation(receipt, true): return false
	observations[stage_id] = {"stage_id":stage_id, "source":"SERVER", "authority":"SERVER_OBSERVATION_RECEIPT", "server_verified":true, "qa_revision":revision, "server_tick":tick}
	last_server_revision = revision
	last_server_tick = tick
	sortie_stage_observed.emit(stage_id, observations[stage_id].duplicate(true))
	changed.emit()
	return true


func _process(_delta: float) -> void:
	if visual_rig == null: return
	var next := next_stage()
	var kind := str(PRESENTATION.get(next, {}).get("target", ""))
	# The player-selected quest and target outrank passive onboarding hints.
	# These checks never change either selection or actual combat/navigation.
	if _higher_priority_guidance_active(kind):
		visual_rig.bind_target(null, "NONE")
	else:
		visual_rig.bind_target(_resolve_guidance_target(kind), kind)


func _higher_priority_guidance_active(kind: String) -> bool:
	if player == null or not is_instance_valid(player): return true
	var health := player.get_node_or_null("Health") as ShipHealth
	if health != null and health.is_sunk: return true
	var tracking := player.get_node_or_null("TrackedQuestRuntime") as TrackedQuestRuntime
	if tracking != null and not tracking.objective().is_empty(): return true
	var hud := get_tree().get_first_node_in_group("hud") as GameHud
	if hud != null and (hud.menu_open or hud.global_map_open): return true
	var targeting := player.get_node_or_null("Targeting") as TargetingSystem
	return kind in ["SHIP", "MONSTER"] and targeting != null and targeting.valid_hostile(targeting.target)


func next_stage() -> String:
	for stage_id in CORE_STAGES:
		if not observations.has(stage_id): return stage_id
	return "COMPLETE"


func _resolve_guidance_target(kind: String) -> Node3D:
	if player == null: return null
	if kind == "PLAYER": return player
	if kind == "HARBOR": return _home_port()
	if kind == "LOOT": return _nearest_group_node("loot", false)
	if kind == "MONSTER": return _nearest_group_node("enemies", true)
	if kind == "SHIP": return _nearest_group_node("enemies", false)
	return null


func _home_port() -> Node3D:
	for value in get_tree().get_nodes_in_group("ports"):
		var port := value as Node3D
		if port == null or not is_instance_valid(port) or not port.is_inside_tree() or port.is_queued_for_deletion(): continue
		var interaction := port.get_node_or_null("PortInteraction") as PortInteraction
		if interaction != null and interaction.port_name == "Haven's Reach": return port
	return null


func _nearest_group_node(group_id: String, monster_only: bool) -> Node3D:
	var best: Node3D
	var best_distance := INF
	for value in get_tree().get_nodes_in_group(group_id):
		var candidate := value as Node3D
		if candidate == null or not is_instance_valid(candidate) or not candidate.is_inside_tree() or candidate.is_queued_for_deletion(): continue
		var is_monster := str(candidate.get_meta("encounter_kind", "ship")) == "monster"
		if group_id == "enemies" and is_monster != monster_only: continue
		if group_id == "enemies":
			var enemy := candidate as ShipMotor
			if enemy == null: continue
			var enemy_health := enemy.get_node_or_null("Health") as ShipHealth
			if enemy_health == null or enemy_health.is_sunk: continue
		var distance := player.global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func presentation_view(_layout: Dictionary = {}) -> Dictionary:
	var next := next_stage()
	var descriptor: Dictionary = PRESENTATION.get(next, {"label":"AUSFAHRT ABGESCHLOSSEN", "hint":"Native QA-Belege erfassen", "target":"NONE"})
	var core_observed := 0
	var optional_observed := 0
	var server_verified_core := 0
	for stage_id in CORE_STAGES:
		if observations.has(stage_id):
			core_observed += 1
			if bool((observations[stage_id] as Dictionary).get("server_verified", false)): server_verified_core += 1
	for stage_id in OPTIONAL_QA_STAGES:
		if observations.has(stage_id): optional_observed += 1
	var sailing_view: Dictionary = sailing_observer.presentation_view() if sailing_observer != null else {}
	return {"milestone":"M301", "observed":core_observed, "total":CORE_STAGES.size(), "progress":float(core_observed) / float(CORE_STAGES.size()), "server_verified_core":server_verified_core, "local_core":core_observed - server_verified_core, "optional_qa_observed":optional_observed, "optional_qa_total":OPTIONAL_QA_STAGES.size(), "next_stage":next, "next_label":str(descriptor.get("label", "")), "hint":str(descriptor.get("hint", "")), "target_kind":str(descriptor.get("target", "NONE")), "status":"CORE_OBSERVED_NATIVE_QA_PENDING" if next == "COMPLETE" else "IN_PROGRESS", "sailing":sailing_view, "ship_model_strategy":"ONE_COMPLETE_GLB_PER_SHIP", "native_status":str(readiness.readiness_view().get("native_status", "NOT_EVALUATED")) if readiness != null else "NOT_EVALUATED", "release_approved":false, "authority":"PRESENTATION_AND_QA_OBSERVER_ONLY"}


func can_move_or_steer_ship() -> bool: return false
func can_select_target_or_fire_weapon() -> bool: return false
func can_confirm_hit_damage_defeat_or_respawn() -> bool: return false
func can_grant_loot_quest_progress_or_rewards() -> bool: return false
func can_mark_native_qa_pass() -> bool: return false
func can_approve_release() -> bool: return false
func can_require_modular_ship_models() -> bool: return false
