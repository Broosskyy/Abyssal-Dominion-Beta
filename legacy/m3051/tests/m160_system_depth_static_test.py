from pathlib import Path
import json
r=Path(__file__).resolve().parents[1]
d=json.loads((r/'data/m160_system_depth.json').read_text())
assert len(d['special_decks'])>=6 and d['normal_decks']['levels']==10
assert len(d['talent_trees'])>=5 and len(d['citadel']['branches'])>=6
assert all(x['levels']==10 for x in d['cannon_upgrade_tracks'])
a=json.loads((r/'data/admin_content_type_registry.json').read_text())['content_types']
for t in ['special_deck','talent_tree','talent_node','citadel_branch','cannon_upgrade_track','buff_effect','guild_building','guild_tower']: assert t in a
old=json.loads((r/'data/m159_items_and_ship_extensions.json').read_text())['ship_extensions']
assert 'extras_deprecated' in old and 'extras' not in old
boot=(r/'scripts/core/game_bootstrap.gd').read_text()
assert 'M160SystemCatalog' in boot and 'M160ProgressionHub' in boot
print('M160 SYSTEM DEPTH STATIC PASS')
