import json
import pathlib

r = pathlib.Path(__file__).resolve().parents[1]
release = json.loads((r / "data/release_identity.json").read_text())
contract = json.loads((r / "data/m182_mobile_interaction_hardening.json").read_text())
markers = json.loads((r / "data/m79_marker_priority.json").read_text())
registry = json.loads((r / "data/admin_content_type_registry.json").read_text())
input_code = (r / "scripts/gameplay/player_input.gd").read_text()
loot = (r / "scripts/gameplay/loot_pickup.gd").read_text()
hud = (r / "scripts/ui/game_hud.gd").read_text()
nautical = (r / "scripts/ui/nautical_hud.gd").read_text()
weapons = (r / "scripts/gameplay/ship_weapons.gd").read_text()
camera = (r / "scripts/gameplay/camera_rig.gd").read_text()

assert release["build_number"] >= 182 and release["master_concept"] == "V3.8"
assert contract["modal_input_ownership"]["background_world_taps_may_leak"] is False
assert contract["loot_guidance"]["tap_visible_loot_to_sail"] is True
assert markers["priority"]["loot"] == 60

for key in contract["modal_input_ownership"]["blocked_world_input_states"]:
    assert key in input_code and key in weapons
for token in ["_modal_input_blocked", "_loot_at_screen", 'navigation_intent", "loot"', "KURS AUF BEUTE"]:
    assert token in input_code
for token in ['add_to_group("world_poi_markers")', 'set_meta("poi_kind", "loot")', 'set_meta("marker_slot", "marker_loot")']:
    assert token in loot
assert '"loot"] and distance<=34.0' in hud
assert "protection_remaining" in nautical and "SCHUTZ %.0fs" in nautical
assert "RESPAWN-SCHUTZ BEENDET" in weapons
assert "admin_panel_open" in camera and "meta_panel_open" in camera
for content_type in ["mobile_interaction_safety_profile", "loot_guidance_profile"]:
    assert content_type in registry["content_types"]

assert (r / "data/m180_mobile_visual_repair.json").exists()
assert (r / "data/m181_gameplay_feedback_repair.json").exists()

print("M182 MOBILE INTERACTION HARDENING PASS")
