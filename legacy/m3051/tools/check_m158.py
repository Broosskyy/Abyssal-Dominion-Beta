#!/usr/bin/env python3
from pathlib import Path
import json, sys, re
ROOT=Path(__file__).resolve().parents[1]
errors=[]
# All JSON must parse.
json_count=0
for p in ROOT.rglob('*.json'):
    try: json.loads(p.read_text(encoding='utf-8'))
    except Exception as e: errors.append(f'JSON {p.relative_to(ROOT)}: {e}')
    json_count+=1
# M158 contracts.
def load(name): return json.loads((ROOT/'data'/name).read_text())
legacy=load('m158_legacy_encounter_refresh.json')
cannon=load('m158_cannon_runtime_progression.json')
bonus=load('m158_bonusmap_boss_mechanics.json')
halloween=load('m158_halloween_gameplay.json')
identity=load('release_identity.json')
if len(legacy.get('bands',[]))!=9: errors.append('expected 9 PL6-50 encounter bands')
levels=[]
for b in legacy.get('bands',[]): levels += list(range(int(b['min_level']),int(b['max_level'])+1))
if levels != list(range(6,51)): errors.append('PL6-50 encounter bands must be contiguous')
if len(cannon.get('tiers',[]))!=5: errors.append('expected five cannon runtime tiers')
if set(cannon.get('role_masteries',{})) != {'rapid','balanced','marksman','brawler','siege','sustained','endgame_siege'}: errors.append('seven cannon role masteries required')
if set(bonus.get('maps',{})) != {'silver','gold','abyss','legendary'}: errors.append('four bonusmap boss contracts required')
if [x.get('id') for x in halloween.get('phase_extensions',[])] != [1,2,3,4]: errors.append('Halloween phases 1-4 required')
event=load('event_framework.json')['events']['halloween_abyss_01']
if not any(int(x.get('id',0))==4 for x in event.get('phases',[])): errors.append('phase 4 not merged into event framework')
if identity.get('build_number')!=158 or identity.get('client_version')!='0.158.0': errors.append('release identity not M158')
# Source integration checks.
checks={
 'scripts/gameplay/ship_weapons.gd':['M158CannonRuntime.modifiers','_cannon_upgrade_level'],
 'scripts/gameplay/enemy_ship_ai.gd':['m158_phase_profile','_base_damage'],
 'scripts/world/encounter_director.gd':['M158LegacyEncounterCatalog.phase_profile','m158_loot_profile'],
 'scripts/world/bonusmap_wave_director.gd':['M158BonusMapBossCatalog.row','m158_bonusmap_mechanics'],
 'scripts/ui/command_deck.gd':['M158 BOSS','M158HalloweenCatalog.phase'],
}
for rel,needles in checks.items():
    text=(ROOT/rel).read_text(encoding='utf-8')
    for n in needles:
        if n not in text: errors.append(f'{rel} missing {n}')
# Ensure beginner passive rule remains.
enc=(ROOT/'scripts/world/encounter_director.gd').read_text(encoding='utf-8')
if 'level <= BeginnerRules.LAST_BEGINNER_LEVEL' not in enc: errors.append('beginner neutrality rule missing')
print(f'M158 static check: {json_count} JSON files parsed')
if errors:
    for e in errors: print('FAIL:',e)
    sys.exit(1)
print('M158 static check: PASS')
