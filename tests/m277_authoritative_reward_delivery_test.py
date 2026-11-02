from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_m277_release_and_contract():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8'
 c=load('data/m277_authoritative_reward_delivery_contract.json'); assert c['contract']=='authoritative_reward_receipt_claim_delivery_mail_fallback_post_settlement_recovery_audit'; assert c['genre_ux_references']==['Seafight','Battle of Sea']; assert all(x in c['authority']['server_owns'] for x in ['reward_receipt_id','transaction_id','idempotency_key','beneficiary_id','delivery_result','mail_fallback_authorization','recovery_state','audit_evidence'])

def test_m277_runtime_fail_closed_receipt_delivery_and_recovery():
 s=read('scripts/online/m277_authoritative_reward_delivery_runtime.gd')
 for t in ['bind_roll_integrity','ingest_server_delivery_snapshot','ingest_server_delivery_event','receipt_revision','delivery_revision','audit_revision','settlement_sequence','receipt_state','claim_state','delivery_state','recovery_state','audit_state','REQUIRED_RECEIPT_IDENTITY','prepare_claim_intent','invalidate_from_world_resync']: assert t in s
 for t in ['can_client_generate_reward_receipt() -> bool: return false','can_client_attach_reward_value() -> bool: return false','can_client_mark_claim_delivered() -> bool: return false','can_client_force_mail_fallback() -> bool: return false','can_client_recover_settled_reward() -> bool: return false','can_client_append_authoritative_audit() -> bool: return false','can_client_change_beneficiary() -> bool: return false','can_client_reopen_settled_receipt() -> bool: return false','can_client_authorize_settlement() -> bool: return false','can_client_transfer_test_receipt_to_global() -> bool: return false']: assert t in s
 assert 'rcr <= receipt_revision' in s and '"creates_value":false' in s and '"settles_reward":false' in s

def test_m277_bootstrap_deck_admin_dependencies():
 b=read('scripts/core/game_bootstrap.gd'); deck=read('scripts/ui/command_deck.gd'); assert 'M277AuthoritativeRewardDeliveryRuntime.new()' in b and 'AuthoritativeRewardDeliveryReadiness' in b; assert 'REWARD RECEIPT · CLAIM DELIVERY · MAIL FALLBACK · RECOVERY' in deck and 'M277AuthoritativeRewardDeliveryCatalog.mail_fallback()' in deck
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['reward_receipt_policy_definition','reward_claim_delivery_policy_definition','reward_mail_fallback_policy_definition','reward_recovery_audit_policy_definition'])
 c=load('data/m277_authoritative_reward_delivery_contract.json'); assert c['dependencies']['roll_integrity'].startswith('M276') and c['dependencies']['distribution'].startswith('M275') and c['dependencies']['mail'].startswith('M254') and c['dependencies']['settlement'].startswith('M266')

def test_m277_convergence_and_unset_tuning():
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['authoritative_reward_receipt_claim_delivery_mail_fallback_post_settlement_recovery_audit']; assert row['status']=='PARTIAL' and 'm277_fix' in row and any(x.startswith('production durable reward-receipt') for x in row['remaining'])
 c=load('data/m277_authoritative_reward_delivery_contract.json'); assert all(x in c['unset_until_measured'] for x in ['claim_expiry','delivery_retry_count','mail_fallback_delay','recovery_timeout','reward_values'])
 assert c['delivery_rules']['durable_value_requires_m266_commit'] is True and c['delivery_rules']['mail_fallback_uses_m254_server_channel'] is True
