from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]

def test_m190_contract_and_release():
    data = json.loads((ROOT / "data/m190_world_composition_readability.json").read_text())
    release = json.loads((ROOT / "data/release_identity.json").read_text())
    assert data["milestone"] == "M190"
    assert release["build_number"] >= 190
    assert data["locks"]["tap_to_sail_preserved"] is True
    assert data["locks"]["camera_wheel_camera_only"] is True
    assert data["locks"]["collision_and_combat_scale_unchanged"] is True

def test_camera_is_modestly_closer_without_removing_controls():
    camera = (ROOT / "scripts/gameplay/camera_rig.gd").read_text()
    assert "var base_offset := Vector3(11.2, 19.5, -16.8)" in camera
    assert "var zoom_factor := 1.0" in camera
    assert "fov = 38.0" in camera
    for token in ["apply_pinch_delta", "pan_camera", "func recenter", "pan_offset"]:
        assert token in camera

def test_water_is_restrained_and_old_mobile_contract_preserved():
    water = (ROOT / "scripts/visual/water_surface.gd").read_text()
    assert "UV * 8.2" in water and "UV.yx * 13.5" in water
    assert "* 0.032" in water
    assert "SPECULAR = clamp(specular_strength, 0.10, 0.26)" in water
    assert "NORMAL_MAP_DEPTH = 0.22" in water
    assert "motion_scale" in water

def test_world_center_cleanup_and_priority_preserved():
    hud = (ROOT / "scripts/ui/nautical_hud.gd").read_text()
    game_hud = (ROOT / "scripts/ui/game_hud.gd").read_text()
    assert "(layout.top as Rect2).end.y + 48.0 * ui_scale" in hud
    assert "safe.position.y + safe.size.y * 0.35" not in hud
    assert 'distance<=34.0' in game_hud
    assert "_draw_tracked_objective_marker" in game_hud
    assert 'keep_readable:=ship.is_in_group("player") or ship==selected_target' in game_hud
