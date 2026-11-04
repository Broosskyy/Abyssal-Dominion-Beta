import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_m257():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M257' in d['visual_master_lock']

def test_contract_has_minimum_version_flags_incident_and_rollback_boundaries():
 d=load('data/m257_release_operations_contract.json'); assert d['release_identity']['test_global_isolation'] is True and d['minimum_version']['server_authoritative'] is True and d['minimum_version']['client_cannot_bypass_required_update'] is True
 assert d['feature_flags']['server_or_signed_config_owned'] is True and d['maintenance_incidents']['no_local_authoritative_progression_when_offline'] is True and d['deployment_rollback']['client_cannot_rollback'] is True
 assert d['balance']['final_rollout_percentages_invented'] is False and d['balance']['final_retry_intervals_invented'] is False

def test_runtime_is_monotonic_fail_closed_and_non_deployment_authority():
 s=read('scripts/online/m257_release_operations_runtime.gd'); assert 'if not server_verified: return false' in s and 'incoming_revision <= revision' in s and 'SERVER_OR_RELEASE_PIPELINE' in s and 'update_required' in s
 for token in ['can_client_set_minimum_version','can_client_bypass_required_update','can_client_override_feature_flag','can_client_promote_build','can_client_deploy','can_client_rollback','can_client_resolve_incident','can_client_mark_release_healthy','can_client_merge_test_and_global_state','can_client_create_authoritative_progression_while_offline']: assert f'func {token}' in s
 assert s.count('return false') >= 11

def test_system_status_ui_reuses_existing_page_without_hud_clutter():
 d=read('scripts/ui/command_deck.gd'); c=read('scripts/ui/m257_release_operations_catalog.gd'); assert 'RELEASE · FEATURE FLAGS · INCIDENTS' in d and 'M257ReleaseOperationsCatalog.overview' in d and 'LOCAL DEVELOPMENT' in c and 'NICHT PRODUKTIONSREIF' in c
 pages=d.split('var pages :=',1)[1].split('\n',1)[0]; assert 'release_operations' not in pages

def test_bootstrap_admin_and_convergence_are_integrated_honestly():
 b=read('scripts/core/game_bootstrap.gd'); assert 'M257ReleaseOperationsRuntime.new()' in b and 'ReleaseOperationsReadiness' in b
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['feature_flag_definition','maintenance_notice_definition','release_channel_definition','operations_runbook_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['release_operations']; assert row['status']=='PARTIAL' and 'real CI/CD promotion pipeline' in row['remaining'] and 'm257_fix' in row
