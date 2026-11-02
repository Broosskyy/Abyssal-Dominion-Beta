import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
release = json.loads((ROOT / "data/release_identity.json").read_text())
assert release["build_number"] >= 183 and release["master_concept"] == "V3.8"

contract = json.loads((ROOT / "data/m183_unified_command_deck.json").read_text())
assert contract["shell"]["touch_target_min"] >= 56
assert contract["shell"]["escape_behavior"] == "back_then_close"
ids = {row["id"] for section in contract["sections"] for row in section["destinations"]}
for required in ["progress", "equipment", "bonusmaps", "quests", "events", "shop", "guild", "rankings", "log", "help", "admin"]:
    assert required in ids

deck = (ROOT / "scripts/ui/command_deck.gd").read_text()
for token in ["page_history", "available_pages", "navigate(page", "go_back", "_page_context", "CommandDeckDestinationPicker"]:
    assert token in deck
assert 'if id == "admin"' in deck and "admin.enabled" in deck
assert "InputDeviceProfile.touch_like" in deck
assert ("56.0" in deck or "M202MenuInteractionPolicy.touch_height" in deck)
assert ("980.0" in deck or "M202MenuInteractionPolicy.panel_width" in deck)

bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text()
assert "M183CommandDeckCatalog.new()" in bootstrap
registry = json.loads((ROOT / "data/admin_content_type_registry.json").read_text())["content_types"]
for content_type in contract["no_code_types"]:
    assert content_type in registry

print("M183 UNIFIED COMMAND DECK TEST PASS")

