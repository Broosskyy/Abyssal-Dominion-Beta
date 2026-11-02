import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_m261():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M261' in d['visual_master_lock']

def test_crash_health_contract_privacy_device_network_and_matrix_are_explicit():
 d=load('data/m261_crash_client_health_qa_contract.json')
 assert d['crash_diagnostics']['sensitive_content_filtered'] is True and d['crash_diagnostics']['raw_secrets_tokens_receipts_forbidden'] is True
 assert d['client_health']['gameplay_tick_independent_from_client_fps'] is True and d['client_health']['real_mobile_device_qa_required'] is True
 assert all(x in d['network_qa']['profiles'] for x in ['jitter','packet_loss','variable_latency','disconnect_reconnect','background_resume'])
 assert d['qa_matrix']['single_developer_device_is_not_release_evidence'] is True and d['qa_matrix']['critical_release_requires_defined_minimum_coverage'] is True
 assert all(v is False for v in d['configuration'].values())

def test_runtime_is_monotonic_sanitized_and_qa_authority_stays_off_client():
 s=read('scripts/online/m261_crash_client_health_runtime.gd')
 assert 'if not operations_verified: return false' in s and 'incoming_revision <= revision' in s and '"QA_OPS"' in s
 assert 'FORBIDDEN_DIAGNOSTIC_KEYS' in s and 'delivery_state":"NOT_SENT"' in s and 'CLIENT_DIAGNOSTIC_INTENT' in s
 for token in ['can_client_mark_crash_uploaded','can_client_mark_qa_gate_passed','can_client_fabricate_device_result','can_client_close_crash_incident','can_client_override_session_revalidation','can_client_attach_secret_to_diagnostics','can_client_merge_test_global_results','can_client_change_gameplay_tick_from_fps']:
  assert f'func {token}' in s

def test_command_deck_and_bootstrap_integrate_client_health_without_hud_sprawl():
 b=read('scripts/core/game_bootstrap.gd'); d=read('scripts/ui/command_deck.gd'); c=read('scripts/ui/m261_crash_client_health_catalog.gd')
 assert 'M261CrashClientHealthRuntime.new()' in b and 'CrashClientHealthReadiness' in b
 assert 'CRASH · CLIENT HEALTH · QA MATRIX' in d and 'M261CrashClientHealthCatalog.overview' in d
 assert 'Secrets, Tokens und Receipts' in c and 'Ein Entwicklergerät reicht nicht als Releasebeleg' in c
 pages=d.split('var pages :=',1)[1].split('\n',1)[0]; assert 'crash' not in pages and 'qa_matrix' not in pages

def test_admin_and_convergence_advance_m261_honestly():
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['crash_diagnostic_policy_definition','qa_matrix_definition','network_qa_profile_definition','client_health_budget_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['crash_client_health_device_network_qa']
 assert row['status']=='PARTIAL' and 'm261_fix' in row and 'production crash-reporting provider integration' in row['remaining'] and 'background/resume/reconnect native QA' in row['remaining']
