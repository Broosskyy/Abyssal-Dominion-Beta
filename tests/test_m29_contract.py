from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding='utf-8')
def test_m29_harbor_and_loadouts():
 inv=read('scripts/progression/player_inventory.gd'); assert 'purchase_harbor_bundle' in inv and 'saved_loadouts' in inv and 'save_loadout' in inv and 'apply_loadout' in inv and 'HARBOR_BUNDLE_PRICE' in inv
def test_loadout_ui_retained_in_modern_panels():
 arsenal=read('scripts/ui/arsenal_panel.gd'); assert '_save_loadout' in arsenal and 'Save Loadout A' in arsenal
def test_m29_campaign_and_arsenal():
 missions=read('scripts/progression/mission_system.gd'); arsenal=read('scripts/ui/arsenal_panel.gd'); assert 'CHAIN_STAGES' in missions and 'chain_description' in missions and 'chain_ratio' in missions and '_save_loadout' in arsenal
