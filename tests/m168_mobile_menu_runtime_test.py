from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
def req(v,m):
 if not v: raise AssertionError(m)
idn=json.loads((ROOT/'data/release_identity.json').read_text())
req(idn['build_number']>=168 and idn['master_concept']=='V3.8','release')
contract=json.loads((ROOT/'data/m168_runtime_mobile_menu_audit.json').read_text())
req(len(contract['crafting_station_runtime'])==4,'stations')
req(all(x['max_level']==10 for x in contract['crafting_station_runtime']),'station cap')
combat=(ROOT/'scripts/combat/combat_catalog.gd').read_text()
req('ammo_index_by_id' in combat and 'ammo_ids()' in combat,'runtime ammo helpers')
ars=(ROOT/'scripts/ui/arsenal_panel.gd').read_text()
req('(%d/3)' not in ars and '(%d/6 owned)' not in ars,'obsolete arsenal caps')
req('CombatCatalog.ammo_index_by_id' in ars and 'inventory.max_stock_for(item)' in ars,'arsenal runtime catalog')
hud=(ROOT/'scripts/ui/game_hud.gd').read_text()
req('"iron", "explosive", "chain", "piercing", "ember", "venom", "shatter", "spectral", "gravefire"' not in hud,'fixed ammo match removed')
req('CombatCatalog.ammo_index_by_id(action)' in hud,'picker runtime ammo')
state=(ROOT/'scripts/core/game_state.gd').read_text();req('CombatCatalog.AMMO.size()' not in state and 'CombatCatalog.ammo_count()' in state,'save runtime ammo clamp')
inv=(ROOT/'scripts/progression/player_inventory.gd').read_text()
for token in ['crafting_station_levels','upgrade_crafting_station','_recipe_station_ready','"crafting_station_levels": crafting_station_levels.duplicate(true)']:req(token in inv,token)
reg=json.loads((ROOT/'data/admin_content_type_registry.json').read_text())['content_types']
for k in ['crafting_station_runtime','runtime_ammo_selection_profile','menu_interaction_audit','mobile_hud_profile','runtime_content_guard']:req(k in reg,k)
print('M168 mobile/menu/runtime-depth test PASS')
