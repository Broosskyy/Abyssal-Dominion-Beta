from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def test_m28_event_loop():
 s=(ROOT/'scripts/progression/mission_system.gd').read_text(); assert all(t in s for t in ['EVENT_MILESTONES','EVENT_REWARDS','claim_event','event_claimable','chain_stage'])
def test_fleet_command_superseded_by_panel_routing():
 s=(ROOT/'scripts/ui/game_hud.gd').read_text(); assert 'global_map_open' in s and 'progression.shop_open' in s
def test_event_claim_runtime_retained():
 s=(ROOT/'scripts/progression/mission_system.gd').read_text(); assert 'claim_event' in s
