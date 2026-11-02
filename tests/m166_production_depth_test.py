import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def load(path): return json.loads((ROOT/path).read_text(encoding='utf-8'))

def require(cond,msg):
    if not cond: raise AssertionError(msg)

def main():
    identity=load('data/release_identity.json')
    require(identity['build_number']>=166 and identity['master_concept']=='V3.8','release identity')
    data=load('data/m166_production_depth_sources_effects.json')
    effects={r['id']:r for r in data['effect_runtime']}
    for key in ['burn','venom','armor_break','spectral_mark','reload_disrupt','chill','structure_break','boss_break','admiral_break']:
        require(key in effects,f'missing effect {key}')
    require(len(data['crafting_recipes'])>=12,'crafting breadth')
    require(len(data['source_graph'])>=20,'source graph breadth')
    registry=load('data/admin_content_type_registry.json')['content_types']
    for key in data['admin_authoring']:
        require(key in registry,f'missing admin type {key}')
    health=(ROOT/'scripts/gameplay/ship_health.gd').read_text(encoding='utf-8')
    require('_active_category_power' in health and 'weapon_reload_debuff_power' in health,'generic effect runtime not wired')
    require('for id in ["burn", "venom"]' not in health,'legacy DOT hardcode remains')
    weapons=(ROOT/'scripts/gameplay/ship_weapons.gd').read_text(encoding='utf-8')
    require('weapon_reload_debuff_until' in weapons,'reload disrupt not wired')
    inv=(ROOT/'scripts/progression/player_inventory.gd').read_text(encoding='utf-8')
    require('_m166_catalog' in inv and 'next.recipe(id)' in inv,'M166 crafting not wired')
    bootstrap=(ROOT/'scripts/core/game_bootstrap.gd').read_text(encoding='utf-8')
    require('M166ProductionDepthCatalog.new()' in bootstrap,'M166 catalog missing from bootstrap')
    print('M166 production depth test PASS')

if __name__=='__main__': main()
