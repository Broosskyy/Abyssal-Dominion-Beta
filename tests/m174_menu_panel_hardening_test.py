import json, pathlib
r=pathlib.Path(__file__).resolve().parents[1]
rel=json.loads((r/'data/release_identity.json').read_text())
assert rel['build_number']>=174 and rel['master_concept']=='V3.8'
inv=(r/'scripts/progression/player_inventory.gd').read_text(); cmd=(r/'scripts/ui/command_deck.gd').read_text(); sy=(r/'scripts/ui/shipyard_panel.gd').read_text(); boot=(r/'scripts/core/game_bootstrap.gd').read_text()
for token in ['catalog_offer_status','harbor_bundle_status','harbor_repair_status']: assert token in inv
assert '_requirement_button' in cmd and 'catalog_offer_status(row)' in cmd
assert 'AUSGEWÄHLT' in sy and '_refresh_selector_labels' in sy
assert 'M174MenuPanelCatalog.new()' in boot
json.loads((r/'data/m174_menu_panel_hardening.json').read_text())
print('M174 MENU/PANEL HARDENING PASS')
