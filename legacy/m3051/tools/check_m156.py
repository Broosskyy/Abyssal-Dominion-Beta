from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
# parse all JSON
for p in ROOT.rglob('*.json'):
    json.load(open(p,encoding='utf-8'))
prog=json.load(open(ROOT/'data/m156_pl51_60_progression.json',encoding='utf-8'))
assert list(map(int,prog['levels'].keys()))==list(range(51,61))
assert prog['cap']['pirate_level_cap']==60
regions=json.load(open(ROOT/'data/world_region_registry_v37.json',encoding='utf-8'))['regions']
assert regions[-2]['levels']==[51,55] and regions[-1]['levels']==[56,60]
sectors=json.load(open(ROOT/'data/world_sector_registry.json',encoding='utf-8'))['sectors']
levels=[int(x['pirate_level']) for x in sectors]
assert max(levels)==60 and set(range(1,61)).issubset(set(levels))
by={x['id']:x for x in sectors}; opp={'left':'right','right':'left','up':'down','down':'up'}
for sid,row in by.items():
    for k,other in row.get('neighbors',{}).items():
        assert other in by,(sid,k,other)
        assert by[other].get('neighbors',{}).get(opp[k])==sid,(sid,k,other)
trials=json.load(open(ROOT/'data/m123_pirate_trial_runtime.json',encoding='utf-8'))['trials']
assert all(str(x) in trials for x in [40,45,50,55,60])
post=(ROOT/'scripts/progression/post_beginner_progress.gd').read_text(encoding='utf-8')
for token in ['Pl51To60ProgressionCatalog','w5_elite_chains','dominion_shard_objectives','mini(60,current+1)']:
    assert token in post
voyage=(ROOT/'scripts/progression/voyage_progress.gd').read_text(encoding='utf-8')
for token in ['advanced_map_level=51','advanced_map_level=56','claim_post_beginner_trial60','BeginnerRules.ELITE_MAP_LEVEL, 60']:
    assert token in voyage
harbor=(ROOT/'scripts/ui/harbor_equipment_panel.gd').read_text(encoding='utf-8')
assert '_claim_runtime_trial' in harbor and '[40,45,50,55,60]' in harbor
world=(ROOT/'scripts/world/world_map_system.gd').read_text(encoding='utf-8')
assert 'Pl51To60ProgressionCatalog.level(level)' in world and '<=60' in world
enc=(ROOT/'scripts/world/encounter_director.gd').read_text(encoding='utf-8')
assert 'record_w5_elite_chain' in enc and 'record_dominion_shards' in enc
validator=(ROOT/'scripts/world/world_region_registry.gd').read_text(encoding='utf-8')
assert 'must_end_at_60' in validator
print('M156_STATIC_CHECK_PASS')
