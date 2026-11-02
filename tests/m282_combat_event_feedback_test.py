from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_m282_release_contract_cleanroom_and_unset_values():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['version'] in {'0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8'
 c=load('data/m282_combat_event_feedback_contract.json'); assert c['contract']=='combat_event_feed_damage_heal_number_coalescing_impact_vfx_hit_confirmation_polish' and c['genre_ux_references']==['Seafight','Battle of Sea']; assert c['visual_rules']['sea_chart_first'] and c['visual_rules']['coalesce_repetitive_standard_hits'] and c['visual_rules']['primary_attack_bottom_right_unobstructed'] and 'coalescing_window' in c['unset_until_measured']

def test_m282_runtime_ordering_coalescing_and_fail_closed_authority():
 s=read('scripts/ui/m282_combat_event_feedback_runtime.gd')
 for t in ['M269AuthoritativeCombatRuntime','M270AuthoritativeCombatStateRuntime','M281CombatHudConvergenceRuntime','ingest_server_feedback_event','seen_event_ids','event_sequence','_coalesce','sync_latest_server_outcome','impact_vfx_hook','presentation_view']: assert t in s
 for t in ['can_client_create_confirmed_damage_number() -> bool: return false','can_client_apply_damage_or_heal() -> bool: return false','can_client_confirm_critical_or_block() -> bool: return false','can_client_confirm_projectile_impact() -> bool: return false','can_client_advance_feedback_revision() -> bool: return false','can_client_transfer_test_feedback_to_global() -> bool: return false']: assert t in s

def test_m282_hud_bootstrap_command_deck_admin_convergence():
 b=read('scripts/core/game_bootstrap.gd'); hud=read('scripts/ui/game_hud.gd'); nh=read('scripts/ui/nautical_hud.gd'); deck=read('scripts/ui/command_deck.gd')
 assert 'M282CombatEventFeedbackRuntime.new()' in b and 'CombatEventFeedbackReadiness' in b
 assert 'm282_combat_feedback_state' in hud and '_m282_sync_combat_feedback_state' in hud
 assert '_draw_m282_combat_event_feedback' in nh and 'event_count' in nh and 'layout.target_info' in nh
 assert 'COMBAT FEEDBACK · DAMAGE / HEAL · IMPACT VFX' in deck and 'M282CombatEventFeedbackCatalog.coalescing()' in deck
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['combat_event_feedback_policy_definition','damage_heal_number_presentation_policy_definition','combat_impact_vfx_policy_definition','combat_feedback_density_policy_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['combat_event_feed_damage_heal_number_coalescing_impact_vfx_hit_confirmation_polish']; assert row['status']=='PARTIAL' and 'm282_fix' in row
