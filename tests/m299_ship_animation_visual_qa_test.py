import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text()


def load(path):
    return json.loads(read(path))


def test_m299_visual_qa_eight_complete_models_scenarios_and_native_gates():
    contract = load('data/m299_ship_animation_visual_qa_contract.json')
    matrix = load('data/m299_ship_animation_visual_qa_matrix.json')
    assets = load('assets/placeholder_pack/manifest.json')['assets']
    assert contract['milestone'] == matrix['milestone'] == 'M299'
    assert contract['master_concept'] == 'V3.8'
    assert len(contract['slots']) == 8 and len(set(contract['slots'])) == 8
    assert len(contract['scenarios']) == 12 and len(matrix['manual_checks']) == 8
    assert contract['scenarios'][-1] == 'RESET'
    assert matrix['status'] == contract['native_qa'] == 'NOT_EVALUATED'
    assert matrix['requires_native_godot'] and all(row['status'] == 'NOT_EVALUATED' for row in matrix['manual_checks'])
    assert not contract['release_approved'] and contract['authority'] == 'NONE'
    assert matrix['scene'] == contract['scene']
    for slot in contract['slots']:
        assert (ROOT / assets[slot]['path'].removeprefix('res://')).is_file()


def test_m299_isolated_scene_responsive_view_and_no_server_event_forgery():
    contract = load('data/m299_ship_animation_visual_qa_contract.json')
    scene = read('scenes/qa/m299_ship_animation_visual_qa.tscn')
    script = read('scripts/qa/m299_ship_animation_visual_qa.gd')
    assert 'res://scripts/qa/m299_ship_animation_visual_qa.gd' in scene
    assert 'class_name M299ShipAnimationVisualQA' in script
    assert 'root.set_meta("m299_animation_qa", true)' in script
    assert '_exit_tree()' in script and 'root.set_meta("m299_animation_qa", false)' in script
    assert 'str(root.get_meta("environment_id", "LOCAL_DEVELOPMENT")) != "LOCAL_DEVELOPMENT"' in script
    assert 'root.get_meta("server_authority_verified", false)' in script
    assert 'columns := 2 if _compact_layout else 4' in script
    assert 'camera.fov = 55.0 if _compact_layout else 47.0' in script
    assert 'AssetVisualLibrary.install(ship, slot_id' in script
    assert 'ship.set_physics_process(false)' in script
    assert 'apply_local_qa_preview(' in script
    assert 'apply_local_qa_defeat_phase(' in script
    assert 'play_local_qa_reaction(' in script
    assert 'apply_server_motion_state(' not in script
    assert 'ingest_server_motion_event(' not in script
    assert 'NATIVE QA: NICHT AUSGEWERTET' in script
    assert contract['ship_rule'].startswith('one complete individual GLB')


def test_m299_qa_helpers_reject_online_and_server_presentation_priority():
    motion = read('scripts/visual/m287_ship_motion_visual_rig.gd')
    damage = read('scripts/visual/m285_ship_damage_visual_rig.gd')
    defeat = read('scripts/visual/m286_ship_damage_overlay_rig.gd')
    assert 'if not _local_qa_allowed() or _server_mode: return false' in motion
    assert 'if not _local_qa_allowed() or _server_presentation_mode: return false' in damage
    assert 'if not _local_qa_allowed() or _server_presentation_mode: return false' in defeat
    for script in (motion, damage, defeat):
        assert 'm299_animation_qa' in script and 'server_authority_verified' in script
        assert 'LOCAL_DEVELOPMENT' in script
    assert 'if _qa_preview_mode and not _local_qa_allowed():' in motion
    assert 'if _qa_preview_flash and not _local_qa_allowed():' in damage
    assert 'if _qa_preview_mode and not _local_qa_allowed():' in defeat
    assert 'if not _server_mode:\n\t\t_speed_ratio = 0.0' in motion
    assert '_server_mode = true' in motion
    assert 'or _server_presentation_mode:' in damage
    assert 'if _local_preview_allowed() and not _server_presentation_mode:' in damage
    assert 'if kind.to_upper() not in' in motion and 'if kind.to_upper() not in' in damage and 'if kind.to_upper() not in' in defeat


def test_m299_release_and_master_hud_boundaries():
    release = load('data/release_identity.json')
    assert (release['milestone'], release['client_version'], release['version'], release['build_number'], release['content_config_version']) == ('M301', '0.301.0', '0.301.0', 301, 'M301')
    assert 'M299 isolated eight-ship responsive visual QA' in release['visual_master_lock']
    assert 'no SERVER event forgery' in release['m299_visual_qa_lock']
    admin = load('data/admin_content_type_registry.json')
    matrix = load('data/m239_master_convergence_matrix.json')
    assert admin['milestone'] == matrix['milestone'] == 'M301'
    row = next(x for x in matrix['domains'] if x['domain'] == 'first_sea_sortie_runtime_integration_guidance')
    assert row['status'] == 'PARTIAL' and 'm299_fix' in row
    contract = load('data/m299_ship_animation_visual_qa_contract.json')
    assert contract['master_hud'].startswith('gameplay HUD unchanged')
    assert 'camera-only' in contract['controls']
