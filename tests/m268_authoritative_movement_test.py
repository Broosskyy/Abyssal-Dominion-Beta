from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_and_contract():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M268' in d['visual_master_lock']
 c=load('data/m268_authoritative_movement_contract.json'); assert c['milestone']=='M268' and c['contract']=='authoritative_movement_prediction_reconciliation'; assert all(x in c['authority']['server_owns'] for x in ['accepted_position','movement_revision','movement_command_ack','speed_legality','teleport_legality'])

def test_runtime_tap_prediction_reconciliation_and_fail_closed_authority():
 s=read('scripts/online/m268_authoritative_movement_runtime.gd')
 for token in ['bind_world_replica','M267AuthoritativeWorldTransportRuntime','prepare_tap_to_sail_intent','apply_local_prediction','ingest_server_movement_verdict','ack_command_sequence','movement_revision','correction_kind','invalidate_from_world_resync']:
  assert token in s
 for token in ['can_client_commit_position() -> bool: return false','can_client_commit_velocity() -> bool: return false','can_client_commit_heading() -> bool: return false','can_client_accept_teleport() -> bool: return false','can_client_decide_speed_legality() -> bool: return false','can_client_promote_prediction_to_authority() -> bool: return false','can_client_transfer_test_movement_to_global() -> bool: return false']:
  assert token in s
 assert 'Prediction can improve responsiveness, but never becomes durable/world truth.' in s

def test_bootstrap_command_deck_and_no_new_main_page():
 b=read('scripts/core/game_bootstrap.gd'); c=read('scripts/ui/command_deck.gd')
 assert 'M268AuthoritativeMovementRuntime.new()' in b and 'AuthoritativeMovementReadiness' in b
 assert 'MOVEMENT · PREDICTION · RECONCILIATION' in c and 'M268AuthoritativeMovementCatalog.overview' in c and 'M268AuthoritativeMovementCatalog.authority' in c
 pages=c.split('var pages :=',1)[1].split('\n',1)[0]; assert 'movement_authority' not in pages

def test_admin_no_code_and_convergence():
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['movement_authority_policy_definition','movement_prediction_policy_definition','movement_reconciliation_policy_definition','movement_abuse_guard_policy_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['authoritative_movement_prediction_reconciliation']; assert row['status']=='PARTIAL' and 'm268_fix' in row and 'production authoritative movement simulation' in row['remaining'] and 'native latency/jitter/loss prediction-reconciliation QA' in row['remaining']

def test_m267_world_transport_still_present_as_dependency():
 assert Path(ROOT/'scripts/online/m267_authoritative_world_transport_runtime.gd').exists()
 c=load('data/m268_authoritative_movement_contract.json'); assert c['world_transport_dependency'].startswith('M267')
