from pathlib import Path
import json
r=Path(__file__).resolve().parents[1]
for p in r.rglob('*.json'):
    json.loads(p.read_text(encoding='utf-8'))
d=json.loads((r/'data/m162_system_runtime.json').read_text(encoding='utf-8'))
assert d['milestone']=='M162'
assert d['normal_decks']['max_level']==10 and d['normal_decks']['visible_under_ship'] is True
assert len(d['special_decks'])>=6 and all(x['max_level']==5 for x in d['special_decks'])
assert len(d['talent_nodes'])==60
assert len(d['citadel_branches'])>=6 and all(x['max_level']==10 for x in d['citadel_branches'])
assert len(d['cannon_upgrade_tracks'])==4 and all(x['max_level']==10 for x in d['cannon_upgrade_tracks'])
assert len(d['new_items'])>=8
registry=json.loads((r/'data/admin_content_type_registry.json').read_text(encoding='utf-8'))['content_types']
for t in ['interface_panel','interface_action','tooltip_profile','animation_profile','economy_formula','upgrade_tree','upgrade_node','guild_rank','guild_permission_set','guild_siege_rule','consumable_effect','harpoon_profile']:
    assert t in registry
inv=(r/'scripts/progression/player_inventory.gd').read_text(encoding='utf-8')
for fn in ['upgrade_special_deck','equip_special_deck','spend_talent_point','upgrade_citadel','upgrade_cannon_track','m162_multiplier']:
    assert f'func {fn}' in inv
assert 'special_deck_levels' in inv and 'talent_ranks' in inv and 'cannon_track_levels' in inv
boot=(r/'scripts/core/game_bootstrap.gd').read_text(encoding='utf-8')
assert 'M162SystemCatalog' in boot
ui=(r/'scripts/ui/m160_progression_hub.gd').read_text(encoding='utf-8')
for label in ['SPEZIALDECKS','KANONEN-AUSBAU','TALENTE','KASTELL','GILDE & GILDENINSEL']:
    assert label in ui
rel=json.loads((r/'data/release_identity.json').read_text(encoding='utf-8'))
assert int(rel.get('build_number',0)) >= 162 and str(rel.get('client_version','')).startswith('0.')
ext=json.loads((r/'data/m162_no_code_extensions.json').read_text(encoding='utf-8'))
assert ext['goal']=='MOST_CONTENT_AND_LIVEOPS_WITHOUT_CLIENT_CODE_CHANGES'
print('M162 GAMEPLAY + AUTHORING STATIC PASS')
