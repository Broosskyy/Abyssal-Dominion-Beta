import hashlib
import json
from pathlib import Path
import struct


ROOT = Path(__file__).resolve().parents[1]
CONTRACT = json.loads((ROOT / 'data/m297_early_npc_complete_model_contract.json').read_text())
MANIFEST = json.loads((ROOT / 'assets/placeholder_pack/manifest.json').read_text())['assets']


def test_m297_all_early_npcs_unique_stable_complete_placeholders():
    assert CONTRACT['milestone'] == 'M297' and CONTRACT['master_concept'] == 'V3.8'
    assert CONTRACT['new_models_single_node_single_mesh'] and CONTRACT['old_sources_preserved_as_fallback']
    assert CONTRACT['replacement_same_stable_slot'] and not CONTRACT['final_art']
    assert len(CONTRACT['active_early_npc_slots']) == 5
    paths = [MANIFEST[asset_id]['path'] for asset_id in CONTRACT['active_early_npc_slots']]
    hashes = [MANIFEST[asset_id]['sha256'] for asset_id in CONTRACT['active_early_npc_slots']]
    assert len(set(paths)) == len(set(hashes)) == 5
    for asset_id in CONTRACT['active_early_npc_slots']:
        slot = MANIFEST[asset_id]
        assert slot['classification'].endswith('GLB_PLACEHOLDER')
        assert hashlib.sha256((ROOT / slot['path'].removeprefix('res://')).read_bytes()).hexdigest() == slot['sha256']


def test_m297_new_glb_binary_structure_geometry_and_source_integrity():
    for row in CONTRACT['new_models']:
        file = ROOT / row['path'].removeprefix('res://')
        raw = file.read_bytes()
        assert len(raw) == MANIFEST[row['id']]['bytes'] == row['bytes']
        assert hashlib.sha256(raw).hexdigest() == MANIFEST[row['id']]['sha256'] == row['sha256']
        assert MANIFEST[row['id']]['path'] == row['path']
        assert MANIFEST[row['id']]['surfaces'] == row['surfaces']
        assert MANIFEST[row['id']]['triangles'] == row['triangles']
        assert struct.unpack_from('<4sII', raw) == (b'glTF', 2, len(raw))
        n, kind = struct.unpack_from('<I4s', raw, 12)
        assert kind == b'JSON' and n % 4 == 0
        document = json.loads(raw[20:20 + n])
        bin_len, kind = struct.unpack_from('<I4s', raw, 20 + n)
        assert kind == b'BIN\x00' and 28 + n + bin_len == len(raw)
        assert len(document['nodes']) == len(document['meshes']) == 1
        assert document['nodes'][0]['mesh'] == 0
        assert not document.get('skins') and not document.get('animations')
        surfaces = document['meshes'][0]['primitives']
        assert len(surfaces) == row['surfaces'] and len(surfaces) > 6
        triangles = 0
        for part in surfaces:
            assert part['mode'] == 4
            position = document['accessors'][part['attributes']['POSITION']]
            normal = document['accessors'][part['attributes']['NORMAL']]
            assert position['count'] == normal['count']
            assert all(low < high for low, high in zip(position['min'], position['max']))
            if 'indices' not in part:
                assert position['count'] % 3 == 0
                triangles += position['count'] // 3
                continue
            indices = document['accessors'][part['indices']]
            assert indices['componentType'] == 5123 and indices['count'] % 3 == 0
            view = document['bufferViews'][indices['bufferView']]
            offset = 28 + n + view.get('byteOffset', 0) + indices.get('byteOffset', 0)
            assert offset + 2 * indices['count'] <= len(raw)
            assert max(struct.unpack_from('<H', raw, offset + i*2)[0]
                       for i in range(indices['count'])) < position['count']
            triangles += indices['count'] // 3
        assert triangles == row['triangles']


def test_m297_active_visuals_skip_structural_overlay_and_slice_references_match():
    decorator = (ROOT / 'scripts/visual/p0_npc_fallback_decorator.gd').read_text()
    runtime = (ROOT / 'scripts/ui/m289_playable_vertical_slice_runtime.gd').read_text()
    content = (ROOT / 'data/m289_playable_vertical_slice_content_manifest.json').read_text()
    sortie = json.loads((ROOT / 'data/m290_first_sortie_placeholder_manifest.json').read_text())
    for row in CONTRACT['new_models']:
        assert ('id == "' + row['id'] + '" and str(visual.get_meta("source_path", "")) == "' +
                row['path'] + '": return') in decorator
        assert row['path'] in runtime and row['path'] in content
        assert next(x for x in sortie['stable_model_slots'] if x['id'] == row['id'])['path'] == row['path']
    assert 'ShipAssetAcceptance.is_p0_ship(id)' in (ROOT / 'scripts/visual/asset_visual_library.gd').read_text()
    assert CONTRACT['native_qa'] == 'NOT_EVALUATED'
    assert 'server combat truth' in CONTRACT['does_not_change']


def test_m297_release_and_reproducible_sources():
    release = json.loads((ROOT / 'data/release_identity.json').read_text())
    assert (release['milestone'], release['client_version'], release['version'], release['build_number'],
            release['content_config_version']) == ('M301', '0.301.0', '0.301.0', 301, 'M301')
    assert 'all five active early NPC' in release['m297_early_npc_model_lock']
    build = (ROOT / 'tools/m297_build_remaining_npc_glbs.py').read_text()
    assert 'source_sha256' in build and '_boxes' in build and '_morph' in build
