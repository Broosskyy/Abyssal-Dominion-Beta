from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_m280_release_contract_and_cleanroom():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['version'] in {'0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8'
 c=load('data/m280_reward_visual_integration_contract.json'); assert c['contract']=='reward_presentation_visual_integration_combat_hud_loot_feedback_boss_reward_reveal_polish' and c['genre_ux_references']==['Seafight','Battle of Sea']; assert c['visual_rules']['sea_chart_first'] and c['visual_rules']['keep_center_readable']

def test_m280_runtime_is_visual_only_and_fail_closed():
 s=read('scripts/ui/m280_reward_visual_integration_runtime.gd')
 for t in ['bind_reward_presentation','ingest_server_visual_event','presentation_view','local_visual_intent','visual_revision','icon_asset_id','inbox_badge_count','claim_state','invalidate_from_world_resync']: assert t in s
 for t in ['can_client_create_reward_visual_truth() -> bool: return false','can_client_override_reward_icon_or_rarity() -> bool: return false','can_client_confirm_reward_delivery() -> bool: return false','can_client_transfer_test_visual_to_global() -> bool: return false']: assert t in s
 assert 'vr <= visual_revision' in s and '"creates_value":false' in s and '"settles_reward":false' in s

def test_m280_hud_bootstrap_deck_admin_and_convergence():
 b=read('scripts/core/game_bootstrap.gd'); hud=read('scripts/ui/game_hud.gd'); nh=read('scripts/ui/nautical_hud.gd'); deck=read('scripts/ui/command_deck.gd')
 assert 'M280RewardVisualIntegrationRuntime.new()' in b and 'RewardVisualIntegrationReadiness' in b
 assert 'm280_reward_visual_state' in hud and '_draw_m280_reward_visual' in nh and 'icon_asset_id' in nh
 assert 'REWARD VISUALS · HUD · BOSS REVEAL' in deck and 'M280RewardVisualIntegrationCatalog.boss_admiral()' in deck
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['reward_visual_layout_policy_definition','reward_reveal_presentation_policy_definition','reward_icon_binding_policy_definition','reward_vfx_motion_policy_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['reward_presentation_visual_integration_combat_hud_loot_feedback_boss_reward_reveal_polish']; assert row['status']=='PARTIAL' and 'm280_fix' in row
