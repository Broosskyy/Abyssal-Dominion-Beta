import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_m252():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.252.0','0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M252' in d['visual_master_lock']

def test_contract_fail_closed_and_environment_isolated():
 d=load('data/m252_online_readiness_contract.json'); assert d['master_contract']['local_simulation_is_never_live_authority'] is True; assert set(['LOCAL_DEVELOPMENT','INTERNAL','TEST','GLOBAL'])<=set(d['master_contract']['environment_profiles']); assert d['client_readiness']['fail_closed_nonlocal_transport'] is True and d['client_readiness']['no_fake_connected_state'] is True; assert d['balance']['new_final_gameplay_values_invented'] is False

def test_gateway_and_locator_capability_matrix():
 a=read('scripts/online/auth_gateway.gd'); r=read('scripts/online/repository_gateway.gd'); t=read('scripts/online/transport_gateway.gd'); l=read('scripts/online/service_locator.gd')
 assert 'provider_verification' in a and 'revision_guard' in r and 'content_handshake' in t and 'environment_isolated' in a+r+t
 assert 'var auth:AuthGateway' in l and 'var repository:RepositoryGateway' in l and 'auth.capabilities()' in l and 'repository.capabilities()' in l and 'transport.capabilities()' in l

def test_online_readiness_runtime_is_verified_monotonic_replica():
 s=read('scripts/online/m252_online_readiness_runtime.gd'); assert 'if not server_verified: return false' in s and 'incoming_revision < revision' in s and 'result["source"] = "SERVER"' in s
 for token in ['can_client_assert_connected','can_client_verify_account','can_client_promote_local_save_to_server','can_client_authorize_remote_repository','can_client_generate_server_revision','can_client_override_environment_isolation','can_client_generate_trusted_time','can_client_finalize_resume']: assert f'func {token}' in s
 assert s.count('return false')>=9

def test_command_deck_system_status_without_hud_clutter():
 d=read('scripts/ui/command_deck.gd'); h=read('scripts/ui/nautical_hud.gd'); c=read('scripts/ui/m252_online_readiness_catalog.gd')
 assert '"systems"' in d and 'M252OnlineReadinessCatalog.overview' in d and 'PRODUKTIONSLÜCKE' in d and 'AUTHORITY-GRENZE' in c
 assert 'M252OnlineReadiness' not in h

def test_convergence_remains_honest_foundation():
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; rows={x['domain']:x for x in m['domains']}; row=rows['online_auth_persistence_transport']; assert row['status']=='FOUNDATION' and 'm252_fix' in row and 'real auth provider' in row['remaining']
