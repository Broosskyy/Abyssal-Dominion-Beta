import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_m253():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M253' in d['visual_master_lock']

def test_world_session_contract_server_owned_and_no_fake_values():
 d=load('data/m253_world_session_reconnect_contract.json'); assert d['master_contract']['server_authoritative_world_session'] is True and d['snapshot']['cached_snapshot_is_never_authority'] is True and d['reconnect']['client_may_not_generate_resume_ticket'] is True and d['balance']['new_final_gameplay_values_invented'] is False
 assert set(['session_id','presence','world_revision','map_instance_channel','population','server_tick','resume_ticket','resume_verdict']) <= set(d['authority'])

def test_runtime_verified_monotonic_and_client_cannot_own_session():
 s=read('scripts/online/m253_world_session_runtime.gd'); assert 'if not server_verified: return false' in s and 'incoming_revision < revision' in s and 'incoming_world_revision < world_revision' in s and 'result["source"] = "SERVER"' in s
 for token in ['can_client_create_session_id','can_client_publish_presence','can_client_assign_map_instance','can_client_advance_world_revision','can_client_generate_resume_ticket','can_client_finalize_resume','can_client_set_population','can_client_set_server_tick','can_client_settle_from_stale_snapshot']: assert f'func {token}' in s
 assert s.count('return false') >= 11

def test_presence_and_hud_do_not_fabricate_offline_players_or_network_state():
 r=read('scripts/online/m253_world_session_runtime.gd'); h=read('scripts/ui/nautical_hud.gd'); c=read('scripts/ui/m253_world_session_catalog.gd')
 assert 'if str(snapshot().get("source", "")) != "SERVER": return result' in r
 assert 'str(session_hud.get("source", "")) == "SERVER"' in h and 'M253WorldSessionRuntime' in h
 assert 'keine simulierten Online-Spieler' in c and 'SERVER ONLY' in c

def test_command_deck_world_session_surface_and_bootstrap():
 d=read('scripts/ui/command_deck.gd'); b=read('scripts/core/game_bootstrap.gd')
 assert 'WORLD SESSION · PRESENCE · RECONNECT' in d and 'M253WorldSessionCatalog.overview' in d and 'M253WorldSessionCatalog.reconnect_card' in d
 assert 'var world_session := M253WorldSessionRuntime.new()' in b and 'world_session.name = "WorldSessionReadiness"' in b

def test_convergence_remains_honest_foundation_until_real_backend():
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; rows={x['domain']:x for x in m['domains']}; row=rows['online_auth_persistence_transport']; assert row['status']=='FOUNDATION' and 'm253_fix' in row and 'authoritative world/zone server' in row['remaining']
