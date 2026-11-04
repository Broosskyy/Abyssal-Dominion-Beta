import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load(name):
    return json.loads((ROOT / name).read_text())


def source(name):
    return (ROOT / name).read_text()


def test_m298_profile_ids_clamped_and_all_active_models_available():
    contract = load('data/m298_ship_visual_animation_contract.json')
    profiles = load('data/m298_ship_visual_animation_profiles.json')
    assets = load('assets/placeholder_pack/manifest.json')['assets']
    assert contract['milestone'] == profiles['milestone'] == 'M298'
    assert contract['master_concept'] == profiles['master_concept'] == 'V3.8'
    assert len(contract['covered_slots']) == len(profiles['slots']) == 8
    assert set(contract['covered_slots']) == set(profiles['slots'])
    assert contract['ship_construction'] == 'ONE_COMPLETE_INDIVIDUAL_3D_MODEL_PER_SHIP'
    assert contract['native_qa'] == profiles['native_qa'] == 'NOT_EVALUATED'
    assert list(profiles['confirmed_defeat_phase_offsets_m']) == list(profiles['confirmed_defeat_phase_roll_deg'])
    assert all(0.0 <= n <= 2.1 for n in profiles['confirmed_defeat_phase_offsets_m'].values())
    assert all(0.0 <= n <= 8.0 for n in profiles['confirmed_defeat_phase_roll_deg'].values())
    for asset_id in contract['covered_slots']:
        path = assets[asset_id]['path'].removeprefix('res://')
        assert path.endswith('.glb') and (ROOT / path).is_file()
        profile = profiles['slots'][asset_id]
        assert profile['profile'] in {'LIGHT', 'BALANCED', 'HEAVY'}
        assert 0.0 <= profile['heave_m'] <= 0.07
        assert 0.0 <= profile['pitch_deg'] <= 1.2
        assert 0.0 <= profile['roll_deg'] <= 1.4
        assert 0.0 <= profile['turn_heel_deg'] <= 1.5
        assert 0.0 <= profile['hull_hit_heel_deg'] <= 1.8
        assert 0.1 <= profile['cycles_per_second'] <= 0.6


def test_m298_animates_model_only_and_respects_replacement_preview_accessibility():
    visual = source('scripts/visual/asset_visual_library.gd')
    rig = source('scripts/visual/m298_ship_visual_animation_rig.gd')
    assert 'M298ShipVisualAnimationRigScript.new()' in visual
    assert 'if parent is ShipMotor and replacement.is_empty() and M298ShipVisualAnimationRig.supports_slot(id):' in visual
    assert 'visual.add_child(animation)' in visual
    assert 'visual.get_node_or_null("Model")' in rig
    assert '_model.position = ' in rig and '_model.rotation = ' in rig
    assert 'ship.position =' not in rig and '_ship.position =' not in rig
    assert 'ship.rotation =' not in rig and '_ship.rotation =' not in rig
    assert '_reduced_motion' in rig and 'ambient := 0.0 if _reduced_motion or _defeated' in rig
    assert '_mobile_budget' in rig and '_sample_left = 0.08' in rig
    for guard in ('can_move_ship()', 'can_change_collision()', 'can_confirm_hit()', 'can_apply_damage()'):
        assert 'func ' + guard + ' -> bool: return false' in rig


def test_m298_motion_reads_m287_and_confirmed_m285_without_fabricating_hits():
    rig = source('scripts/visual/m298_ship_visual_animation_rig.gd')
    motion = source('scripts/visual/m287_ship_motion_visual_rig.gd')
    damage = source('scripts/visual/m285_ship_damage_visual_rig.gd')
    defeat = source('scripts/visual/m286_ship_damage_overlay_rig.gd')
    assert 'var motion := _motion.snapshot()' in rig
    assert 'if bool(motion.get("server_mode", false)) or _local_preview_allowed():' in rig
    assert 'var impact := _damage.reaction_presentation()' in rig
    assert 'if not server_verified or str(event.get("source", "")) != "SERVER"' in damage
    assert '"SHIELD_HIT": _shield_flash_left = 0.24' in damage
    assert '"hull": clampf(_hull_flash_left / 0.18' in damage
    assert 'if shield_state == "BROKEN":' not in damage
    assert 'Only a verified impact event' in damage
    assert 'func snapshot() -> Dictionary:' in motion
    assert 'var offsets: Dictionary = _profile.get("defeat_phase_offsets_m", {})' in rig
    assert 'var phase_view := _defeat.snapshot()' in rig
    assert 'if not bool(phase_view.get("qa_preview_mode", false)) or _local_qa_allowed():' in rig
    assert 'if not server_verified or str(state.get("source", "")) != "SERVER"' in defeat
    assert 'if not server_verified or str(event.get("source", "")) != "SERVER"' in defeat
    assert 'server combat truth' not in rig.lower()  # no game-state decision engine
    contract = load('data/m298_ship_visual_animation_contract.json')
    assert contract['authority'] == 'PRESENTATION_ONLY'
    assert 'Tap-to-Sail course' in contract['must_not_change']
    assert 'camera-only joystick' in contract['must_not_change']


def test_m298_release_master_matrix_and_no_code_profile_foundation():
    release = load('data/release_identity.json')
    assert (release['milestone'], release['client_version'], release['version'], release['build_number'],
            release['content_config_version']) == ('M301', '0.301.0', '0.301.0', 301, 'M301')
    assert 'M298 presentation-only' in release['visual_master_lock']
    assert 'whole-model animation' in release['m298_model_animation_lock']
    matrix = load('data/m239_master_convergence_matrix.json')
    assert matrix['milestone'] == 'M301'
    row = next(x for x in matrix['domains'] if x['domain'] == 'first_sea_sortie_runtime_integration_guidance')
    assert row['status'] == 'PARTIAL' and 'm298_fix' in row
    admin = load('data/admin_content_type_registry.json')
    assert admin['milestone'] == 'M301'
    profile = admin['content_types']['ship_visual_animation_profile_definition']
    assert profile['status'] == 'FOUNDATION' and profile['authority'] == 'VERSIONED_CONTENT'
