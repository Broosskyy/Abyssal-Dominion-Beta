#!/usr/bin/env python3
"""Run real Godot import and behavior tests; reject logged errors, even at exit 0."""
import argparse
import json
import re
import subprocess
from pathlib import Path
from preview import validate_engine

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--engine", required=True, help="Godot executable path")
    parser.add_argument("--milestone", choices=["m10", "m11", "m12", "m13", "m14", "m15", "m16", "m17", "m18"], default="m18")
    args = parser.parse_args()
    version = subprocess.check_output([args.engine, "--version"], text=True).strip()
    validate_engine(version)
    stages = [
        ("import", ["--editor", "--import"]),
        ("m10_behavior", ["--script", "res://tests/m10_encounters_test.gd"]),
    ]
    if args.milestone in {"m11", "m12", "m13", "m14", "m15", "m16", "m17", "m18"}:
        stages.append(("m11_behavior", ["--script", "res://tests/m11_arsenal_test.gd"]))
    if args.milestone in {"m12", "m13", "m14", "m15", "m16", "m17", "m18"}:
        stages.append(("m12_behavior", ["--script", "res://tests/m12_platform_test.gd"]))
    if args.milestone in {"m13", "m14", "m15", "m16", "m17", "m18"}:
        stages.append(("m13_behavior", ["--script", "res://tests/m13_entry_test.gd"]))
    if args.milestone in {"m14", "m15", "m16", "m17", "m18"}:
        stages.append(("m14_behavior", ["--script", "res://tests/m14_settings_test.gd"]))
    if args.milestone in {"m15", "m16", "m17", "m18"}:
        stages.append(("m15_behavior", ["--script", "res://tests/m15_combat_presentation_test.gd"]))
    if args.milestone in {"m16", "m17", "m18"}:
        stages.append(("m16_behavior", ["--script", "res://tests/m16_mockup_hud_test.gd"]))
    if args.milestone in {"m17", "m18"}:
        stages.append(("m17_behavior", ["--script", "res://tests/m17_target_loot_test.gd"]))
    if args.milestone == "m18":
        stages.append(("m18_behavior", ["--script", "res://tests/m18_journal_selection_test.gd"]))
    report = {"engine": version, "mode": "headless/dummy renderer", "visual_verification": False, "stages": []}
    for name, options in stages:
        result = subprocess.run([args.engine, "--headless", "--path", str(ROOT), *options],
                                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
        log = result.stdout
        (ROOT / f"docs/{args.milestone}_engine_{name}.log").write_text(log)
        passed = result.returncode == 0 and not re.search(r"(?:^|\n)(?:SCRIPT )?ERROR:", log)
        match = re.search(r"M(?:10|11|12|13|14|15|16|17|18)_ENGINE_TESTS: (\d+)/(\d+) passed", log)
        if name.endswith("behavior"):
            passed = passed and bool(match) and match[1] == match[2] and int(match[2]) > 0
        report["stages"].append({"stage": name, "exit_code": result.returncode, "passed": passed})
        if match:
            report["checks_passed"] = report.get("checks_passed", 0) + int(match[1])
            report["checks_total"] = report.get("checks_total", 0) + int(match[2])
    report["passed"] = all(stage["passed"] for stage in report["stages"])
    (ROOT / f"docs/{args.milestone}_engine_validation.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
