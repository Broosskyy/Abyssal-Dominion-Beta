import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def load(path): return json.loads((ROOT / path).read_text())
def read(path): return (ROOT / path).read_text()


def test_m287_contract_preserves_master_movement_and_clean_room_rules():
    contract = load("data/m287_ship_motion_identity_contract.json")
    assert contract["milestone"] == "M287" and contract["master_concept"] == "V3.8"
    assert contract["genre_ux_references"] == ["Seafight", "Battle of Sea"]
    assert contract["motion_states"] == ["ANCHORED", "IDLE", "ACCELERATING", "CRUISE", "TURNING", "BRAKING", "DRIFTING", "CORRECTING"]
    locks = contract["master_locks"]
    assert locks["tap_to_sail_only"] and locks["camera_joystick_camera_only"]
    assert locks["tap_behind_ship_may_route_directly_without_forced_forward_arc"]
    assert locks["islands_are_navigation_obstacles"] and locks["units_and_loot_do_not_block_navigation"]
    strategy = contract["ship_model_strategy"]
    assert strategy["initial_production"] == "ONE_COMPLETE_3D_MODEL_PER_SHIP"
    assert strategy["modular_ship_system_required"] is False and strategy["separate_sail_mesh_or_bone_required"] is False
    assert "derive authority from wake length" in contract["authority"]["client_never"]
    assert "wake_length_curve" in contract["unset_until_native_qa"]


def test_m287_runtime_is_replica_guarded_and_has_no_movement_authority():
    runtime = read("scripts/ui/m287_ship_motion_identity_runtime.gd")
    assert "class_name M287ShipMotionIdentityRuntime" in runtime
    for token in ["motion_revision", "event_revision", "last_server_tick", "last_event_sequence", "seen_event_ids", "presentation_seed", "invalidate_from_world_resync"]: assert token in runtime
    for token in ["ANCHOR_SETTLE", "ACCELERATION_START", "TURN_ENTER", "BRAKE_START", "DRIFT_ENTER", "CORRECTION_PRESENTATION"]: assert token in runtime
    for token in ["can_client_commit_position() -> bool: return false", "can_client_commit_velocity() -> bool: return false", "can_client_commit_heading() -> bool: return false", "can_client_decide_speed_or_route() -> bool: return false", "can_client_turn_camera_input_into_ship_input() -> bool: return false", "can_client_promote_motion_vfx_to_authority() -> bool: return false"]: assert token in runtime


def test_m287_visual_rig_has_visible_replaceable_motion_placeholders():
    rig = read("scripts/visual/m287_ship_motion_visual_rig.gd")
    factory = read("scripts/core/procedural_factory.gd")
    manifest = load("data/m287_ship_motion_placeholder_manifest.json")
    profiles = load("data/m287_ship_motion_presentation_profiles.json")
    assert "class_name M287ShipMotionVisualRig" in rig
    for visual in ["BowDisplacementPlaceholder", "SternWakePlaceholder", "TurnCurlPlaceholder", "HullWaterlinePlaceholder", "AnchorRipplePlaceholder", "SailFlowOverlayPlaceholder"]: assert visual in rig
    for socket in manifest["required_sockets"]: assert socket in rig and socket in factory
    assert len(manifest["slots"]) == 6 and manifest["status"] == "PLACEHOLDER_REPLACEABLE"
    assert len(profiles["profiles"]) == 5 and profiles["rules"]["profile_does_not_change_speed"] and profiles["rules"]["same_profile_on_mobile_web_desktop"]
    assert "M287ShipMotionVisualRigScript.new()" in factory and 'legacy.visible = false' in rig
    assert "_capture_sails" not in rig and "SINGLE_COMPLETE_3D_MODEL" in rig
    for token in ["func can_set_destination() -> bool: return false", "func can_change_speed() -> bool: return false", "func can_change_heading() -> bool: return false", "func can_rotate_ship_transform() -> bool: return false", "func can_require_modular_ship_mesh() -> bool: return false", "func can_detach_or_replace_ship_parts() -> bool: return false", "func can_decide_collision_or_route() -> bool: return false"]: assert token in rig


def test_m287_bootstrap_hud_command_deck_admin_matrix_and_release():
    bootstrap = read("scripts/core/game_bootstrap.gd")
    hud = read("scripts/ui/game_hud.gd")
    nautical = read("scripts/ui/nautical_hud.gd")
    deck = read("scripts/ui/command_deck.gd")
    assert "M287ShipMotionIdentityRuntime.new()" in bootstrap and "ShipMotionIdentityReadiness" in bootstrap
    assert "m287_ship_motion_identity_state" in hud and "_m287_sync_ship_motion_identity_state()" in hud
    assert "_draw_m287_ship_motion_identity" in nautical
    assert "SHIP MOTION IDENTITY · WAKE · WATER · SAIL RESPONSE" in deck and "M287ShipMotionIdentityCatalog.controls" in deck
    admin = load("data/admin_content_type_registry.json")
    assert admin["milestone"] == "M301"
    assert all(x in admin["content_types"] for x in ["ship_motion_identity_policy_definition", "ship_wake_presentation_profile_definition", "ship_sail_motion_profile_definition", "ship_water_displacement_profile_definition"])
    matrix = load("data/m239_master_convergence_matrix.json")
    row = {x["domain"]: x for x in matrix["domains"]}["ship_motion_identity_wake_water_sail_presentation"]
    assert matrix["milestone"] == "M301" and row["status"] == "PARTIAL" and "m287_fix" in row
    release = load("data/release_identity.json")
    assert release["milestone"] == "M301" and release["client_version"] == "0.301.0" and release["version"] == "0.301.0" and release["build_number"] == 301 and release["content_config_version"] == "M301"
