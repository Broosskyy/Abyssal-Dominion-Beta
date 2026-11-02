import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def load(p): return json.loads((R/p).read_text())
def test_release_and_contract():
 d=load('data/release_identity.json'); assert d['build_number']>=195
 c=load('data/m195_regional_chart_composition.json'); assert c['locks']['cross_platform_world_parity'] is True and c['locks']['chart_size_world_units']==360

def test_macro_chart_anchors_are_platform_neutral():
 s=(R/'scripts/world/chart_composition_catalog.gd').read_text(); assert 'BASE_ISLAND_ANCHORS' in s and 'POI_ANCHORS' in s and 'device' in s.lower()
 w=(R/'scripts/world/world_map_system.gd').read_text(); assert 'ChartCompositionCatalog.island_anchor' in w and 'preferred.is_finite()' in w

def test_pois_use_full_chart_not_old_prototype_patch():
 s=(R/'scripts/world/world_poi_composer.gd').read_text(); assert 'const EXTENT:=155.0' in s and 'ChartCompositionCatalog.poi_anchor' in s
 assert 'randf_range(-27.0,27.0)' not in s and 'randf_range(-25.0,25.0)' not in s

def test_audit_no_mobile_desktop_world_divergence():
 s=(R/'M193_MASTER_REFERENCE_AUDIT.md').read_text(); assert '6 islands mobile/web, 8 desktop' not in s and '8 identical island composition slots on every platform' in s
