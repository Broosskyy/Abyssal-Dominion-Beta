from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_m279_release_and_contract():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['version'] in {'0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8'
 c=load('data/m279_authoritative_reward_presentation_contract.json'); assert c['contract']=='authoritative_reward_notification_loot_presentation_claim_ux_state_foundation'; assert c['genre_ux_references']==['Seafight','Battle of Sea']; assert all(x in c['authority']['server_owns'] for x in ['reward_notification_truth','reward_value_and_quantity','rarity_truth','inbox_badge_truth','claim_ux_state','settlement_state'])

def test_m279_runtime_is_presentation_only_and_fail_closed():
 s=read('scripts/ui/m279_authoritative_reward_presentation_runtime.gd')
 for t in ['bind_reward_inbox','ingest_server_presentation_snapshot','ingest_server_presentation_event','presentation_revision','notification_sequence','presentation_state','notification_state','badge_state','claim_ux_state','encounter_reward_state','prepare_dismiss_presentation_intent','prepare_open_claim_surface_intent','invalidate_from_world_resync']: assert t in s
 for t in ['can_client_create_reward_notification() -> bool: return false','can_client_define_reward_value() -> bool: return false','can_client_override_rarity_or_quantity() -> bool: return false','can_client_confirm_claim_success() -> bool: return false','can_client_set_badge_authoritatively() -> bool: return false','can_client_mark_delivery_settled() -> bool: return false','can_client_transfer_test_presentation_to_global() -> bool: return false']: assert t in s
 assert 'pr <= presentation_revision' in s and '"creates_value":false' in s and '"claims_reward":false' in s and '"settles_reward":false' in s

def test_m279_bootstrap_deck_admin_and_dependencies():
 b=read('scripts/core/game_bootstrap.gd'); deck=read('scripts/ui/command_deck.gd'); assert 'M279AuthoritativeRewardPresentationRuntime.new()' in b and 'AuthoritativeRewardPresentationReadiness' in b; assert 'REWARD PRESENTATION · LOOT FEEDBACK · CLAIM UX' in deck and 'M279AuthoritativeRewardPresentationCatalog.boss_admiral()' in deck
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['reward_notification_presentation_policy_definition','reward_loot_feedback_policy_definition','reward_claim_ux_policy_definition','reward_badge_hierarchy_policy_definition'])
 c=load('data/m279_authoritative_reward_presentation_contract.json'); assert c['dependencies']['inbox'].startswith('M278') and c['dependencies']['settlement'].startswith('M266') and c['rules']['visible_reward_never_proves_ownership'] is True and c['rules']['no_new_reward_main_menu'] is True

def test_m279_convergence_and_unset_ux_tuning():
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['authoritative_reward_notification_loot_presentation_claim_ux_state_foundation']; assert row['status']=='PARTIAL' and 'm279_fix' in row and any(x.startswith('production authored reward-presentation') for x in row['remaining'])
 c=load('data/m279_authoritative_reward_presentation_contract.json'); assert all(x in c['unset_until_measured'] for x in ['banner_duration','notification_coalescing_window','reward_reveal_timing','badge_refresh_interval'])
