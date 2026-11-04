import json
import pathlib

r = pathlib.Path(__file__).resolve().parents[1]
release = json.loads((r / "data/release_identity.json").read_text())
contract = json.loads((r / "data/m181_gameplay_feedback_repair.json").read_text())
player_input = (r / "scripts/gameplay/player_input.gd").read_text()
motor = (r / "scripts/gameplay/ship_motor.gd").read_text()
health = (r / "scripts/gameplay/ship_health.gd").read_text()
enemy = (r / "scripts/gameplay/enemy_ship_ai.gd").read_text()
loot = (r / "scripts/gameplay/loot_pickup.gd").read_text()
hud = (r / "scripts/ui/nautical_hud.gd").read_text()
encounters = (r / "scripts/world/encounter_director.gd").read_text()

assert release["build_number"] >= 181
assert contract["milestone"] == "M181"
assert contract["navigation"]["behind_target_behavior"] == "pivot_then_accelerate"
assert contract["defeat_respawn"]["protection_seconds"] == 6.0
assert contract["loot_rewards"]["proximity_collect_radius"] == 4.25

for token in ["angle_degrees >= 58.0", 'ship.throttle_input = 0.0', 'ship.set_meta("navigation_pivoting", pivoting)']:
    assert token in player_input
for token in ['get_meta("navigation_pivoting", false)', "acceleration_scale := 4.0", "turn_scale: float = 1.0"]:
    assert token in motor
for token in ["PLAYER_RESPAWN_PROTECTION_SECONDS", 'ship.set_meta("respawn_at_msec"', 'ship.set_meta("respawn_protection_until"', "ship_respawned.emit"]:
    assert token in health
for token in ["_target_is_attackable", 'candidate.get_meta("respawn_protection_until"', "candidate_health.is_sunk"]:
    assert token in enemy
for token in ["proximity_collect_radius", "_collect(player)", "body_entered.connect", 'note_prioritized(reward_text, 8, "reward"']:
    assert token in loot
for token in ["_draw_defeat_overlay", "SCHIFF VERSENKT", 'hud.notice_family in ["reward", "respawn", "defeat"]']:
    assert token in hud
assert "ZIEL VERSENKT · +%d EXP · BEUTE IM WASSER" in encounters

# M180 visual repair must remain present in the M181 source.
assert (r / "data/m180_mobile_visual_repair.json").exists()
assert "Secondary destinations remain available through MENU" in (r / "scripts/ui/nautical_layout.gd").read_text()
assert "surface_roughness" in (r / "scripts/visual/water_surface.gd").read_text()

print("M181 GAMEPLAY FEEDBACK/RECOVERY REPAIR PASS")
