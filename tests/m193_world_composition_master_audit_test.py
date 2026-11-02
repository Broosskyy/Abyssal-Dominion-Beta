from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]

def test_m193_contract_and_audit():
    c=json.loads((ROOT/'data/m193_world_composition_contract.json').read_text())
    assert c['chart']['world_units']==360
    assert c['chart']['technical_sector_ids_hidden'] is True
    assert c['chart']['target_island_budget']=={'mobile':8,'web':8,'desktop':8}
    assert c['movement_locks']['land_blocks_and_routes_around'] is True
    assert c['movement_locks']['ships_npcs_monsters_bosses_overlap'] is True
    audit=(ROOT/'M193_MASTER_REFERENCE_AUDIT.md').read_text()
    assert 'PLACEHOLDER' in audit and 'server-authoritative' in audit

def test_m193_visual_budget_matches_contract():
    p=json.loads((ROOT/'data/m137_visual_budget_profiles.json').read_text())
    assert p['mobile']['islands_per_sector']==8
    assert p['web']['islands_per_sector']==8
    assert p['desktop']['islands_per_sector']==8
    assert p['mobile']==p['web']==p['desktop']
