import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
r=json.loads((ROOT/'data/release_identity.json').read_text())
assert int(r['build_number']) >= 187  # M187 boundary must survive later milestones
c=json.loads((ROOT/'data/m187_harbor_service_hub.json').read_text())
assert c['quests']['normal_quests_require_harbor'] is False
assert c['quests']['harbor_quests_require_harbor'] is True
for x in ['shipyard','equipment','quests','itemshop','progression']: assert x in c['global_anywhere']
assert c['world']['auto_open_global_shop_on_dock'] is False
cat=(ROOT/'scripts/world/m187_harbor_service_catalog.gd').read_text()
assert 'requires_harbor' in cat and 'quest_scope' in cat
port=(ROOT/'scripts/world/port_interaction.gd').read_text()
assert 'progression.toggle_shop()' not in port
roster=(ROOT/'scripts/progression/player_ship_roster.gd').read_text()
segment=roster[roster.index('func equip_owned_ship'):roster.index('func unlock_main_progression_for_map_level')]
assert 'at_port()' not in segment
deck=(ROOT/'scripts/ui/command_deck.gd').read_text()
for t in ['"harbor"','LOKALER HAFEN','SPEZIELLE HAFENAUFTRÄGE','Global erreichbar.']: assert t in deck
assert 'Schiffe im Hafen ausrüsten' not in deck
print('M187 HARBOR SERVICE BOUNDARY TEST PASS')
