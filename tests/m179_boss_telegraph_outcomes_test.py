import json, pathlib

r = pathlib.Path(__file__).resolve().parents[1]
release = json.loads((r / "data/release_identity.json").read_text())
assert release["build_number"] >= 179
contract = json.loads((r / "data/m179_boss_telegraph_outcomes.json").read_text())
bosses = json.loads((r / "data/m177_bonusmap_boss_runtime.json").read_text())
feedback = json.loads((r / "data/m176_runtime_feedback.json").read_text())
registry = json.loads((r / "data/admin_content_type_registry.json").read_text())
runtime = (r / "scripts/gameplay/bonusmap_boss_mechanics.gd").read_text()

assert set(contract["shapes"]) == {"circle", "line", "boss_ring"}
assert contract["outcomes"]["dodged"]["target_effects_applied"] is False
assert contract["mobile"]["authored_vfx_is_additive_and_cannot_replace_shape_geometry"] is True
assert contract["authority"]["presentation_may_grant_rewards"] is False
shapes = {row["telegraph_shape"] for row in bosses["mechanics"].values()}
assert shapes == {"circle", "line", "boss_ring"}
for row in bosses["mechanics"].values():
    if row["telegraph_shape"] == "line": assert row["line_width"] > 0
for event_id in ["boss_hit", "boss_dodged"]:
    assert event_id in feedback["notification_profiles"]
for token in ["locked_origin", "_distance_to_segment_xz", "BoxMesh", "AuthoredTelegraphAccent", "mechanic_resolved", "target_unavailable", "_exit_tree", "_present_result"]:
    assert token in runtime
for content_type in ["boss_telegraph_shape_profile", "boss_mechanic_outcome_profile"]:
    assert content_type in registry["content_types"]
print("M179 BOSS TELEGRAPH SHAPES/OUTCOMES PASS")
