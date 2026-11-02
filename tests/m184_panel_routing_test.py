import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
release = json.loads((ROOT / "data/release_identity.json").read_text())
assert release["build_number"] >= 184 and release["master_concept"] == "V3.8"

contract = json.loads((ROOT / "data/m184_panel_routing.json").read_text())
assert contract["modal_input_key"] == "external_panel_open"
assert contract["header_contract"]["touch_target_min"] >= 56
routes = {row["panel"]: row for row in contract["routes"]}
for panel in ["shipyard", "progression_track", "ship_mastery", "harbor_equipment", "progression_hub", "captain_meta"]:
    assert panel in routes

hud = (ROOT / "scripts/ui/game_hud.gd").read_text()
for token in ["routed_panel", "route_panel", "complete_routed_panel", "routed_return", 'set_meta("external_panel_open", true)']:
    assert token in hud

for source in ["player_input.gd", "camera_rig.gd", "ship_weapons.gd"]:
    text = (ROOT / "scripts/gameplay" / source).read_text()
    assert "external_panel_open" in text

for source in ["shipyard_panel.gd", "progression_track_panel.gd", "ship_mastery_panel.gd", "harbor_equipment_panel.gd", "m160_progression_hub.gd", "meta_systems_panel.gd"]:
    text = (ROOT / "scripts/ui" / source).read_text()
    assert "complete_routed_panel" in text

deck = (ROOT / "scripts/ui/command_deck.gd").read_text()
assert "hud.route_panel" in deck and "_open_shipyard" in deck and "_open_mastery" in deck
assert "AUSRÜSTUNG & AUSBAU · M173" not in (ROOT / "scripts/ui/m160_progression_hub.gd").read_text()
assert "AUSWAHL & VERGLEICH · M174" not in (ROOT / "scripts/ui/shipyard_panel.gd").read_text()

registry = json.loads((ROOT / "data/admin_content_type_registry.json").read_text())["content_types"]
for content_type in contract["no_code_types"]:
    assert content_type in registry

print("M184 PANEL ROUTING TEST PASS")

