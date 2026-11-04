from pathlib import Path
import json
ROOT = Path(__file__).resolve().parents[1]

def test_m191_release_and_locks():
    data=json.loads((ROOT/'data/m191_coast_wake_world_readability.json').read_text())
    release=json.loads((ROOT/'data/release_identity.json').read_text())
    assert data['milestone']=='M191'
    assert release['build_number']>=191
    assert data['locks']['visual_only_coast_dressing'] is True
    assert data['locks']['collision_navigation_unchanged'] is True
    assert data['locks']['combat_ranges_unchanged'] is True

def test_shallow_coast_is_visual_only_and_perimeter_biased():
    src=(ROOT/'scripts/world/shallow_coast_dressing.gd').read_text()
    assert 'M191ShallowWaterShelf' in src
    assert 'radius*0.93' in src
    assert 'visual_only' in src
    assert 'TRANSPARENCY_ALPHA' in src

def test_wake_has_speed_driven_center_turbulence():
    src=(ROOT/'scripts/visual/ship_wake.gd').read_text()
    assert 'M191CenterTurbulence' in src
    assert 'lerp(0.55, 4.8' in src
    assert 'lerp(0.0, 0.20' in src
    assert 'speed_ratio' in src

def test_island_fallback_breaks_round_silhouette_without_authority():
    src=(ROOT/'scripts/visual/island_fallback_composer.gd').read_text()
    assert 'M191EdgeBreak' in src
    assert 'visual_only' in src
    assert 'Collision/navigation remain' in src
