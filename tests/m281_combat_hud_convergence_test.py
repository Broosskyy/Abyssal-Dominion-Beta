from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text()
def load(p): return json.loads(read(p))

def test_m281_release_contract_cleanroom_and_unset_values():
 d=load('data/release_identity.json'); assert d['milestone'] in {'M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['version'] in {'0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8'
 c=load('data/m281_combat_hud_convergence_contract.json'); assert c['contract']=='combat_hud_target_reload_ammo_status_visual_convergence_naval_battle_feedback_polish' and c['genre_ux_references']==['Seafight','Battle of Sea']; assert c['visual_rules']['sea_chart_first'] and c['visual_rules']['primary_attack_bottom_right'] and c['visual_rules']['camera_joystick_bottom_left']; assert 'reload_ring_animation_timing' in c['unset_until_measured']

def test_m281_runtime_fail_closed_over_existing_authorities():
 s=read('scripts/ui/m281_combat_hud_convergence_runtime.gd')
 for t in ['M269AuthoritativeCombatRuntime','M270AuthoritativeCombatStateRuntime','M271TargetingRelationshipAuthorityRuntime','bind_authority_layers','presentation_view','status_effects','boss_phase','local_presentation_intent']: assert t in s
 for t in ['can_client_authorize_target() -> bool: return false','can_client_complete_reload() -> bool: return false','can_client_consume_ammo() -> bool: return false','can_client_confirm_hit_or_damage() -> bool: return false','can_client_apply_status_effect() -> bool: return false','can_client_advance_boss_phase() -> bool: return false','can_client_transfer_test_combat_visuals_to_global() -> bool: return false']: assert t in s

def test_m281_hud_bootstrap_command_deck_admin_convergence():
 b=read('scripts/core/game_bootstrap.gd'); hud=read('scripts/ui/game_hud.gd'); nh=read('scripts/ui/nautical_hud.gd'); deck=read('scripts/ui/command_deck.gd')
 assert 'M281CombatHudConvergenceRuntime.new()' in b and 'CombatHudConvergenceReadiness' in b
 assert 'm281_combat_hud_state' in hud and '_m281_sync_combat_hud_state' in hud
 assert '_draw_m281_combat_convergence' in nh and 'ammo_label' in nh and 'layout.actions.fire' in nh
 assert 'COMBAT HUD · TARGET · RELOAD · AMMO · STATUS' in deck and 'M281CombatHudConvergenceCatalog.reload_ammo()' in deck
 a=load('data/admin_content_type_registry.json'); assert a['milestone'] in {'M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and all(x in a['content_types'] for x in ['combat_hud_visual_policy_definition','target_header_visual_policy_definition','combat_feedback_presentation_policy_definition','boss_admiral_telegraph_visual_policy_definition'])
 m=load('data/m239_master_convergence_matrix.json'); assert m['milestone'] in {'M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}; row={x['domain']:x for x in m['domains']}['combat_hud_target_reload_ammo_status_visual_convergence_naval_battle_feedback_polish']; assert row['status']=='PARTIAL' and 'm281_fix' in row
