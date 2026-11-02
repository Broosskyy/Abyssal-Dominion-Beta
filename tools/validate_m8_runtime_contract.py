#!/usr/bin/env python3
"""Validate the M8 recovered-runtime and IL2CPP integration contract."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def nonempty(path: str) -> bool:
    item = ROOT / path
    return item.is_file() and item.stat().st_size > 0


def main() -> int:
    ship_adapter = text("scripts/visual/reference_visual_adapter.gd")
    island_adapter = text("scripts/visual/reference_island_adapter.gd")
    port_adapter = text("scripts/visual/reference_port_adapter.gd")
    bootstrap = text("scripts/core/game_bootstrap.gd")
    player_input = text("scripts/gameplay/player_input.gd")
    presets = text("export_presets.cfg")
    il2cpp_types = json.loads(text("docs/il2cpp/assembly_csharp_types.json"))
    runtime_assets = [
        "assets/recovered_test/m8/ships/clipper_hull_lod3.obj",
        "assets/recovered_test/m8/ships/barco_low.obj",
        "assets/recovered_test/m8/ships/npc_chalupa.obj",
        "assets/recovered_test/m8/islands/tropical_island_04_main.obj",
        "assets/recovered_test/m8/islands/tropical_island_01_main.obj",
        "assets/recovered_test/m8/islands/desert_island_06_main.obj",
        "assets/recovered_test/m8/islands/snow_island_02_main.obj",
        "assets/recovered_test/m8/harbor/wooden_pier.obj",
        "assets/recovered_test/m8/harbor/lighthouse.obj",
        "assets/recovered_test/m8/audio/Oceano_en_Calma_1__1323.wav",
        "assets/recovered_test/m8/audio/Blast-Test-10-4-23__570.wav",
    ]
    checks = {
        "m8_or_newer_version": any(
            f'config/version="0.{version}.0"' in text("project.godot")
            for version in range(8, 100)
        ),
        "il2cpp_assembly_type_count": len(il2cpp_types) == 2282,
        "runtime_assets_nonempty": all(nonempty(path) for path in runtime_assets),
        "ship_adapter_runtime": "recovered_test/m8" in ship_adapter and "OS.is_debug_build" not in ship_adapter,
        "island_adapter_runtime": "recovered_test/m8" in island_adapter and "OS.is_debug_build" not in island_adapter,
        "port_adapter_runtime": "recovered_test/m8" in port_adapter and "OS.is_debug_build" not in port_adapter,
        "hud_canvas_layer": "CanvasLayer.new()" in bootstrap and 'hud_layer.add_child(hud)' in bootstrap,
        "target_position_sailing": "_set_navigation_target" in player_input and "MoveTargetMarker" in player_input,
        "recovered_water_maps": "water_bump.png" in text("scripts/visual/water_surface.gd") and "water_foam.png" in text("scripts/visual/water_surface.gd"),
        "recovered_audio": "CANNON_AUDIO" in text("scripts/gameplay/ship_weapons.gd") and "SINK_AUDIO" in text("scripts/gameplay/ship_health.gd"),
        "six_legacy_reference_exclusions": presets.count('exclude_filter="assets/reference_only/**"') == 6,
        "runtime_subset_not_excluded": "recovered_test" not in presets,
        "implementation_map": nonempty("docs/M8_IL2CPP_IMPLEMENTATION_MAP.md"),
    }
    report = {
        "milestone": "M8",
        "passed": all(checks.values()),
        "checks_passed": sum(checks.values()),
        "checks_total": len(checks),
        "checks": checks,
    }
    (ROOT / "docs/m8_runtime_validation.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
