import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def load(p):return json.loads((R/p).read_text())

def test_release_and_contract():
 d=load('data/release_identity.json');assert d['build_number']>=197
 c=load('data/m197_regional_encounter_zones.json');assert c['milestone']=='M197'
 assert c['locks']['cross_platform_world_parity'] is True
 assert c['locks']['chart_size_world_units']==360 and c['locks']['combat_math_unchanged'] is True

def test_regional_zone_catalog_is_platform_neutral():
 s=(R/'scripts/world/regional_encounter_zone_catalog.gd').read_text()
 assert 'REGION_PROFILES' in s and 'safe_lane' in s and 'monster' in s and 'admiral' in s
 assert 'OS.has_feature' not in s and 'RuntimeQualityBudget' not in s
 assert 'abyssal_frontier' in s and 'drowned_reach' in s and 'stormbound_expanse' in s

def test_encounter_director_uses_authored_zones_and_safe_lane():
 s=(R/'scripts/world/encounter_director.gd').read_text()
 assert '_find_spawn_position(kind:String="patrol",slot:int=0)' in s
 assert 'RegionalEncounterZoneCatalog.anchor(encounter_region_id,kind' in s
 assert '_inside_safe_lane(candidate,lane,lane_radius)' in s
 assert '_find_spawn_position("monster",slot)' in s
 assert 'encounter_zone_kind' in s and 'encounter_zone_region' in s
 assert 'world.sector_spawn_extent()' in s

def test_existing_movement_parity_lock_remains():
 c=load('data/m196_regional_world_identity.json')
 assert c['locks']['land_blocks_units_do_not'] is True
 q=(R/'scripts/core/runtime_quality_budget.gd').read_text()
 assert 'gameplay/simulation budgets are canonical and never platform-dependent' in q
