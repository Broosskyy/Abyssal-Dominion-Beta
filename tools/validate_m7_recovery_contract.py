#!/usr/bin/env python3
"""Validate the M7 Unity recovery catalogs and release separation."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    inventory = json.loads((ROOT / "docs/unity_legacy_inventory.json").read_text(encoding="utf-8"))
    systems = json.loads((ROOT / "docs/seefight_recovered_systems.json").read_text(encoding="utf-8"))
    presets = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    checks = {
        "m7_or_newer_version": any(
            f'config/version="0.{version}.0"' in project for version in range(7, 100)
        ),
        "unity_2021_3_45": "2021.3.45f1" in inventory["unity_versions"],
        "complete_object_inventory": inventory["object_count"] == 196237,
        "complete_mesh_inventory": inventory["type_counts"].get("Mesh") == 660,
        "complete_texture_inventory": inventory["type_counts"].get("Texture2D") == 1559,
        "complete_behaviour_inventory": inventory["type_counts"].get("MonoBehaviour") == 13705,
        "project_script_types": systems["user_script_type_count"] == 793,
        "recovery_report": (ROOT / "docs/M7_RECOVERY_REPORT.md").is_file(),
        "inventory_tool": (ROOT / "tools/inventory_unity_build.py").is_file(),
        "asset_extractor": (ROOT / "tools/extract_unity_reference.py").is_file(),
        "structure_recovery": (ROOT / "tools/recover_unity_structure.py").is_file(),
        "audio_recovery": (ROOT / "tools/extract_unity_audio.py").is_file(),
        "six_reference_exclusions": presets.count('exclude_filter="assets/reference_only/**"') == 6,
    }
    report = {
        "milestone": "M7",
        "passed": all(checks.values()),
        "checks_passed": sum(checks.values()),
        "checks_total": len(checks),
        "checks": checks,
    }
    (ROOT / "docs/m7_recovery_validation.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
