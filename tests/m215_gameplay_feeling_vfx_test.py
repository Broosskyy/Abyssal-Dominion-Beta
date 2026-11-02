import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_m215_contract_and_gameplay_locks():
    d=json.loads((ROOT/'data/m215_gameplay_feeling_vfx_contract.json').read_text())
    assert d['milestone'] in {'M215','M216','M217','M218','M219', 'M245','M246','M247','M248','M249'}
    assert d['cross_platform_visual_parity'] is True
    assert all(v is False for v in d['gameplay_locks'].values())
    assert d['native_visual_qa_required'] is True

def test_m215_world_vfx_layers_exist():
    wake=(ROOT/'scripts/visual/ship_wake.gd').read_text()
    water=(ROOT/'scripts/visual/water_surface.gd').read_text()
    splash=(ROOT/'scripts/visual/water_splash.gd').read_text()
    impact=(ROOT/'scripts/visual/impact_fx.gd').read_text()
    loot=(ROOT/'scripts/gameplay/loot_pickup.gd').read_text()
    assert 'M215SternBreak' in wake and 'M215WakeSpine' in wake
    assert 'm215_whitecap_detail' in water
    assert 'M215WaterImpactRing' in splash
    assert 'M215ImpactWaterShock' in impact
    assert 'M215LootCollectionFX' in loot

def test_m215_preserves_important_regression_tokens():
    water=(ROOT/'scripts/visual/water_surface.gd').read_text()
    projectile=(ROOT/'scripts/gameplay/cannon_projectile.gd').read_text()
    loot=(ROOT/'scripts/gameplay/loot_pickup.gd').read_text()
    assert 'NORMAL_MAP_DEPTH = 0.22' in water
    assert 'METALLIC = 0.0' in water
    assert '* 0.032' in water
    assert 'trail_mesh.height = 1.58' in projectile
    assert 'shape.radius=float(GameplayRuleset.get_path(get_tree(),"loot.pickup_radius",0.85))' in loot
