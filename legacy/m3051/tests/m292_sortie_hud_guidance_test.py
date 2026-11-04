import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def src(path):
    return (ROOT / path).read_text()


def test_m292_contract_keeps_layout_priority_and_non_authority():
    contract = json.loads(src('data/m292_sortie_hud_guidance_contract.json'))
    assert contract['milestone'] == 'M292' and contract['master_concept'] == 'V3.8'
    assert contract['genre_ux_references'] == ['Seafight', 'Battle of Sea']
    assert contract['layout']['camera_joystick'] == 'bottom_left_camera_only_unchanged'
    assert contract['layout']['mobile_primary_attack'] == 'bottom_right_unchanged'
    assert contract['layout']['beacons'] == 'one_existing_replaceable_world_beacon_maximum'
    assert contract['initial_ship_model'] == 'ONE_COMPLETE_GLB_PER_SHIP'
    assert not any(contract['evidence'][k] for k in ['navigation_intent_proves_arrival', 'presentation_fire_proves_hit', 'repair_intent_proves_healing', 'static_tests_prove_native_playability', 'release_approved'])


def test_m292_quest_owns_panel_and_compact_guidance_reuses_it():
    hud = src('scripts/ui/nautical_hud.gd')
    assert 'show_sortie := tracked_objective.is_empty() and not sortie.is_empty()' in hud
    assert '"ERSTE AUSFAHRT" if show_sortie else "VERFOLGTES ZIEL"' in hud
    assert '"title": str(sortie.get("next_label"' in hud
    assert '"detail": str(sortie.get("hint"' in hud
    assert '"progress": float(sortie.get("progress"' in hud
    assert 'if not show_sortie_in_mission:' in hud
    game_hud = src('scripts/ui/game_hud.gd')
    assert 'if mission.size.x < 192.0: return' in game_hud
    assert 'var label := "%d/%d"' in game_hud
    assert 'var width := minf(48.0, mission.size.x * 0.22)' in game_hud


def test_m292_evidence_counts_and_release_readiness_remain_explicit():
    runtime = src('scripts/ui/m290_first_sortie_integration_runtime.gd')
    assert 'if bool((observations[stage_id] as Dictionary).get("server_verified", false))' in runtime
    assert '"local_core":core_observed - server_verified_core' in runtime
    assert '"milestone":"M301"' in runtime
    assert '"release_approved":false' in runtime
    deck = src('scripts/ui/command_deck.gd')
    assert 'M290FirstSortieCatalog.m292_guidance()' in deck
    assert 'int(view.server_verified_core)' in src('scripts/ui/m290_first_sortie_catalog.gd')
    release = json.loads(src('data/release_identity.json'))
    assert (release['milestone'], release['version'], release['client_version'], release['build_number'], release['content_config_version']) == ('M301', '0.301.0', '0.301.0', 301, 'M301')
