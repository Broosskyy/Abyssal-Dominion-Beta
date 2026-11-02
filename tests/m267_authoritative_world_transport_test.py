from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_and_contract():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.267.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M267' in d['visual_master_lock']
 c=load('data/m267_authoritative_world_transport_contract.json'); assert c['milestone']=='M267' and c['master_concept']=='V3.8' and c['contract']=='authoritative_world_transport_snapshot_protocol'; assert all(x in c['authority']['server_owns'] for x in ['world_baseline','world_delta','network_entity_identity','server_tick','snapshot_revision','sequence'])

def test_runtime_fail_closed_authority_and_ordering():
 s=read('scripts/online/m267_authoritative_world_transport_runtime.gd')
 for token in ['ingest_full_snapshot','ingest_delta','network_entity_id','spawn_generation','baseline_mismatch','sequence_gap','incoming_sequence != last_sequence + 1','prepare_join_intent','prepare_resync_intent','prepare_transfer_intent']:
  assert token in s
 for token in ['can_client_publish_full_snapshot() -> bool: return false','can_client_publish_delta() -> bool: return false','can_client_allocate_network_entity_id() -> bool: return false','can_client_advance_server_tick() -> bool: return false','can_client_authorize_spawn_despawn() -> bool: return false','can_client_confirm_zone_transfer() -> bool: return false','can_client_transfer_test_world_to_global() -> bool: return false']:
  assert token in s
 assert 'incoming_environment not in ["INTERNAL", "TEST", "GLOBAL"]' in s

def test_bootstrap_command_deck_and_no_new_main_page():
 b=read('scripts/core/game_bootstrap.gd'); c=read('scripts/ui/command_deck.gd')
 assert 'M267AuthoritativeWorldTransportRuntime.new()' in b and 'AuthoritativeWorldTransportReadiness' in b
 assert 'WORLD TRANSPORT · SNAPSHOTS · DELTAS' in c and 'M267AuthoritativeWorldTransportCatalog.overview' in c and 'M267AuthoritativeWorldTransportCatalog.authority' in c
 pages=c.split('var pages :=',1)[1].split('\n',1)[0]; assert 'world_transport' not in pages

def test_admin_no_code_and_convergence():
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['world_snapshot_policy_definition','world_delta_policy_definition','network_entity_identity_policy_definition','world_transfer_resync_policy_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['authoritative_world_transport_snapshot_protocol']; assert row['status']=='PARTIAL' and 'm267_fix' in row and 'production realtime transport backend' in row['remaining'] and 'native multiplayer latency/jitter/packet-loss/load/concurrency QA' in row['remaining']
