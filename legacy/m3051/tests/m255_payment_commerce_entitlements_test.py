import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_m255():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M255' in d['visual_master_lock']

def test_payment_contract_is_server_verified_idempotent_and_fair():
 d=load('data/m255_payment_commerce_contract.json'); assert d['master_contract']['ownership_after_server_verification_only'] is True and d['master_contract']['server_receipt_validation'] is True and d['master_contract']['idempotent_purchase_transaction'] is True
 assert d['offline']=={'fake_purchases':False,'fake_entitlements':False,'fake_receipts':False,'fake_store_prices':False}
 assert d['security']['duplicate_receipt_rejected'] is True and d['security']['replay_protection'] is True and d['balance']['new_final_prices_invented'] is False
 assert d['fairness']['dominant_pvp_power_cash_exclusive'] is False and d['fairness']['relevant_combat_power_must_be_earnable'] is True

def test_runtime_monotonic_and_client_cannot_grant_commerce_value():
 s=read('scripts/online/m255_payment_commerce_runtime.gd'); assert 'if not server_verified: return false' in s and 'incoming_revision < revision' in s and 'result["source"] = "SERVER"' in s
 for token in ['can_client_validate_receipt','can_client_grant_entitlement','can_client_confirm_purchase','can_client_set_store_price','can_client_reuse_purchase_token','can_client_settle_refund','can_client_settle_chargeback','can_client_revoke_entitlement','can_client_transfer_test_entitlement_to_global','can_client_mutate_premium_wallet']: assert f'func {token}' in s
 assert s.count('return false') >= 11 and 'grants_ownership":false' in s

def test_existing_shop_integrates_payment_without_duplicate_top_level_page_or_hud_spam():
 d=read('scripts/ui/command_deck.gd'); c=read('scripts/ui/m255_payment_commerce_catalog.gd'); assert 'PAYMENT · PURCHASES · ENTITLEMENTS' in d and 'M255PaymentCommerceCatalog.overview' in d
 assert 'Keine Fake-Käufe' in c and 'SERVER ONLY' in c
 pages=d.split('var pages :=',1)[1].split('\n',1)[0]; assert pages.count('"shop"')==1

def test_bootstrap_admin_and_convergence_advance_payment_honestly():
 b=read('scripts/core/game_bootstrap.gd'); assert 'M255PaymentCommerceRuntime.new()' in b and 'PaymentCommerceReadiness' in b
 a=load('data/admin_content_type_registry.json'); assert all(x in a['content_types'] for x in ['store_product_definition','store_product_mapping_definition','shop_offer_definition','commerce_bundle_definition','entitlement_policy_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['payments_commerce']; assert row['status']=='PARTIAL' and 'm255_fix' in row and 'payment provider' not in row['remaining'] and 'production receipt verification service' in row['remaining']
