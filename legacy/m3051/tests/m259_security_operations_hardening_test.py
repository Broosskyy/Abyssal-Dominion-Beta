import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_m259():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M259' in d['visual_master_lock']

def test_security_contract_preserves_secrets_rbac_and_anti_abuse_boundaries():
 d=load('data/m259_security_operations_contract.json'); assert d['secrets']['local_test_global_separated'] is True and d['secrets']['client_may_receive_secret_material'] is False
 assert d['operational_permissions']['model']=='RBAC_LEAST_PRIVILEGE' and d['operational_permissions']['direct_database_manipulation_by_support'] is False
 assert d['anti_abuse']['server_authoritative_enforcement'] is True and d['anti_abuse']['client_detection_is_not_proof'] is True and d['configuration']['final_risk_thresholds_invented'] is False

def test_security_runtime_is_monotonic_sanitized_and_non_mutating():
 s=read('scripts/online/m259_security_operations_runtime.gd'); assert 'if not security_verified: return false' in s and 'incoming_revision <= revision' in s and 'snapshot.has("secrets")' in s and '"SECURITY_SERVER"' in s
 for token in ['can_client_grant_staff_role','can_client_elevate_permission','can_client_read_secret_material','can_client_rotate_secret','can_client_revoke_secret','can_client_disable_rate_limit','can_client_confirm_abuse_case','can_client_issue_critical_sanction','can_client_bypass_security_audit','can_client_merge_test_global_security_state','can_client_mark_security_service_healthy']: assert f'func {token}' in s
 assert s.count('return false') >= 12

def test_system_status_integrates_security_without_hud_or_menu_sprawl():
 d=read('scripts/ui/command_deck.gd'); c=read('scripts/ui/m259_security_operations_catalog.gd'); assert 'SECURITY · SECRETS · ANTI-ABUSE' in d and 'M259SecurityOperationsCatalog.overview' in d and 'CLIENT-ZUGRIFF GESPERRT' in c and 'RBAC · LEAST PRIVILEGE' in c
 pages=d.split('var pages :=',1)[1].split('\n',1)[0]; assert 'security' not in pages and 'secrets' not in pages

def test_bootstrap_admin_and_convergence_advance_security_honestly():
 b=read('scripts/core/game_bootstrap.gd'); assert 'M259SecurityOperationsRuntime.new()' in b and 'SecurityOperationsReadiness' in b
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['security_policy_definition','rate_limit_policy_definition','operational_permission_definition','secret_rotation_policy_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['security_secrets_anti_abuse']; assert row['status']=='PARTIAL' and 'm259_fix' in row and 'production secret-management provider' in row['remaining']
