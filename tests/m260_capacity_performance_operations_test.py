import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_m260():
 d=load('data/release_identity.json'); assert d['milestone'] in ['M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'] and d['client_version'] in ['0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'] and d['build_number'] in [260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301] and d['content_config_version'] in ['M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'] and d['master_concept']=='V3.8' and 'M260' in d['visual_master_lock']

def test_capacity_contract_measures_scale_without_invented_limits():
 d=load('data/m260_capacity_performance_operations_contract.json')
 assert d['capacity_planning']['measured_not_assumed'] is True and d['capacity_planning']['global_event_capacity_requires_test_evidence'] is True
 assert all(x in d['capacity_planning']['dimensions'] for x in ['ccu','players_per_map_instance','combat_load','database_throughput','event_spikes'])
 assert d['resilience_testing']['destructive_tests_uncontrolled_on_global_forbidden'] is True
 assert d['client_performance']['platform_parity_gameplay_world_preserved'] is True and d['client_performance']['client_fps_does_not_drive_server_simulation'] is True
 assert all(v is False for v in d['configuration'].values())

def test_capacity_runtime_is_monotonic_read_only_and_environment_safe():
 s=read('scripts/online/m260_capacity_performance_runtime.gd')
 assert 'if not operations_verified: return false' in s and 'incoming_revision <= revision' in s and '"CAPACITY_OPS"' in s
 assert 'environment not in ["INTERNAL", "TEST", "GLOBAL"]' in s and 'snapshot.has("autoscaling_write")' in s
 for token in ['can_client_start_production_load_test','can_client_start_destructive_global_chaos_test','can_client_change_capacity_limit','can_client_change_autoscaling_threshold','can_client_change_server_tick_rate','can_client_mark_capacity_gate_passed','can_client_fabricate_test_result','can_client_merge_test_global_results','can_client_degrade_gameplay_world_for_platform_capacity']:
  assert f'func {token}' in s
 assert s.count('return false') >= 12

def test_command_deck_and_bootstrap_integrate_capacity_without_hud_sprawl():
 b=read('scripts/core/game_bootstrap.gd'); d=read('scripts/ui/command_deck.gd'); c=read('scripts/ui/m260_capacity_performance_catalog.gd')
 assert 'M260CapacityPerformanceRuntime.new()' in b and 'CapacityPerformanceReadiness' in b
 assert 'CAPACITY · LOAD · SOAK · PERFORMANCE' in d and 'M260CapacityPerformanceCatalog.overview' in d
 assert 'Datengetriebene Render-/VFX-/Wasser-/LOD-/FPS-Profile' in c and 'Destruktive Tests niemals unkontrolliert auf GLOBAL' in c
 pages=d.split('var pages :=',1)[1].split('\n',1)[0]; assert 'capacity' not in pages and 'performance' not in pages

def test_admin_and_convergence_advance_capacity_honestly():
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in ['M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'] and all(x in a['content_types'] for x in ['capacity_plan_definition','load_test_scenario_definition','performance_budget_definition','resilience_test_scenario_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in ['M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301']; row={x['domain']:x for x in m['domains']}['capacity_load_performance_operations']
 assert row['status']=='PARTIAL' and 'm260_fix' in row and 'production distributed load-test harness' in row['remaining'] and 'autoscaling validation and large GLOBAL event capacity drills' in row['remaining']
