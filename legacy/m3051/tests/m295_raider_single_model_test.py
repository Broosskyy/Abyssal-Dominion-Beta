import hashlib
import json
from pathlib import Path
import struct


ROOT = Path(__file__).resolve().parents[1]
RAIDER = ROOT / 'assets/production_placeholders/m295/npc_raider_01.glb'
SCOUT = ROOT / 'assets/production_placeholders/p0/npc_scout_01.glb'


def src(path):
    return (ROOT / path).read_text()


def glb(path):
    raw = path.read_bytes()
    magic, version, length = struct.unpack_from('<4sII', raw)
    assert (magic, version, length) == (b'glTF', 2, len(raw))
    doc_len, kind = struct.unpack_from('<I4s', raw, 12)
    assert kind == b'JSON'
    doc = json.loads(raw[20:20 + doc_len])
    bin_len, bin_kind = struct.unpack_from('<I4s', raw, 20 + doc_len)
    assert bin_kind == b'BIN\x00' and 20 + doc_len + 8 + bin_len == len(raw)
    return doc, raw[28 + doc_len:]


def test_m295_raider_has_distinct_complete_glb_and_reproducible_hash():
    data = json.loads(src('data/m295_raider_single_model_placeholder_contract.json'))
    assert data['milestone'] == 'M295' and data['master_concept'] == 'V3.8'
    assert data['clean_room_references'] == ['Seafight', 'Battle of Sea']
    assert data['complete_model'] and data['single_node'] and data['single_mesh']
    assert not data['runtime_structural_overlays'] and not data['modular_ship_construction'] and not data['final_art']
    assert hashlib.sha256(RAIDER.read_bytes()).hexdigest() == data['sha256']
    assert hashlib.sha256(RAIDER.read_bytes()).digest() != hashlib.sha256(SCOUT.read_bytes()).digest()
    assert 'EXPECTED_SOURCE_SHA256' in src('tools/m295_build_raider_glb.py')


def test_m295_glb_is_one_ship_scene_with_real_geometry_and_distinct_silhouette():
    raider, binary = glb(RAIDER)
    scout, _ = glb(SCOUT)
    assert len(raider['nodes']) == len(raider['meshes']) == 1
    assert raider['nodes'][0]['mesh'] == 0
    assert not raider.get('skins') and not raider.get('animations')
    assert len(raider['meshes'][0]['primitives']) == 6
    assert sum(p['mode'] == 4 for p in raider['meshes'][0]['primitives']) == 6
    assert len(binary) == raider['buffers'][0]['byteLength'] or len(binary) - raider['buffers'][0]['byteLength'] < 4
    def width(doc):
        values = []
        for primitive in doc['meshes'][0]['primitives']:
            accessor = doc['accessors'][primitive['attributes']['POSITION']]
            values.extend([accessor['min'][0], accessor['max'][0]])
        return max(values) - min(values)
    assert width(raider) > width(scout) * 1.05
    assert [m['pbrMetallicRoughness']['baseColorFactor'] for m in raider['materials']] != [m['pbrMetallicRoughness']['baseColorFactor'] for m in scout['materials']]


def test_m295_stable_asset_slot_and_no_runtime_ship_part_overlay():
    path = 'res://assets/production_placeholders/m295/npc_raider_01.glb'
    manifest = json.loads(src('assets/placeholder_pack/manifest.json'))['assets']['npc_raider_01']
    assert manifest['path'] == path and manifest['sha256'] == hashlib.sha256(RAIDER.read_bytes()).hexdigest()
    assert manifest['bytes'] == RAIDER.stat().st_size and 'GLB_PLACEHOLDER' in manifest['classification']
    intake = json.loads(src('data/m290_first_sortie_placeholder_manifest.json'))
    assert [row for row in intake['stable_model_slots'] if row['id'] == 'npc_raider_01'][0]['path'] == path
    assert path in src('scripts/ui/m289_playable_vertical_slice_runtime.gd')
    assert path in src('data/m289_playable_vertical_slice_content_manifest.json')
    decorator = src('scripts/visual/p0_npc_fallback_decorator.gd')
    assert 'id == "npc_raider_01" and str(visual.get_meta("source_path", "")) == "' + path + '": return' in decorator


def test_m295_release_and_authority_boundary():
    release = json.loads(src('data/release_identity.json'))
    assert (release['milestone'], release['client_version'], release['version'], release['build_number']) == ('M301', '0.301.0', '0.301.0', 301)
    assert 'complete Raider GLB' in release['m295_single_model_lock']
    contract = json.loads(src('data/m295_raider_single_model_placeholder_contract.json'))
    assert 'ShipMotor collision' in contract['does_not_change']
    assert 'server combat truth' in contract['does_not_change']
    assert contract['native_qa'] == 'NOT_EVALUATED'
