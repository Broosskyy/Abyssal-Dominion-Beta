import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
release = json.loads((ROOT / "data/release_identity.json").read_text())
assert release["build_number"] >= 185 and release["master_concept"] == "V3.8"

contract = json.loads((ROOT / "data/m185_menu_content_clarity.json").read_text())
assert len(contract["quest_groups"]) == 6
assert "owned_and_required_fragments" in contract["bonusmap_fields"]
assert len(contract["competitive_layers"]) == 3

catalog = (ROOT / "scripts/ui/m185_menu_status_catalog.gd").read_text()
for token in ["static func context", "static func bonusmap", "pity_tokens", "inventory.at_port", "eligibility_level"]:
    assert token in catalog

deck = (ROOT / "scripts/ui/command_deck.gd").read_text()
for token in ["func _status_card", "KERN- & STORYAUFTRAG", "REGION", "TÄGLICH & WÖCHENTLICH", "JÄGER, GILDE & EVENT", "FORTSCHRITTSEBENEN", "AKTIVES LOADOUT"]:
    assert token in deck
assert "M185MenuStatusCatalog.bonusmap" in deck
assert '"guild":' in deck and '"rankings":' in deck
assert "missions.daily_complete()" in deck and "missions.weekly_complete()" in deck

bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text()
assert "M185MenuStatusCatalog.new()" in bootstrap
registry = json.loads((ROOT / "data/admin_content_type_registry.json").read_text())["content_types"]
for content_type in contract["no_code_types"]:
    assert content_type in registry

print("M185 MENU CONTENT CLARITY TEST PASS")

