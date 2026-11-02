import json
import hashlib
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text()


def test_m301_server_rules_cover_hostile_tower_and_event_damage():
    config = json.loads(read('data/m301_halloween_guild_server_config.json'))
    server = read('server/halloween_guild_domain.py')
    assert config['authority'] == 'SERVER_DOMAIN_ONLY'
    assert set(config['tower_profiles']) == {'cannon', 'chain', 'mortar', 'ward', 'hunter'}
    assert 'BEGIN IMMEDIATE' in server and 'CREATE TABLE IF NOT EXISTS commands' in server
    assert 'def tick_towers(' in server and 'def fire(' in server and 'def collect_pumpkin(' in server
    assert 'if kind == "pumpkin_wreck" and weapon != "HARPOON"' in server
    assert '"PENDING_M266"' in server
    assert 'ORDER BY damage DESC,captain ASC' in server


def test_m301_client_only_prototypes_are_explicit_and_assets_are_independent():
    world = read('scripts/events/halloween_event_world.gd')
    fleet = read('scripts/events/halloween_event_encounters.gd')
    catalog = read('scripts/combat/combat_catalog.gd')
    config = json.loads(read('data/m301_halloween_guild_server_config.json'))
    slots = json.loads(read('data/visual_slots.json'))
    assert 'server_spawn_identity_required' in world
    assert 'event_halloween_pumpkin_wreck_01' in world and 'event_halloween_pumpkin_01' in world
    assert 'LOCAL_PREVIEW_ONLY' in fleet and 'M301DrownedFleetIdentity' in fleet
    assert '"id":"pumpkin"' in catalog
    assert config['pumpkin_event_damage_multiplier'] > 1
    assert (ROOT / slots['ui']['m301_pumpkin_ammo']['path'].removeprefix('res://')).is_file()


def test_m301_release_is_not_live_or_approved():
    release = json.loads(read('data/release_identity.json'))
    assert (release['milestone'], release['client_version'], release['build_number']) == ('M301', '0.301.0', 301)
    assert release['m301_server_slice_lock'].startswith('Source-level server domain only')
    assert 'NOT_EVALUATED' in read('M301_SERVER_SLICE_REPORT.md')


def test_m301_halloween_npcs_and_prize_are_three_distinct_complete_models():
    manifest = json.loads(read('assets/placeholder_pack/manifest.json'))['assets']
    ids = ('event_halloween_npc_sloop_01', 'event_halloween_npc_raider_01', 'event_halloween_ship_design_01')
    hashes = set()
    for key in ids:
        entry = manifest[key]
        raw = (ROOT / entry['path'].removeprefix('res://')).read_bytes()
        digest = hashlib.sha256(raw).hexdigest()
        assert digest == entry['sha256'] and digest not in hashes
        hashes.add(digest)
        magic, version, total = struct.unpack_from('<4sII', raw)
        assert (magic, version, total) == (b'glTF', 2, len(raw))
        length = struct.unpack_from('<I', raw, 12)[0]
        document = json.loads(raw[20:20 + length])
        assert len(document['nodes']) == len(document['meshes']) == 1
    assert 'event_halloween_npc_sloop_01' in read('scripts/events/halloween_event_encounters.gd')
