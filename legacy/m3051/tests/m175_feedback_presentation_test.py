import json, pathlib

r = pathlib.Path(__file__).resolve().parents[1]
release = json.loads((r / "data/release_identity.json").read_text())
assert int(release["milestone"].removeprefix("M")) >= 175
assert release["build_number"] >= 175
assert release["master_concept"] == "V3.8"

data = json.loads((r / "data/m175_feedback_presentation.json").read_text())
lock = data["immutable_hud_contract"]
assert lock["bottom_left"] == "camera_joystick_only"
assert lock["ship_movement"] == "tap_to_sail"
assert lock["bottom_right"] == "large_primary_attack_with_combat_actions"
assert lock["camera_joystick_may_steer_ship"] is False
assert set(data["reward_presentations"]) >= {"common", "rare", "epic", "legendary", "abyssal"}
assert len(data["layerable_status_vfx"]) >= 10

feedback = (r / "scripts/combat/combat_feedback.gd").read_text()
vfx = (r / "scripts/visual/combat_vfx.gd").read_text()
loot = (r / "scripts/gameplay/loot_pickup.gd").read_text()
settings = (r / "scripts/core/client_settings.gd").read_text()
boot = (r / "scripts/core/game_bootstrap.gd").read_text()
loader = (r / "scripts/core/json_data_loader.gd").read_text()
registry = json.loads((r / "data/admin_content_type_registry.json").read_text())

for token in ["crowd_merge_window", "crowd_threshold", "value_kind", "entry_limit"]:
    assert token in feedback
for token in ["effect_intensity", "reduced_motion", "reduced_flashes", "vfx_profile"]:
    assert token in vfx
assert "reward_presentation" in loot and ("note_tiered" in loot or "note_prioritized" in loot)
assert '"effect_intensity": 1.0' in settings
assert "M175FeedbackPresentationCatalog.new()" in boot
assert "class_name JsonDataLoader" in loader
for content_type in ["damage_number_profile", "reward_presentation_profile", "vfx_presentation_profile", "notification_family_profile", "screen_feedback_profile"]:
    assert content_type in registry["content_types"]

print("M175 DATA-DRIVEN COMBAT/REWARD/MOBILE FEEDBACK PASS")
