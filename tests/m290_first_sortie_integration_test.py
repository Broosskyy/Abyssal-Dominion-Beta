import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load(path):
    return json.loads((ROOT / path).read_text())


def read(path):
    return (ROOT / path).read_text()


def test_m290_contract_preserves_master_controls_clean_room_and_single_model_strategy():
    contract = load("data/m290_first_sortie_integration_contract.json")
    assert contract["milestone"] == "M290" and contract["master_concept"] == "V3.8"
    assert contract["genre_ux_references"] == ["Seafight", "Battle of Sea"]
    assert len(contract["stages"]) == 12 and contract["stages"][0] == "HARBOR_START" and contract["stages"][-1] == "HARBOR_RETURN"
    assert set(contract["event_bindings"]) == {"navigation_intent_created", "target_changed", "presentation_salvo_fired", "repair_intent_created", "presentation_collected", "mission_completed", "ship_sunk", "ship_respawned", "docking_state_changed"}
    strategy = contract["ship_model_strategy"]
    assert strategy["initial_ships"] == "ONE_COMPLETE_GLB_PER_SHIP"
    assert strategy["modular_ship_construction"] is False and strategy["modular_ship_system_deferred"] is True
    locks = contract["control_locks"]
    assert locks["tap_to_sail"] and locks["camera_joystick_camera_only"] and locks["hull_and_shield_separate"]
    assert locks["cannons_against_ships"] and locks["harpoons_against_monsters"]
    assert locks["auto_navigation"] is False and locks["default_auto_fire"] is False and locks["auto_chase"] is False and locks["angle_damage"] is False
    evidence = contract["evidence"]
    assert evidence["local_observations_are_server_truth"] is False and evidence["presentation_fire_confirms_hit"] is False
    assert evidence["static_tests_are_native_qa"] is False and evidence["missing_native_evidence"] == "NOT_EVALUATED"


def test_m290_gameplay_hooks_feed_observation_without_taking_gameplay_authority():
    player_input = read("scripts/gameplay/player_input.gd")
    targeting = read("scripts/combat/targeting_system.gd")
    weapons = read("scripts/gameplay/ship_weapons.gd")
    loot = read("scripts/gameplay/loot_pickup.gd")
    port = read("scripts/world/port_interaction.gd")
    assert "signal navigation_intent_created" in player_input and "signal repair_intent_created" in player_input
    assert 'navigation_intent_created.emit(navigation_target, "water")' in player_input and "navigation_intent_created.emit(navigation_target, intent)" in player_input
    assert 'repair_intent_created.emit("repair_or_shield")' in player_input
    assert "signal target_changed" in targeting and "target_changed.emit(target)" in targeting
    assert "signal presentation_salvo_fired" in weapons and "presentation_salvo_fired.emit(weapon_mode, selected_target())" in weapons
    assert "signal presentation_collected" in loot and "presentation_collected.emit" in loot
    assert "signal docking_state_changed" in port and "docking_state_changed.emit(true, port_name)" in port and "docking_state_changed.emit(false, port_name)" in port
    runtime = read("scripts/ui/m290_first_sortie_integration_runtime.gd")
    assert "class_name M290FirstSortieIntegrationRuntime" in runtime and "ingest_server_stage_receipt" in runtime
    for token in ["last_server_revision", "last_server_tick", "qa_revision", "server_tick", "M289PlayableVerticalSliceRuntime", "QA_OBSERVATION_ONLY", "SERVER_OBSERVATION_RECEIPT"]:
        assert token in runtime
    for token in [
        "can_move_or_steer_ship() -> bool: return false",
        "can_select_target_or_fire_weapon() -> bool: return false",
        "can_confirm_hit_damage_defeat_or_respawn() -> bool: return false",
        "can_grant_loot_quest_progress_or_rewards() -> bool: return false",
        "can_mark_native_qa_pass() -> bool: return false",
        "can_approve_release() -> bool: return false",
        "can_require_modular_ship_models() -> bool: return false",
    ]:
        assert token in runtime


def test_m290_placeholder_manifest_and_visual_guidance_are_replaceable_and_non_authoritative():
    manifest = load("data/m290_first_sortie_placeholder_manifest.json")
    assert manifest["milestone"] == "M290" and manifest["status"] == "RUNTIME_BOUND_REPLACEABLE_PLACEHOLDERS"
    assert len(manifest["stable_model_slots"]) == 8 and len(manifest["procedural_presentation_placeholders"]) == 3
    for entry in manifest["stable_model_slots"]:
        assert entry["model_strategy"] == "ONE_COMPLETE_GLB" and entry["final_required"] is True
        assert entry["path"].startswith("res://") and (ROOT / entry["path"].removeprefix("res://")).is_file()
    rules = manifest["rules"]
    assert rules["ship_parts_are_not_runtime_modules"] and rules["guidance_markers_never_enter_ship_glb"]
    assert rules["wake_water_smoke_fire_damage_and_targeting_remain_external"] and rules["placeholder_assets_are_not_final_art"]
    rig = read("scripts/visual/m290_first_sortie_visual_rig.gd")
    for token in ["RouteRingPlaceholder", "GuidanceMastPlaceholder", "ObjectiveBeaconPlaceholder", 'set_meta("presentation_only", true)', 'set_meta("placeholder_replacement_ready", true)']:
        assert token in rig
    assert "can_change_navigation_or_collision() -> bool: return false" in rig
    assert "can_select_target_or_confirm_objective() -> bool: return false" in rig
    assert "can_modify_ship_model_parts() -> bool: return false" in rig


def test_m290_integration_admin_matrix_native_qa_audit_and_release_identity():
    bootstrap = read("scripts/core/game_bootstrap.gd")
    hud = read("scripts/ui/game_hud.gd")
    nautical = read("scripts/ui/nautical_hud.gd")
    deck = read("scripts/ui/command_deck.gd")
    assert "M290FirstSortieIntegrationRuntime.new()" in bootstrap and "first_sortie_integration.configure(player, world_map, playable_vertical_slice)" in bootstrap
    assert "m290_first_sortie_state" in hud and "_m290_sync_first_sortie_state()" in hud and "_draw_m290_first_sortie_guidance" in hud
    assert "hud._draw_m290_first_sortie_guidance(layout)" in nautical
    assert "FIRST SEA SORTIE · EVENT BINDING · GUIDANCE" in deck and "M290FirstSortieCatalog.authority" in deck
    assert "No production code called `observe_local_slice_event`" in read("M289_DEEP_AUDIT_FOR_M290.md")
    admin = load("data/admin_content_type_registry.json")
    assert admin["milestone"] == "M301"
    for item in ["first_sortie_integration_definition", "first_sortie_guidance_profile_definition", "first_sortie_event_receipt_policy_definition", "first_sortie_placeholder_profile_definition"]:
        assert item in admin["content_types"]
    matrix = load("data/m239_master_convergence_matrix.json")
    row = {x["domain"]: x for x in matrix["domains"]}["first_sea_sortie_runtime_integration_guidance"]
    assert matrix["milestone"] == "M301" and row["status"] == "PARTIAL" and "m290_fix" in row
    native = load("data/m290_first_sortie_native_qa_matrix.json")
    assert native["status"] == "NOT_EVALUATED" and native["release_approved"] is False
    assert len(native["gates"]) == 10 and all(x["state"] == "NOT_EVALUATED" for x in native["gates"])
    qa = read("scripts/qa/m290_first_sortie_integration_qa.gd")
    assert "can_simulate_gameplay_event() -> bool: return false" in qa and "can_mark_native_pass() -> bool: return false" in qa and "can_approve_release() -> bool: return false" in qa
    release = load("data/release_identity.json")
    assert release["milestone"] == "M301" and release["client_version"] == release["version"] == "0.301.0"
    assert release["build_number"] == 301 and release["content_config_version"] == "M301"
    assert "one complete GLB" in release["m290_integration_lock"]
