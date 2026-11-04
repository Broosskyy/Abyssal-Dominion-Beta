import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_m256():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M256' in d['visual_master_lock']

def test_telemetry_contract_privacy_versioning_and_isolation():
 d=load('data/m256_telemetry_observability_contract.json'); assert d['event_architecture']['stable_event_names'] is True and d['event_architecture']['schema_versioned'] is True and d['event_architecture']['analytics_is_not_gameplay_authority'] is True
 assert 'password' in d['privacy']['forbidden_payload_classes'] and 'raw_store_receipt' in d['privacy']['forbidden_payload_classes'] and d['environment_isolation']['test_telemetry_never_counts_as_global_revenue_or_economy'] is True
 assert d['balance']['new_final_thresholds_invented'] is False and d['balance']['new_final_alert_thresholds_invented'] is False

def test_runtime_is_monotonic_sanitized_and_non_authoritative():
 s=read('scripts/online/m256_telemetry_observability_runtime.gd'); assert 'if not server_verified: return false' in s and 'incoming_revision < revision' in s and 'LOCAL_DIAGNOSTIC_ONLY' in s and 'FORBIDDEN_KEYS' in s and 'MAX_LOCAL_DIAGNOSTIC_EVENTS := 64' in s
 for token in ['can_client_publish_production_telemetry','can_client_define_retention_policy','can_client_define_alert_thresholds','can_client_mark_service_healthy','can_client_confirm_fraud_or_cheat','can_client_grant_reward_from_analytics','can_client_mutate_balance_from_analytics','can_client_count_test_as_global','can_client_log_sensitive_secrets']: assert f'func {token}' in s
 assert s.count('return false') >= 10

def test_systems_ui_integrates_observability_without_new_top_level_clutter():
 d=read('scripts/ui/command_deck.gd'); c=read('scripts/ui/m256_telemetry_observability_catalog.gd'); assert 'TELEMETRIE · ANALYTICS · OBSERVABILITY' in d and 'M256TelemetryObservabilityCatalog.overview' in d and 'PIPELINE NICHT VERBUNDEN' in c and 'Keine Fake-KPIs' in c
 pages=d.split('var pages :=',1)[1].split('\n',1)[0]; assert '"telemetry"' not in pages

def test_bootstrap_admin_and_convergence_advance_telemetry_honestly():
 b=read('scripts/core/game_bootstrap.gd'); assert 'M256TelemetryObservabilityRuntime.new()' in b and 'TelemetryObservabilityReadiness' in b
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['telemetry_event_definition','analytics_metric_definition','operations_alert_definition','retention_policy_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['telemetry_observability']; assert row['status']=='PARTIAL' and 'm256_fix' in row and 'production event ingestion pipeline' in row['remaining']
