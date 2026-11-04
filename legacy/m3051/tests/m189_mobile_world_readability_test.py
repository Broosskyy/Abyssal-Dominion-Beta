from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def test_m189_contract():
    data = json.loads((ROOT / "data/m189_mobile_world_readability.json").read_text())
    assert data["milestone"] == "M189"
    assert data["locks"]["tap_to_sail_preserved"] is True
    assert data["locks"]["camera_wheel_camera_only"] is True
    assert data["locks"]["primary_attack_bottom_right"] is True
    assert data["locks"]["harbor_is_local_world_poi"] is True


def test_contextual_harbor_copy_and_no_shipyard_dock_claim():
    hud = (ROOT / "scripts/ui/nautical_hud.gd").read_text()
    assert 'count = "HAFEN" if player.has_meta("nearby_port") else "ZIEL"' in hud
    assert "WERFT ZUM ANLEGEN" not in hud
    assert "LOKALE HAFENINTERAKTION VERFÜGBAR" in hud


def test_objective_marker_avoids_reserved_hud():
    hud = (ROOT / "scripts/ui/game_hud.gd").read_text()
    assert "var reserved := NauticalLayout.reserved(layout(), log_visible())" in hud
    assert "candidate_rect.intersects(hud_rect)" in hud
    assert "base_direction.rotated(angle)" in hud


def test_current_nautical_hud_does_not_stack_legacy_mobile_action_rail_on_shipyard():
    hud = (ROOT / "scripts/ui/nautical_hud.gd").read_text()
    shop_tail = 'elif progression.shop_open:\n\t\thud._draw_shop(safe, clampf(safe.size.y / 720, 0.7, 1.3), progression)'
    assert shop_tail in hud
    # The helper remains for legacy fallback compatibility, but NauticalHud.paint must not invoke it.
    assert "hud._draw_mobile_actions" not in hud
