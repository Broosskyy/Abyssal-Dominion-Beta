import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_m201_contract_and_release():
    c=json.loads((ROOT/'data/m201_visual_master_placeholder_contract.json').read_text())
    r=json.loads((ROOT/'data/release_identity.json').read_text())
    assert c['milestone']=='M201'
    assert c['cross_platform_lock']['same_models'] is True
    assert c['cross_platform_lock']['same_world_vfx'] is True
    assert r['build_number']>=201

def test_reference_grade_placeholder_files_exist_and_are_real_glb():
    c=json.loads((ROOT/'data/m201_reference_placeholder_catalog.json').read_text())
    assert len(c['models'])>=11
    assert len(c['ui_icons'])==8
    for row in c['models']:
        p=ROOT/row['path'].replace('res://','')
        assert p.exists() and p.stat().st_size>1000
        assert p.read_bytes()[:4]==b'glTF'
        assert row['final'] is False
    for row in c['ui_icons']:
        p=ROOT/row['path'].replace('res://','')
        assert p.exists() and '<svg' in p.read_text()
        assert row['final'] is False

def test_manifest_uses_m201_for_core_readability_slots():
    m=json.loads((ROOT/'assets/placeholder_pack/manifest.json').read_text())['assets']
    for slot in ['ship_small','ship_medium','ship_large','island_tropical_small','island_tropical_medium','island_cliff_cove','island_sandbar_long','loot_chest_common','loot_coin_cache','loot_salvage_bundle','repair_crate']:
        assert '/m201_reference/models/' in m[slot]['path']
        assert m[slot]['classification']=='M201_REFERENCE_GRADE_PLACEHOLDER'
        assert m[slot]['counts_as_final'] is False

def test_cross_platform_placeholder_quality_is_canonical():
    text=(ROOT/'scripts/visual/production_placeholder_contract.gd').read_text()
    assert '"lod":"LOD1"' in text
    assert '"vfx_quality":"canonical"' in text
    assert '"vfx_quality":"mobile" if compact else "desktop"' not in text
    icon=(ROOT/'scripts/ui/m201_reference_icon_catalog.gd').read_text()
    assert 'cross_platform_asset_parity' in icon
    port=(ROOT/'scripts/world/port_factory.gd').read_text()
    assert 'M201Roof' in port and 'M201GoldAccent' in port
