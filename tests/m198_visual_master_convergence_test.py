import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def test_m198_contract_and_release():
 c=json.loads((ROOT/'data/m198_visual_master_convergence_contract.json').read_text()); r=json.loads((ROOT/'data/release_identity.json').read_text()); assert c['milestone']=='M198' and r['build_number']>=198; h=c['visual_master']['hud']; assert h['primary_attack']=='lower_right' and h['persistent_bottom_command_bar'] is False and h['centered_primary_attack'] is False and h['same_hierarchy_mobile_desktop'] is True
def test_full_chart_water_surface():
 s=(ROOT/'scripts/visual/water_surface.gd').read_text(); assert 'plane.size = Vector2(390.0, 390.0)' in s and 'NORMAL_MAP_DEPTH = 0.22' in s and 'METALLIC = 0.0' in s
def test_hud_visual_master_exception_lock():
 s=(ROOT/'scripts/ui/nautical_layout.gd').read_text(); assert 'No persistent bottom command/map-selection bar' in s and 'no centered primary attack button' in s and 'lower-right combat anchor' in s
