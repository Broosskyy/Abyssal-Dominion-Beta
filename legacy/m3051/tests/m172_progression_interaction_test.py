from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
def main():
    rel=json.loads(read("data/release_identity.json"))
    assert rel["build_number"]>=172 and rel["master_concept"]=="V3.8"
    c=json.loads(read("data/m172_runtime_progression_interaction.json"))
    assert c["master_concept"]=="V3.8" and len(c["authoring_guards"])>=4
    inv=read("scripts/progression/player_inventory.gd")
    assert "func m165_recipe_status" in inv and '"station_locked"' in inv and '"missing_materials"' in inv and '"output_full"' in inv
    hub=read("scripts/ui/m160_progression_hub.gd")
    assert "m165_recipe_status" in hub and "Voraussetzung ·" in hub and "AUSRÜSTUNG & AUSBAU" in hub
    ship=read("scripts/ui/shipyard_panel.gd")
    assert "var seen: Dictionary" in ship and "seen.has(id)" in ship
    harbor=read("scripts/ui/harbor_equipment_panel.gd")
    assert 'silver.config()' in harbor and 'legendary.config()' in harbor and 'abyss_map.entry_cost()' in harbor and 'gold.data()' in harbor
    boot=read("scripts/core/game_bootstrap.gd")
    assert "M172RuntimeProgressionCatalog" in boot
    reg=json.loads(read("data/admin_content_type_registry.json"))
    for k in ["bonusmap_entry_profile","crafting_requirement_profile","shipyard_catalog_profile","interaction_feedback_profile"]: assert k in reg["content_types"]
    print("M172 progression interaction test: PASS")
if __name__=="__main__": main()
