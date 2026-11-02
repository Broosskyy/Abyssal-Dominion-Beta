import json, pathlib
root=pathlib.Path(__file__).resolve().parents[1]
rel=json.loads((root/'data/release_identity.json').read_text())
assert rel['build_number']>=169 and rel['master_concept']=='V3.8'
data=json.loads((root/'data/m169_mobile_menu_functionality.json').read_text())
assert len(data['mobile_profiles'])>=3 and len(data['interaction_audit'])>=4
h=(root/'scripts/ui/harbor_equipment_panel.gd').read_text()
assert 'HFlowContainer.new()' in h and 'size.x < 700' in h and 'PRÜFUNG' in h
a=(root/'scripts/ui/arsenal_panel.gd').read_text(); assert '52 * NauticalTheme.density_scale()' in a
s=(root/'scripts/ui/shipyard_panel.gd').read_text(); assert 'SCHIFFSWERFT · AUSWAHL & VERGLEICH' in s
b=(root/'scripts/core/game_bootstrap.gd').read_text(); assert 'M169MobileMenuCatalog.new()' in b
reg=json.loads((root/'data/admin_content_type_registry.json').read_text())['content_types']
for k in ['mobile_menu_profile','harbor_tab_profile','interaction_audit_profile','progression_connection']: assert k in reg
print('M169 MOBILE/MENU/FUNCTIONALITY TEST PASS')
