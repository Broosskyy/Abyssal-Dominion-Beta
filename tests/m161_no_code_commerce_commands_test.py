from pathlib import Path
import json,re
r=Path(__file__).resolve().parents[1]
# all json must parse
for p in r.rglob('*.json'):
    json.loads(p.read_text(encoding='utf-8'))
commerce=json.loads((r/'data/m161_commerce_catalog.json').read_text())
assert commerce['milestone']=='M161'
assert len(commerce['shops'])>=2 and len(commerce['offers'])>=20
paid=[x for x in commerce['offers'] if x.get('kind')=='real_money']
assert len(paid)>=3
assert all(x.get('provider_product_id') and x.get('entitlement_id') for x in paid)
cmd=json.loads((r/'data/m161_admin_command_catalog.json').read_text())
assert len(cmd['commands'])>=12
assert all(x.get('permission') and x.get('risk') for x in cmd['commands'])
critical=[x for x in cmd['commands'] if x.get('risk')=='critical']
assert critical and all(x.get('server_only') for x in critical)
rbac=json.loads((r/'data/admin_rbac_contract.json').read_text())
for perm in ['commerce.edit','shop.publish','command.execute','payment.refund']:
    assert perm in rbac['permissions']
registry=json.loads((r/'data/admin_content_type_registry.json').read_text())['content_types']
for t in ['shop_offer','currency','commerce_campaign','price_rule','entitlement','bundle','admin_command','role_profile','permission_profile','icon_slot','vfx_profile']:
    assert t in registry
matrix=json.loads((r/'data/m161_no_code_authoring_matrix.json').read_text())
assert len(matrix['families'])>=7 and 'new_behavior_primitive' in matrix['exceptions_requiring_code']
api=json.loads((r/'data/m144_admin_api_contract.json').read_text())['operations']
for op in ['commands.execute','commerce.publish','commerce.rollback','payment.refund','entitlement.adjust']:
    assert op in api and api[op]['server_only'] is True
boot=(r/'scripts/core/game_bootstrap.gd').read_text()
for cls in ['M161CommerceCatalog','M161AdminCommandRegistry','M161NoCodeCapabilityCatalog']:
    assert cls in boot
ui=(r/'scripts/ui/command_deck.gd').read_text()
assert 'purchase_catalog_offer' in ui and 'CHAT + STAFF COMMAND CONSOLE' in ui
inv=(r/'scripts/progression/player_inventory.gd').read_text()
assert 'func purchase_catalog_offer' in inv
rel=json.loads((r/'data/release_identity.json').read_text())
assert int(rel.get('build_number',0)) >= 161 and str(rel.get('client_version','')).startswith('0.')
print('M161 NO-CODE COMMERCE + COMMANDS STATIC PASS')
