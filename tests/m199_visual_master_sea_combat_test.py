import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def test_m199_release_contract():
 c=json.loads((ROOT/'data/m199_visual_master_sea_combat_contract.json').read_text()); r=json.loads((ROOT/'data/release_identity.json').read_text()); assert c['milestone']=='M199' and r['build_number']>=199; assert c['world_visual_parity']['only_allowed_platform_difference'].startswith('interface size')
def test_world_visual_budget_parity():
 d=json.loads((ROOT/'data/m63_world_visual_budgets.json').read_text())['tiers']; assert d['low']==d['balanced']==d['high']; assert d['high']['water_subdivisions']==64 and d['high']['shoreline_segments']==36
def test_feedback_parity_except_scale():
 d=json.loads((ROOT/'data/m175_feedback_presentation.json').read_text())['damage_number_profiles']; keys=['max_entries','merge_window','crowd_merge_window','crowd_threshold','life']; assert all(d['compact_phone'][k]==d['tablet_desktop'][k] for k in keys); assert d['compact_phone']['base_scale']!=0
def test_visual_master_water_coast_target_tokens():
 water=(ROOT/'scripts/visual/water_surface.gd').read_text(); shore=(ROOT/'scripts/visual/shoreline_foam.gd').read_text(); target=(ROOT/'scripts/combat/targeting_system.gd').read_text(); hud=(ROOT/'scripts/ui/game_hud.gd').read_text(); assert 'micro_contrast' in water and 'crest_strength' in water and 'NORMAL_MAP_DEPTH = 0.22' in water; assert 'M199InnerShoreBreak' in shore; assert 'm199_selected_target' in target; assert 'selected_read' in hud
