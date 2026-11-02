import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

release = json.loads((ROOT / "data/release_identity.json").read_text())
assert int(release["build_number"]) >= 186
assert release["master_concept"] == "V3.8"

contract = json.loads((ROOT / "data/m186_quest_tracking_navigation.json").read_text())
assert contract["selection"]["maximum_tracked"] == 1
assert contract["selection"]["progress_authority_unchanged"] is True
assert contract["navigation"]["requires_existing_world_node"] is True
for forbidden in ["teleport", "spawn_missing_target", "fake_route"]:
    assert contract["navigation"][forbidden] is False
assert contract["hud"]["mission_lane"] == "tracked_objective_only"
assert contract["hud"]["clear_center"] is True

runtime = (ROOT / "scripts/progression/tracked_quest_runtime.gd").read_text()
for token in [
    "class_name TrackedQuestRuntime",
    "var tracked: Dictionary",
    "func track(",
    "func untrack(",
    "func resolve_target(",
    "func navigate_to_target(",
    "func export_state(",
    "func import_state(",
]:
    assert token in runtime

resolver = (ROOT / "scripts/progression/m186_objective_navigation_catalog.gd").read_text()
for token in [
    "class_name M186ObjectiveNavigationCatalog",
    'if kind == "dock": return ["ports"]',
    'if kind == "loot": return ["loot"]',
    'return ["enemies"]',
    'return ["event_interactables"]',
    'content_ids',
    'content_tags',
    'require_event_participant',
]:
    assert token in resolver
assert "queue_free" not in resolver and "instantiate" not in resolver

state = (ROOT / "scripts/core/game_state.gd").read_text()
assert '"quest_tracking"' in state
assert "TrackedQuestRuntime).export_state()" in state
assert "tracked_quest.import_state" in state

deck = (ROOT / "scripts/ui/command_deck.gd").read_text()
for token in ["func _tracking_controls", "ZIEL VERFOLGEN", "NICHT MEHR VERFOLGEN", "AUF SEEKARTE ANSTEUERN", "KEIN KARTENZIEL"]:
    assert token in deck

hud = (ROOT / "scripts/ui/nautical_hud.gd").read_text()
world_hud = (ROOT / "scripts/ui/game_hud.gd").read_text()
assert "VERFOLGTES ZIEL" in hud
assert "tracked_target" in hud
assert "func _draw_tracked_objective_marker" in world_hud
assert "ZIEL · %dm" in world_hud

player_input = (ROOT / "scripts/gameplay/player_input.gd").read_text()
assert "func set_navigation_world_target" in player_input
assert '"tracked_objective"' in runtime

registry = json.loads((ROOT / "data/admin_content_type_registry.json").read_text())["content_types"]
for content_type in contract["no_code_types"]:
    assert content_type in registry
    assert registry[content_type]["draft_review_publish"] is True

print("M186 QUEST TRACKING NAVIGATION TEST PASS")
