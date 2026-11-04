#!/usr/bin/env python3
"""Static M5 contract validation for all supported Godot targets."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT = (ROOT / "project.godot").read_text(encoding="utf-8")
EXPORTS = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")


def check(name: str, condition: bool, detail: str) -> dict[str, object]:
    return {"name": name, "passed": bool(condition), "detail": detail}


def main() -> int:
    preset_names = ["Web", "Android", "iOS", "Windows Desktop", "macOS", "Linux"]
    input_actions = [
        "move_forward",
        "move_back",
        "turn_left",
        "turn_right",
        "fire",
        "map_toggle",
        "target_next",
        "repair",
        "ability",
        "interact",
    ]
    gdscript_text = "\n".join(
        path.read_text(encoding="utf-8") for path in (ROOT / "scripts").rglob("*.gd")
    )
    checks = [
        check("Godot 4.7 feature", 'config/features=PackedStringArray("4.7"' in PROJECT, "Project declares Godot 4.7"),
        check("Compatibility renderer", 'renderer/rendering_method="gl_compatibility"' in PROJECT, "Desktop renderer"),
        check("Mobile Compatibility renderer", 'renderer/rendering_method.mobile="gl_compatibility"' in PROJECT, "Mobile renderer"),
        check("Landscape orientation", "window/handheld/orientation=6" in PROJECT, "Landscape sensor mode"),
        check("Adaptive stretch", 'window/stretch/aspect="expand"' in PROJECT, "Aspect-ratio expansion"),
        check("Mobile compression", "textures/vram_compression/import_etc2_astc=true" in PROJECT, "ETC2/ASTC import"),
        check("Desktop compression", "textures/vram_compression/import_s3tc_bptc=true" in PROJECT, "S3TC/BPTC import"),
        check("All export presets", all(f'name="{name}"' in EXPORTS for name in preset_names), ", ".join(preset_names)),
        check("Reference exclusion", EXPORTS.count('exclude_filter="assets/reference_only/**') == 6, "Six protected presets"),
        check("Input actions", all(f"{action}={{" in PROJECT for action in input_actions), ", ".join(input_actions)),
        check("Controller mappings", PROJECT.count("InputEventJoypad") >= 9, "Joypad axes and buttons"),
        check("Touch input", "InputEventScreenTouch" in gdscript_text and "InputEventScreenDrag" in gdscript_text, "Touch and drag"),
        check("Pinch zoom", "apply_pinch_delta" in gdscript_text and "pinch_distance" in gdscript_text, "Two-finger zoom path"),
        check("Safe area", gdscript_text.count("get_display_safe_area") >= 2, "HUD and input safe-area transforms"),
        check("Focus pause", "NOTIFICATION_APPLICATION_FOCUS_OUT" in gdscript_text, "Suspend/resume handling"),
        check("Adaptive quality", "quality_tier" in gdscript_text and "scaling_3d_scale" in gdscript_text, "Runtime quality profile"),
        check("Dynamic reference loading", 'preload("res://assets/reference_only/' not in gdscript_text, "No hard release dependency"),
        check("Production icon", (ROOT / "assets/production/ui/app_icon.svg").is_file(), "SVG app icon"),
        check("Production splash", (ROOT / "assets/production/ui/splash.png").is_file(), "PNG boot splash"),
    ]
    report = {
        "milestone": "M5",
        "passed": all(item["passed"] for item in checks),
        "checks_passed": sum(1 for item in checks if item["passed"]),
        "checks_total": len(checks),
        "checks": checks,
    }
    output = ROOT / "docs/m5_platform_validation.json"
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
