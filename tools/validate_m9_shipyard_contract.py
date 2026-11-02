#!/usr/bin/env python3
"""Validate the M9 ship catalog, roster, UI and persistence contract."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def has(path: str, *needles: str) -> bool:
    value = text(path)
    return all(needle in value for needle in needles)


def main() -> int:
    metadata = text("docs/il2cpp/relevant_game_types.csv")
    checks = {
        "m9_or_newer_version": any(has("project.godot", f'config/version="0.{version}.0"') for version in range(9, 100)),
        "three_ship_profiles": all(
            token in text("scripts/progression/ship_catalog.gd")
            for token in ('"clipper"', '"barco_low"', '"chalupa"')
        ),
        "distinct_ship_stats": has(
            "scripts/progression/ship_catalog.gd",
            '"hull"',
            '"armor"',
            '"speed"',
            '"turn_speed"',
            '"damage"',
        ),
        "owned_and_selected_state": has(
            "scripts/progression/player_ship_roster.gd",
            "owned_ship_ids",
            "selected_ship_id",
            "export_state",
            "import_state",
        ),
        "coin_purchase": has(
            "scripts/progression/player_ship_roster.gd",
            "progression.coins < price",
            "progression.add_coins(-price)",
        ),
        "live_visual_swap": has(
            "scripts/visual/reference_visual_adapter.gd",
            "func apply_profile",
            "RecoveredVisual_",
        ),
        "live_stats": has(
            "scripts/progression/player_ship_roster.gd",
            "set_ship_base_stats",
            "turn_speed_degrees",
            "health.armor",
        ),
        "save_binding": has(
            "scripts/core/game_state.gd",
            '"ship_roster"',
            "roster.export_state()",
            "roster.import_state",
        ),
        "desktop_controls": all(
            f"{action}={{" in text("project.godot")
            for action in ("ship_previous", "ship_next", "ship_select")
        ),
        "touch_controls": has(
            "scripts/ui/game_hud.gd",
            '"SHIP ‹"',
            '"BUY / EQUIP"',
            '"SHIP ›"',
        ) and has(
            "scripts/gameplay/player_input.gd",
            "ship_roster.preview_previous()",
            "ship_roster.buy_or_equip_preview()",
            "ship_roster.preview_next()",
        ),
        "il2cpp_selector_evidence": "Code.Demo.ShipSelection,UIShipSelector" in metadata
        and "ShowNextShip" in metadata
        and "TryBuyShipOrSkin" in metadata,
        "il2cpp_ship_data_evidence": ",,ShipData," in metadata
        and "MovementSpeed" in metadata
        and "AttackPower" in metadata,
        "mapping_document": (ROOT / "docs/M9_IL2CPP_IMPLEMENTATION_MAP.md").stat().st_size > 0,
    }
    report = {
        "milestone": "M9",
        "passed": all(checks.values()),
        "checks_passed": sum(checks.values()),
        "checks_total": len(checks),
        "checks": checks,
    }
    (ROOT / "docs/m9_shipyard_validation.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
