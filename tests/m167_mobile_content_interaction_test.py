from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[1]
def req(x,m):
 if not x: raise AssertionError(m)
idn=json.loads((ROOT/'data/release_identity.json').read_text())
req(idn['build_number']>=167 and idn['master_concept']=='V3.8','release identity')
ui=json.loads((ROOT/'data/m167_mobile_interaction_contract.json').read_text())
req(set(ui['profiles'])=={'compact_phone','phone','tablet_desktop'},'mobile profiles')
req(len(ui['interaction_contracts'])>=7,'interaction contracts')
req(any(x['id']=='commerce.purchase' and x.get('authority')=='server_payment_only' for x in ui['interaction_contracts']),'payment authority')
src=json.loads((ROOT/'data/m167_source_binding_station_progression.json').read_text())
req(len(src['binding_rules'])>=6 and len(src['station_progression'])==4,'source/station depth')
reg=json.loads((ROOT/'data/admin_content_type_registry.json').read_text())['content_types']
for k in ['event_source_binding','admiral_source_binding','bonusmap_source_binding','crafting_station_progression','mobile_ui_profile','interaction_contract','menu_navigation_profile','qa_device_profile']: req(k in reg,k)
hub=(ROOT/'scripts/ui/m160_progression_hub.gd').read_text()
req('M167UxContentCatalog' in hub and 'touch_target' in hub and 'prefer_short_labels' in hub,'responsive hub wiring')
boot=(ROOT/'scripts/core/game_bootstrap.gd').read_text(); req('M167UxContentCatalog.new()' in boot,'catalog bootstrap')
print('M167 mobile/content interaction test PASS')
