import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_m258():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M258' in d['visual_master_lock']

def test_backup_contract_preserves_master_recovery_boundaries():
 d=load('data/m258_backup_disaster_recovery_contract.json'); assert d['backup']['automated_by_criticality'] is True and d['backup']['encrypted'] is True and d['pitr_restore']['existing_backup_file_is_not_proof_of_recoverability'] is True
 assert d['disaster_recovery']['drills_required'] is True and d['account_economy_recovery']['uncontrolled_direct_database_editor'] is False and d['balance']['final_rpo_rto_values_invented'] is False

def test_recovery_runtime_is_monotonic_operations_only_and_non_mutating():
 s=read('scripts/online/m258_backup_disaster_recovery_runtime.gd'); assert 'if not operations_verified: return false' in s and 'incoming_revision <= revision' in s and '"OPERATIONS"' in s
 for token in ['can_client_create_production_backup','can_client_verify_backup','can_client_select_restore_point','can_client_execute_restore','can_client_execute_pitr','can_client_change_rpo_rto','can_client_mark_drill_successful','can_client_repair_account_economy','can_client_bypass_recovery_audit','can_client_merge_test_and_global_backup_state']: assert f'func {token}' in s
 assert s.count('return false') >= 11

def test_system_status_integrates_recovery_without_world_hud_clutter():
 d=read('scripts/ui/command_deck.gd'); c=read('scripts/ui/m258_backup_disaster_recovery_catalog.gd'); assert 'BACKUP · PITR · DISASTER RECOVERY' in d and 'M258BackupDisasterRecoveryCatalog.overview' in d and 'OPS NICHT VERBUNDEN' in c and 'DRILL AUSSTEHEND' in c
 pages=d.split('var pages :=',1)[1].split('\n',1)[0]; assert 'backup' not in pages and 'recovery' not in pages

def test_bootstrap_admin_and_convergence_advance_recovery_honestly():
 b=read('scripts/core/game_bootstrap.gd'); assert 'M258BackupDisasterRecoveryRuntime.new()' in b and 'BackupDisasterRecoveryReadiness' in b
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['backup_policy_definition','restore_policy_definition','disaster_recovery_plan_definition','recovery_runbook_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['backup_restore_disaster_recovery']; assert row['status']=='PARTIAL' and 'm258_fix' in row and 'production automated backup jobs' in row['remaining']
