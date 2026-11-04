import json, pathlib

r = pathlib.Path(__file__).resolve().parents[1]
release = json.loads((r / "data/release_identity.json").read_text())
assert int(release["milestone"].removeprefix("M")) >= 176
assert release["build_number"] >= 176

data = json.loads((r / "data/m176_runtime_feedback.json").read_text())
assert data["hud_lock"]["camera_joystick"] == "bottom_left_camera_only"
assert data["hud_lock"]["ship_movement"] == "tap_to_sail"
assert data["bonusmap_rules"]["final_boss_resolution"] == "last_authored_runtime_wave"
assert data["authority"]["presentation_may_grant_rewards"] is False

health = (r / "scripts/gameplay/ship_health.gd").read_text()
weapons = (r / "scripts/gameplay/ship_weapons.gd").read_text()
enemy = (r / "scripts/gameplay/enemy_ship_ai.gd").read_text()
bonus = (r / "scripts/world/bonusmap_wave_director.gd").read_text()
hud = (r / "scripts/ui/game_hud.gd").read_text()
nautical = (r / "scripts/ui/nautical_hud.gd").read_text()
boot = (r / "scripts/core/game_bootstrap.gd").read_text()
registry = json.loads((r / "data/admin_content_type_registry.json").read_text())

for token in ["barrier_absorb", "armor_saved", '"block"', '"armor"', "record_value"]:
    assert token in health
assert 'health.repair(180.0 * heal_mult, ship, "heal")' in weapons
assert 'health.restore_shield(150.0 * heal_mult, ship)' in weapons
assert 'var event_id := "boss_enrage" if _phase >= 3 else "boss_phase"' in enemy
assert "hud.present_event(event_id" in enemy
assert "_is_final_runtime_wave" in bonus
for event_id in ["bonus_wave_start", "bonus_wave_clear", "bonus_complete", "bonus_boss"]:
    assert event_id in bonus
gold = (r / "scripts/progression/gold_bonusmap_progress.gd").read_text()
abyss = (r / "scripts/progression/abyss_bonusmap_progress.gd").read_text()
assert 'runtime_waves().size()' in gold and 'wave<total' in gold
assert 'runtime_waves()' in abyss and 'wave<total' in abyss
assert "func note_prioritized" in hud and "func present_event" in hud
assert "active_notice" in nautical
assert "M176RuntimeFeedbackCatalog.new()" in boot
for content_type in ["runtime_notification_profile", "combat_value_feedback_profile", "bonusmap_feedback_profile", "boss_phase_feedback_profile"]:
    assert content_type in registry["content_types"]

print("M176 RUNTIME COMBAT/BOSS/BONUSMAP FEEDBACK PASS")
