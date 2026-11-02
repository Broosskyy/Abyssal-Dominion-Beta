from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_release_identity_and_contract():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8' and 'M269' in d['visual_master_lock']
 c=load('data/m269_authoritative_combat_contract.json'); assert c['milestone']=='M269' and c['contract']=='authoritative_combat_resolution_fire_command_pipeline'; assert c['genre_ux_references']==['Seafight','Battle of Sea']; assert all(x in c['authority']['server_owns'] for x in ['target_legality','range_legality','reload_cooldown','ammo_consumption','damage','healing','death'])

def test_runtime_target_fire_verdict_and_fail_closed_authority():
 s=read('scripts/online/m269_authoritative_combat_runtime.gd')
 for token in ['bind_world_replica','select_target_preview','prepare_fire_intent','stage_local_fire_feedback','ingest_server_combat_verdict','fire_sequence','combat_revision','authoritative_target_state','invalidate_from_world_resync']:
  assert token in s
 for token in ['can_client_confirm_target_legality() -> bool: return false','can_client_confirm_range() -> bool: return false','can_client_confirm_line_of_fire() -> bool: return false','can_client_confirm_reload_cooldown() -> bool: return false','can_client_consume_ammo() -> bool: return false','can_client_resolve_hit() -> bool: return false','can_client_apply_damage_or_heal() -> bool: return false','can_client_confirm_death() -> bool: return false','can_client_settle_combat_reward() -> bool: return false','can_client_transfer_test_combat_to_global() -> bool: return false']:
  assert token in s
 assert 'confirmed_hit":false' in s

def test_bootstrap_command_deck_and_no_new_main_page():
 b=read('scripts/core/game_bootstrap.gd'); c=read('scripts/ui/command_deck.gd')
 assert 'M269AuthoritativeCombatRuntime.new()' in b and 'AuthoritativeCombatReadiness' in b
 assert 'COMBAT · TARGET · FIRE RESOLUTION' in c and 'M269AuthoritativeCombatCatalog.overview' in c and 'M269AuthoritativeCombatCatalog.authority' in c
 pages=c.split('var pages :=',1)[1].split('\n',1)[0]; assert 'combat_authority' not in pages

def test_admin_no_code_and_convergence():
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['combat_resolution_policy_definition','fire_command_policy_definition','combat_outcome_policy_definition','combat_settlement_policy_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['authoritative_combat_resolution_fire_command_pipeline']; assert row['status']=='PARTIAL' and 'm269_fix' in row and 'production authoritative combat simulation' in row['remaining'] and 'native latency/jitter/loss/concurrency/adversarial combat QA' in row['remaining']

def test_dependency_chain_remains_explicit():
 c=load('data/m269_authoritative_combat_contract.json'); assert c['dependencies']['world_transport'].startswith('M267') and c['dependencies']['movement'].startswith('M268') and c['dependencies']['economy_inventory'].startswith('M266')
 assert Path(ROOT/'scripts/online/m267_authoritative_world_transport_runtime.gd').exists() and Path(ROOT/'scripts/online/m268_authoritative_movement_runtime.gd').exists() and Path(ROOT/'scripts/online/m266_economy_inventory_transaction_runtime.gd').exists()
