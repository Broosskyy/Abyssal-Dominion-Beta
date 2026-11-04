import json, pathlib

r = pathlib.Path(__file__).resolve().parents[1]
release = json.loads((r / "data/release_identity.json").read_text())
assert release["build_number"] >= 178
contract = json.loads((r / "data/m178_boss_telegraph_readability.json").read_text())
bosses = json.loads((r / "data/m177_bonusmap_boss_runtime.json").read_text())
slots = json.loads((r / "data/visual_slots.json").read_text())
registry = json.loads((r / "data/admin_content_type_registry.json").read_text())
runtime = (r / "scripts/gameplay/bonusmap_boss_mechanics.gd").read_text()
hud = (r / "scripts/ui/game_hud.gd").read_text()

assert contract["contracts"]["target_zone_is_locked_at_cast_start"] is True
assert contract["contracts"]["ship_movement_remains_tap_to_sail"] is True
assert contract["authority"]["visual_replacement_may_change_timing_or_damage"] is False
for row in bosses["mechanics"].values():
    for key in ["telegraph_anchor", "telegraph_shape", "hit_radius", "dodgeable", "telegraph_color", "telegraph_slot"]:
        assert key in row
    assert row["telegraph_slot"] in slots["vfx"]
for token in ["locked_position", "inside_zone", "BossTelegraph", "reduced_motion", "effect_intensity", "_clear_telegraph"]:
    assert token in runtime
for token in ["danger_telegraph_duration", "remaining", "duration", "progress"]:
    assert token in hud
for content_type in ["boss_telegraph_profile", "boss_safe_zone_profile", "boss_mechanic_readability_profile"]:
    assert content_type in registry["content_types"]
print("M178 BOSS TELEGRAPH READABILITY PASS")
