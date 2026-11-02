import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load(path):
    return json.loads((ROOT / path).read_text())


def read(path):
    return (ROOT / path).read_text()


def test_m289_contract_preserves_master_loop_authority_and_single_model_lock():
    contract = load("data/m289_playable_vertical_slice_contract.json")
    assert contract["milestone"] == "M289" and contract["master_concept"] == "V3.8"
    assert contract["genre_ux_references"] == ["Seafight", "Battle of Sea"]
    assert len(contract["slice_stages"]) == 12
    assert contract["slice_stages"][0] == "HARBOR_START" and contract["slice_stages"][-1] == "HARBOR_RETURN"
    required = contract["required_content"]
    assert required["sea_maps"] == 1 and required["harbors"] == 1 and required["starter_ships"] == 3
    assert required["normal_npc_roles"] == 3 and required["elite_roles"] == required["admirals"] == required["monsters"] == 1
    strategy = contract["ship_model_strategy"]
    assert strategy["initial_production"] == "ONE_COMPLETE_3D_MODEL_PER_SHIP"
    assert strategy["modular_ship_system_required"] is False and strategy["modular_ship_system_deferred"] is True
    assert strategy["required_complete_parts"] == ["hull", "bow", "stern", "deck", "masts", "sails", "characteristic_design_parts"]
    locks = contract["gameplay_locks"]
    assert locks["sea_map_is_core"] and locks["tap_to_sail"] and locks["camera_joystick_camera_only"]
    assert locks["target_attack_reload_loop"] and locks["hull_and_shield_are_separate"]
    assert locks["cannons_primary_against_ships"] and locks["harpoons_primary_against_monsters"]
    assert locks["default_auto_fire"] is False and locks["auto_chase"] is False and locks["broadside_angle_changes_damage"] is False
    evidence = contract["evidence_policy"]
    assert evidence["static_tests_are_not_native_gameplay_qa"] and evidence["source_ready_is_not_release_ready"]
    assert "approve release" in contract["authority"]["m289_never"]


def test_m289_content_manifest_resolves_replaceable_complete_model_placeholders():
    manifest = load("data/m289_playable_vertical_slice_content_manifest.json")
    assert manifest["milestone"] == "M289" and manifest["status"] == "PLACEHOLDER_INTAKE_READY_FINAL_ART_PENDING"
    assert len(manifest["starter_ships"]) == 3 and len(manifest["normal_npcs"]) == 3
    assert {x["kind"] for x in manifest["priority_encounters"]} == {"ELITE", "ADMIRAL", "MONSTER"}
    assets = [manifest["harbor"], *manifest["starter_ships"], *manifest["normal_npcs"], *manifest["priority_encounters"]]
    for asset in assets:
        assert asset["final_asset_required"] is True
        assert asset["placeholder"].startswith("res://")
        assert (ROOT / asset["placeholder"].removeprefix("res://")).is_file()
    assert all(ship["model_strategy"] == "ONE_COMPLETE_GLB" for ship in manifest["starter_ships"])
    rules = manifest["rules"]
    assert rules["all_initial_ships_are_complete_individual_models"]
    assert rules["modular_ship_parts_required"] is False and rules["placeholder_assets_do_not_count_as_final_art"]
    loadout = manifest["combat_loadout"]
    assert loadout["cannon_families"] == ["LIGHT", "STANDARD", "HEAVY"]
    assert loadout["harpoon_required"] and loadout["repair_required"] and loadout["shield_required"]


def test_m289_runtime_is_observer_only_receipt_guarded_and_native_evidence_safe():
    runtime = read("scripts/ui/m289_playable_vertical_slice_runtime.gd")
    assert "class_name M289PlayableVerticalSliceRuntime" in runtime
    for token in ["SLICE_STAGES", "NATIVE_QA_STATES", "REQUIRED_ASSETS", "qa_revision", "last_server_tick", "ingest_server_slice_observation", "ingest_trusted_native_qa_receipt", "readiness_view"]:
        assert token in runtime
    for gate in ["GODOT_4_7_2_BOOT", "DESKTOP_GAMEPLAY_LOOP", "ANDROID_GAMEPLAY_LOOP", "MOBILE_TOUCH_AND_SAFE_AREA", "GPU_FRAME_TIME", "AUDIO_MIX", "HAPTICS", "SINK_RESPAWN_LOOP", "HARBOR_RETURN_LOOP"]:
        assert gate in runtime
    assert "_set_navigation_target" in runtime and "camera_pan" in runtime
    assert '"release_approved":false' in runtime and '"ship_model_strategy":"ONE_COMPLETE_3D_MODEL_PER_SHIP"' in runtime
    for token in [
        "can_authorize_combat_or_targeting() -> bool: return false",
        "can_grant_loot_progression_or_rewards() -> bool: return false",
        "can_commit_movement_or_respawn() -> bool: return false",
        "can_approve_release() -> bool: return false",
        "can_mark_native_qa_pass_without_receipt() -> bool: return false",
        "can_require_modular_ship_models() -> bool: return false",
        "can_transfer_local_observations_to_global() -> bool: return false",
    ]:
        assert token in runtime


def test_m289_integration_admin_native_matrix_and_release_identity():
    bootstrap = read("scripts/core/game_bootstrap.gd")
    hud = read("scripts/ui/game_hud.gd")
    deck = read("scripts/ui/command_deck.gd")
    qa = read("scripts/qa/m289_playable_vertical_slice_qa.gd")
    qa_scene = read("scenes/qa/m289_playable_vertical_slice_qa.tscn")
    assert "M289PlayableVerticalSliceRuntime.new()" in bootstrap and "PlayableVerticalSliceReadiness" in bootstrap
    assert "m289_playable_vertical_slice_state" in hud and "_m289_sync_playable_vertical_slice_state()" in hud
    assert "PLAYABLE VERTICAL SLICE · CONTENT · NATIVE QA" in deck and "M289PlayableVerticalSliceCatalog.authority" in deck
    assert "M289PlayableVerticalSliceQA" in qa and "can_mark_pass() -> bool: return false" in qa and "can_approve_release() -> bool: return false" in qa
    assert "m289_playable_vertical_slice_qa.gd" in qa_scene
    admin = load("data/admin_content_type_registry.json")
    assert admin["milestone"] == "M301"
    assert all(x in admin["content_types"] for x in ["playable_vertical_slice_definition", "vertical_slice_content_manifest_definition", "native_gameplay_qa_evidence_definition", "vertical_slice_performance_capture_profile_definition"])
    matrix = load("data/m239_master_convergence_matrix.json")
    row = {x["domain"]: x for x in matrix["domains"]}["native_playable_vertical_slice_readiness"]
    assert matrix["milestone"] == "M301" and row["status"] == "PARTIAL" and "m289_fix" in row
    native = load("data/m289_native_gameplay_qa_matrix.json")
    assert native["status"] == "NOT_EVALUATED" and native["release_approved"] is False and native["target_engine"] == "Godot 4.7.2"
    assert len(native["gates"]) == 12 and all(gate["state"] == "NOT_EVALUATED" for gate in native["gates"])
    assert native["rules"]["static_tests_cannot_set_pass"]
    release = load("data/release_identity.json")
    assert release["milestone"] == "M301" and release["client_version"] == release["version"] == "0.301.0"
    assert release["build_number"] == 301 and release["content_config_version"] == "M301"
    assert "one complete GLB" in release["m289_readiness_lock"]
