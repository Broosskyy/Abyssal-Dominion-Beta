from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
def main():
    rel=json.loads(read("data/release_identity.json"))
    assert rel["build_number"]>=173 and rel["master_concept"]=="V3.8"
    cfg=json.loads(read("data/m173_menu_progression_interaction.json"))
    assert cfg["master_concept"]=="V3.8" and len(cfg["authoring_guards"])>=4
    inv=read("scripts/progression/player_inventory.gd")
    for fn in ["special_deck_upgrade_status","talent_spend_status","citadel_upgrade_status","cannon_track_upgrade_status"]: assert ("func "+fn) in inv
    assert 'talent_points_unspent<point_cost' in inv and 'missing_prerequisite' in inv and 'missing_material' in inv
    hub=read("scripts/ui/m160_progression_hub.gd")
    assert "AUSRÜSTUNG & AUSBAU" in hub and 'label="● "+label' in hub and "_requirement_action" in hub
    hud=read("scripts/ui/game_hud.gd")
    assert 'row_indices' in hud and 'first_index' in hud and 'guild_island_focus_index' in hud
    draw=read("scripts/ui/nautical_hud.gd")
    assert 'visible_indices' in draw and 'absolute_index' in draw
    boot=read("scripts/core/game_bootstrap.gd")
    assert "M173MenuProgressionCatalog" in boot
    reg=json.loads(read("data/admin_content_type_registry.json"))
    for k in ["progression_panel_profile","upgrade_requirement_feedback_profile","guild_detail_navigation_profile","progression_selection_profile"]: assert k in reg["content_types"]
    print("M173 menu/progression interaction test: PASS")
if __name__=="__main__": main()
