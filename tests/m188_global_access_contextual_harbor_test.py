import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
r=json.loads((ROOT/'data/release_identity.json').read_text())
assert int(r['build_number']) >= 188  # M188 global-access boundary must survive later milestones
c=json.loads((ROOT/'data/m188_global_access_contextual_harbor.json').read_text())
assert c['routing']['shipyard_opens_global_shipyard_panel'] is True
assert c['routing']['shipyard_never_aliases_harbor_page'] is True
assert c['routing']['normal_target_cycle_preserved_at_sea'] is True
assert c['quests']['normal_global'] is True
assert c['quests']['harbor_special_opt_in_only'] is True
pi=(ROOT/'scripts/gameplay/player_input.gd').read_text()
ship=pi[pi.index('\t\t"shipyard":'):pi.index('\t\t"arsenal":')]
assert 'ShipyardPanel.new()' in ship
assert 'show_page("harbor")' not in ship
target=pi[pi.index('\t\t"target":'):pi.index('\t\t"map", "minimap"')]
assert 'ship.has_meta("nearby_port")' in target
assert 'use_port_interaction()' in target
assert 'hud.open_menu("harbor")' in target
assert 'targeting.cycle_target()' in target
hud=(ROOT/'scripts/ui/game_hud.gd').read_text()
assert '"HARBOR SHIPYARD"' not in hud
assert '"SCHIFFSWERFT"' in hud
deck=(ROOT/'scripts/ui/command_deck.gd').read_text()
assert 'Ausrüstung und Loadouts sind global erreichbar' in deck
assert 'Ausrüstungszentrum öffnen' in deck
print('M188 GLOBAL ACCESS CONTEXTUAL HARBOR TEST PASS')
