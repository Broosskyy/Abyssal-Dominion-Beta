import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def load(p): return json.loads((R/p).read_text())

def test_release_and_contract():
 d=load('data/release_identity.json'); assert d['build_number']>=196
 c=load('data/m196_regional_world_identity.json'); assert c['locks']['cross_platform_world_parity'] is True
 assert c['locks']['island_count_all_platforms']==8 and c['locks']['chart_size_world_units']==360

def test_region_drives_macro_layout_not_device():
 s=(R/'scripts/world/chart_composition_catalog.gd').read_text()
 assert 'REGION_PROFILES' in s and 'REGION_POI_MIX' in s and 'region_id:String' in s
 assert 'OS.has_feature' not in s and 'platform_key' not in s
 assert 'storm_chokepoints_with_outer_bypass' in s and 'rift_ring_and_monster_corridor' in s

def test_all_eight_island_profiles_are_always_authored():
 s=(R/'scripts/world/world_map_system.gd').read_text()
 assert '{"radius": 1.8, "aspect": Vector2(1.85, 0.52)' in s
 assert '_runtime_seed()%2==1' not in s
 assert 'ChartCompositionCatalog.island_anchor(index,_runtime_seed(),sector_spawn_extent(),str(data.get("region_id","")))' in s

def test_pois_are_region_aware_but_keep_existing_authority():
 s=(R/'scripts/world/world_poi_composer.gd').read_text()
 assert 'ChartCompositionCatalog.poi_mix(region_id,level)' in s
 assert 'ChartCompositionCatalog.poi_anchor(index,seed_value,EXTENT,region_id)' in s
 assert 'poi.set_meta("visual_only",false)' in s and 'interaction_radius' in s
