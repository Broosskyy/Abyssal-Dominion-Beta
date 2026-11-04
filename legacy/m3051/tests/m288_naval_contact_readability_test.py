import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def load(path): return json.loads((ROOT / path).read_text())
def read(path): return (ROOT / path).read_text()


def test_m288_contract_preserves_master_hud_clean_room_and_single_model_rules():
    contract = load("data/m288_naval_contact_readability_contract.json")
    assert contract["milestone"] == "M288" and contract["master_concept"] == "V3.8"
    assert contract["genre_ux_references"] == ["Seafight", "Battle of Sea"]
    assert contract["contact_classes"] == ["PLAYER", "FLEET_ALLY", "FRIENDLY", "NEUTRAL", "HOSTILE", "ELITE", "ADMIRAL", "MONSTER", "BOSS"]
    locks = contract["master_locks"]
    assert locks["sea_chart_center_remains_readable"] and locks["lower_left_camera_control_unobstructed"]
    assert locks["lower_right_attack_cluster_unobstructed"] and locks["bottom_center_ammo_weapon_controls_unobstructed"]
    assert locks["tap_to_sail_unchanged"] and locks["camera_joystick_camera_only"]
    strategy = contract["ship_model_strategy"]
    assert strategy["initial_production"] == "ONE_COMPLETE_3D_MODEL_PER_SHIP"
    assert strategy["modular_ship_system_required"] is False and strategy["separate_hull_mast_sail_mesh_required"] is False
    assert "calculate authoritative range" in contract["authority"]["client_never"]


def test_m288_runtime_is_replica_guarded_and_has_no_target_combat_or_aggro_authority():
    runtime = read("scripts/ui/m288_naval_contact_readability_runtime.gd")
    assert "class_name M288NavalContactReadabilityRuntime" in runtime
    for token in ["contact_revision", "event_revision", "last_server_tick", "last_event_sequence", "seen_event_ids", "presentation_seed", "invalidate_from_world_resync"]: assert token in runtime
    for token in ["TARGET_ACQUIRED", "TARGET_CLEARED", "THREAT_ENTER", "THREAT_EXIT", "RANGE_ENTER", "RANGE_EXIT", "PROTECTION_CHANGED", "PRIORITY_CHANGED"]: assert token in runtime
    for token in ["can_client_select_or_clear_target() -> bool: return false", "can_client_decide_attack_legality() -> bool: return false", "can_client_decide_range() -> bool: return false", "can_client_set_relationship_or_aggro() -> bool: return false", "can_client_remove_protection() -> bool: return false", "can_client_promote_contact_vfx_to_authority() -> bool: return false"]: assert token in runtime


def test_m288_visual_rig_has_replaceable_single_model_contact_placeholders():
    rig = read("scripts/visual/m288_naval_contact_visual_rig.gd")
    factory = read("scripts/core/procedural_factory.gd")
    manifest = load("data/m288_naval_contact_placeholder_manifest.json")
    profiles = load("data/m288_naval_contact_presentation_profiles.json")
    for visual in ["TargetFocusRingPlaceholder", "RelationArcPlaceholder", "ThreatChevronPlaceholder", "RangeStateBracketPlaceholder", "PriorityBeaconPlaceholder"]: assert visual in rig
    for socket in manifest["required_sockets"]: assert socket in rig
    assert len(manifest["slots"]) == 6 and manifest["status"] == "PLACEHOLDER_REPLACEABLE"
    assert len(profiles["profiles"]) == 9 and profiles["rules"]["profile_does_not_require_modular_ship_parts"]
    assert profiles["rules"]["selected_target_always_preserved"]
    assert "M288NavalContactVisualRigScript.new()" in factory and "SINGLE_COMPLETE_3D_MODEL" in rig
    for token in ["func can_select_or_clear_target() -> bool: return false", "func can_decide_attack_legality_or_range() -> bool: return false", "func can_set_relationship_or_aggro() -> bool: return false", "func can_remove_protection() -> bool: return false", "func can_require_modular_ship_mesh() -> bool: return false", "func can_hide_detach_or_replace_ship_parts() -> bool: return false"]: assert token in rig


def test_m288_bootstrap_hud_command_deck_admin_matrix_and_release():
    bootstrap = read("scripts/core/game_bootstrap.gd")
    hud = read("scripts/ui/game_hud.gd")
    nautical = read("scripts/ui/nautical_hud.gd")
    deck = read("scripts/ui/command_deck.gd")
    assert "M288NavalContactReadabilityRuntime.new()" in bootstrap and "NavalContactReadabilityReadiness" in bootstrap
    assert "m288_naval_contact_readability_state" in hud and "_m288_sync_naval_contact_readability_state()" in hud
    assert "_draw_m288_naval_contact_readability" in nautical
    assert "edge_budget" in nautical and "hud._safe_rect().grow" in nautical and "edge_x" in read("scripts/ui/m288_naval_contact_readability_runtime.gd")
    assert "NAVAL CONTACT READABILITY · TARGET · THREAT · RANGE" in deck and "M288NavalContactReadabilityCatalog.authority" in deck
    admin = load("data/admin_content_type_registry.json")
    assert admin["milestone"] == "M301"
    assert all(x in admin["content_types"] for x in ["naval_contact_readability_policy_definition", "contact_relationship_presentation_profile_definition", "contact_threat_range_profile_definition", "offscreen_contact_marker_profile_definition"])
    matrix = load("data/m239_master_convergence_matrix.json")
    row = {x["domain"]: x for x in matrix["domains"]}["naval_contact_target_threat_range_offscreen_readability"]
    assert matrix["milestone"] == "M301" and row["status"] == "PARTIAL" and "m288_fix" in row
    release = load("data/release_identity.json")
    assert release["milestone"] == "M301" and release["client_version"] == "0.301.0" and release["version"] == "0.301.0" and release["build_number"] == 301 and release["content_config_version"] == "M301"
    assert "complete individual ship models" in release["m288_visual_lock"]
