class_name M289PlayableVerticalSliceRuntime
extends Node
## Integration/readiness observer for the first complete sea-map gameplay slice.
signal changed
signal slice_stage_observed(stage_id: String, receipt: Dictionary)
signal native_qa_state_changed(gate_id: String, state: String)

const SLICE_STAGES := ["HARBOR_START", "UNDOCK", "TAP_TO_SAIL", "TARGET_CONTACT", "CANNON_COMBAT", "HARPOON_MONSTER", "REPAIR_OR_SHIELD", "LOOT_RECOVERY", "QUEST_COMPLETION", "SHIP_DEFEAT", "RESPAWN", "HARBOR_RETURN"]
const NATIVE_QA_STATES := ["NOT_EVALUATED", "PASS", "BLOCKED"]
const REQUIRED_ASSETS := {
	"starter_small": "res://assets/production_placeholders/p0/ship_small.glb",
	"starter_medium": "res://assets/production_placeholders/p0/ship_medium.glb",
	"starter_large": "res://assets/production_placeholders/p0/ship_large.glb",
	"harbor": "res://assets/production_placeholders/p0/harbor_havens_reach.glb",
	"npc_scout": "res://assets/production_placeholders/m297/npc_scout_01.glb",
	"npc_raider": "res://assets/production_placeholders/m295/npc_raider_01.glb",
	"npc_heavy": "res://assets/production_placeholders/m297/npc_heavy_01.glb",
	"elite": "res://assets/production_placeholders/p1/regional/ships/npc_crimson_hunter.glb",
	"admiral": "res://assets/production_placeholders/p1/regional/ships/npc_crimson_admiral.glb",
	"monster": "res://assets/production_placeholders/p0/monster_early_01.glb",
	"loot": "res://assets/production_placeholders/m155_loot/loot_tier_chest.glb",
}

var source_gate_states: Dictionary = {}
var stage_observations: Dictionary = {}
var native_qa_states: Dictionary = {}
var native_qa_receipts: Dictionary = {}
var qa_revision := -1
var last_server_tick := -1
var environment := "LOCAL_DEVELOPMENT"


func _ready() -> void:
	add_to_group("playable_vertical_slice_readiness")
	environment = str(get_tree().root.get_meta("environment_id", "LOCAL_DEVELOPMENT")).to_upper()
	_initialize_native_gates()
	refresh_source_readiness()


func refresh_source_readiness() -> Dictionary:
	source_gate_states = {
		"SEA_MAP_BOOT": _has_group("gameplay_root"),
		"TAP_TO_SAIL": _script_contains("res://scripts/gameplay/player_input.gd", "_set_navigation_target"),
		"CAMERA_ONLY_JOYSTICK": _script_contains("res://scripts/gameplay/player_input.gd", "camera_pan"),
		"TARGET_ATTACK_RELOAD": _script_contains("res://scripts/gameplay/ship_weapons.gd", "fire_broadside") and _script_contains("res://scripts/combat/targeting_system.gd", "target_readiness"),
		"HULL_SHIELD_REPAIR": _script_contains("res://scripts/gameplay/ship_health.gd", "func repair"),
		"LOOT_AND_QUEST": FileAccess.file_exists("res://scripts/gameplay/loot_pickup.gd") and FileAccess.file_exists("res://scripts/progression/mission_system.gd"),
		"SINK_RESPAWN_RETURN": _script_contains("res://scripts/gameplay/ship_health.gd", "respawn"),
		"MOBILE_HUD": FileAccess.file_exists("res://scripts/ui/game_hud.gd") and FileAccess.file_exists("res://scripts/ui/nautical_hud.gd"),
		"SERVER_AUTHORITY_CONTRACTS": FileAccess.file_exists("res://data/m269_authoritative_combat_contract.json") and FileAccess.file_exists("res://data/m271_targeting_relationship_authority_contract.json"),
		"SLICE_CONTENT_MANIFEST": FileAccess.file_exists("res://data/m289_playable_vertical_slice_content_manifest.json"),
	}
	for asset_id in REQUIRED_ASSETS:
		source_gate_states["ASSET_" + str(asset_id).to_upper()] = FileAccess.file_exists(str(REQUIRED_ASSETS[asset_id]))
	changed.emit()
	return source_gate_states.duplicate(true)


func observe_local_slice_event(stage_id: String, payload: Dictionary = {}) -> bool:
	var normalized := stage_id.to_upper()
	if normalized not in SLICE_STAGES or environment != "LOCAL_DEVELOPMENT": return false
	if bool(get_tree().root.get_meta("server_authority_verified", false)): return false
	var receipt := {"stage_id":normalized, "source":"LOCAL_DEVELOPMENT", "server_verified":false, "authority":"QA_OBSERVATION_ONLY", "payload":payload.duplicate(true)}
	stage_observations[normalized] = receipt
	slice_stage_observed.emit(normalized, receipt.duplicate(true))
	changed.emit()
	return true


func ingest_server_slice_observation(receipt: Dictionary, server_verified: bool) -> bool:
	if not server_verified or str(receipt.get("source", "")) != "SERVER": return false
	if str(receipt.get("environment", "")).to_upper() != environment: return false
	var stage_id := str(receipt.get("stage_id", "")).to_upper()
	var revision := int(receipt.get("qa_revision", -1))
	var tick := int(receipt.get("server_tick", -1))
	if stage_id not in SLICE_STAGES or revision <= qa_revision or tick < last_server_tick: return false
	var safe := {"stage_id":stage_id, "source":"SERVER", "server_verified":true, "authority":"SERVER_OBSERVATION_RECEIPT", "qa_revision":revision, "server_tick":tick, "session_id":str(receipt.get("session_id", ""))}
	stage_observations[stage_id] = safe
	qa_revision = revision
	last_server_tick = tick
	slice_stage_observed.emit(stage_id, safe.duplicate(true))
	changed.emit()
	return true


func ingest_trusted_native_qa_receipt(receipt: Dictionary, trusted_runner: bool) -> bool:
	if not trusted_runner: return false
	var gate_id := str(receipt.get("gate_id", "")).to_upper()
	var state := str(receipt.get("state", "")).to_upper()
	var revision := int(receipt.get("qa_revision", -1))
	if not native_qa_states.has(gate_id) or state not in NATIVE_QA_STATES or revision <= qa_revision: return false
	if str(receipt.get("environment", "")).to_upper() != environment: return false
	native_qa_states[gate_id] = state
	native_qa_receipts[gate_id] = {"gate_id":gate_id, "state":state, "qa_revision":revision, "device_profile":str(receipt.get("device_profile", "")), "evidence_id":str(receipt.get("evidence_id", "")), "trusted_runner":true}
	qa_revision = revision
	native_qa_state_changed.emit(gate_id, state)
	changed.emit()
	return true


func readiness_view() -> Dictionary:
	var source_ready := 0
	for gate in source_gate_states:
		if bool(source_gate_states[gate]): source_ready += 1
	var native_pass := 0
	var native_blocked := 0
	for gate in native_qa_states:
		if str(native_qa_states[gate]) == "PASS": native_pass += 1
		elif str(native_qa_states[gate]) == "BLOCKED": native_blocked += 1
	return {"milestone":"M289", "environment":environment, "source_ready":source_ready, "source_total":source_gate_states.size(), "observed_stages":stage_observations.size(), "stage_total":SLICE_STAGES.size(), "native_pass":native_pass, "native_blocked":native_blocked, "native_total":native_qa_states.size(), "native_status":"BLOCKED" if native_blocked > 0 else ("PASS" if native_pass == native_qa_states.size() else "NOT_EVALUATED"), "ship_model_strategy":"ONE_COMPLETE_3D_MODEL_PER_SHIP", "release_approved":false, "authority":"READINESS_OBSERVER_ONLY"}


func _initialize_native_gates() -> void:
	for gate_id in ["GODOT_4_7_2_BOOT", "PARSER_AND_SCENE_LOAD", "DESKTOP_GAMEPLAY_LOOP", "ANDROID_GAMEPLAY_LOOP", "MOBILE_TOUCH_AND_SAFE_AREA", "HUD_OVERLAP", "GPU_FRAME_TIME", "MEMORY_AND_VFX_BUDGET", "AUDIO_MIX", "HAPTICS", "SINK_RESPAWN_LOOP", "HARBOR_RETURN_LOOP"]:
		native_qa_states[gate_id] = "NOT_EVALUATED"


func _has_group(group_id: String) -> bool:
	return get_tree().get_first_node_in_group(group_id) != null


func _script_contains(path: String, token: String) -> bool:
	if not FileAccess.file_exists(path): return false
	var file := FileAccess.open(path, FileAccess.READ)
	return file != null and token in file.get_as_text()


func can_authorize_combat_or_targeting() -> bool: return false
func can_grant_loot_progression_or_rewards() -> bool: return false
func can_commit_movement_or_respawn() -> bool: return false
func can_approve_release() -> bool: return false
func can_mark_native_qa_pass_without_receipt() -> bool: return false
func can_require_modular_ship_models() -> bool: return false
func can_transfer_local_observations_to_global() -> bool: return false
