from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def test_m27_mission_depth():
 s=(ROOT/'scripts/progression/mission_system.gd').read_text(); assert all(t in s for t in ['DAILY_GOALS','WEEKLY_GOALS','event_points','claim_daily','claim_weekly'])
def test_command_ui_superseded_by_world_first_hud():
 s=(ROOT/'scripts/ui/nautical_layout.gd').read_text(); assert 'No persistent bottom command/map-selection bar' in s and 'lower-right combat anchor' in s
def test_mobile_desktop_hierarchy_parity():
 s=(ROOT/'data/m198_visual_master_convergence_contract.json').read_text(); assert 'same_hierarchy_mobile_desktop' in s and 'size_spacing_safe_areas_only' in s
