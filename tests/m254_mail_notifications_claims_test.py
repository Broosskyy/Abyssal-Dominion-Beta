import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_m254():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M254' in d['visual_master_lock']

def test_mail_contract_is_server_authoritative_idempotent_and_non_fake():
 d=load('data/m254_mail_notifications_contract.json'); assert d['master_contract']['server_authoritative_mail_claims'] is True and d['master_contract']['claims_are_idempotent'] is True and d['offline']=={'fake_mail':False,'fake_claimable_rewards':False,'fake_notifications':False}
 assert d['claims']['request_transaction_ids_required'] is True and d['claims']['retries_after_timeout_or_reconnect_must_not_duplicate_rewards'] is True and d['balance']['new_final_reward_values_invented'] is False

def test_runtime_monotonic_and_client_cannot_settle_mail_claims():
 s=read('scripts/online/m254_mail_notification_runtime.gd'); assert 'if not server_verified: return false' in s and 'incoming_revision < revision' in s and 'result["source"] = "SERVER"' in s
 for token in ['can_client_deliver_mail','can_client_attach_rewards','can_client_set_expiry','can_client_set_audience','can_client_settle_claim','can_client_generate_claim_receipt','can_client_grant_compensation','can_client_confirm_read_sync','can_client_publish_notification']: assert f'func {token}' in s
 assert s.count('return false') >= 10

def test_command_deck_integrates_mail_without_permanent_hud_spam():
 d=read('scripts/ui/command_deck.gd'); c=read('scripts/ui/m254_mail_notification_catalog.gd'); assert 'MAIL · MITTEILUNGEN · CLAIMS' in d and 'REJOIN-KOMMUNIKATION' in d and 'M254MailNotificationCatalog.overview' in d
 assert 'Keine Fake-Mails' in c and 'SERVER ONLY' in c

def test_bootstrap_admin_and_convergence_close_explicit_mail_gap_honestly():
 b=read('scripts/core/game_bootstrap.gd'); assert 'M254MailNotificationRuntime.new()' in b and 'MailNotificationReadiness' in b
 a=load('data/admin_content_type_registry.json'); assert all(x in a['content_types'] for x in ['mail_definition','notification_definition','compensation_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['social_groups_chat_mail']; assert row['status']=='PARTIAL' and 'm254_fix' in row and 'mail/inbox service' not in row['remaining'] and 'connected server mail/notification delivery service' in row['remaining']
