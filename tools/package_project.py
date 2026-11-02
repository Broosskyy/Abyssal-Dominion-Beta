#!/usr/bin/env python3
"""Package source/assets/docs, excluding editor caches, binaries and user saves."""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("--include-web", action="store_true", help="Bundle the current prebuilt preview")
    args = parser.parse_args()
    output = args.output.resolve()
    if ROOT == output or ROOT in output.parents:
        parser.error("output must be outside the project")
    output.parent.mkdir(parents=True, exist_ok=True)
    excluded = {".godot", ".git", "__pycache__", "node_modules", ".tools"}
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(ROOT.rglob("*")):
            relative = path.relative_to(ROOT)
            if not path.is_file() or any(part in excluded for part in relative.parts):
                continue
            if relative.parts[0] == "builds" and (not args.include_web or relative.parts[:2] != ("builds", "web")):
                continue
            if path.suffix in {".pyc", ".pyo"}:
                continue
            archive.write(path, relative.as_posix())
    with zipfile.ZipFile(output) as archive:
        corrupt = archive.testzip()
        if corrupt:
            raise RuntimeError("ZIP CRC failure: " + corrupt)
        required = ["project.godot", "scripts/progression/player_inventory.gd",
                    "scripts/ui/arsenal_panel.gd", "tests/m11_arsenal_test.gd", "docs/M11_REPORT.md"]
        assert all(name in archive.namelist() for name in required)
        report = json.loads(archive.read("docs/m11_engine_validation.json"))
        assert report["passed"] and report["checks_passed"] == report["checks_total"]
        for asset in json.loads(archive.read("docs/m11_recovered_icons.json"))["assets"]:
            assert hashlib.sha256(archive.read(asset["path"])).hexdigest() == asset["sha256"]
        if args.include_web:
            from preview import fingerprint, validate_engine
            stamp = json.loads(archive.read("builds/web/preview-build.json"))
            validate_engine(stamp["engine"])
            assert stamp["source_sha256"] == fingerprint(), "Web build is stale"
            for suffix in ("html", "js", "wasm", "pck"):
                assert f"builds/web/index.{suffix}" in archive.namelist()
            latest = json.loads(archive.read("docs/m18_engine_validation.json"))
            validate_engine(latest["engine"])
            assert latest["passed"]
            for asset in json.loads(archive.read("docs/m12_recovered_visual_assets.json"))["assets"]:
                assert hashlib.sha256(archive.read(asset["path"])).hexdigest() == asset["sha256"]
        count = len(archive.namelist())
    print(json.dumps({"archive": str(output), "files": count, "bytes": output.stat().st_size,
                      "sha256": hashlib.sha256(output.read_bytes()).hexdigest()}, indent=2))


if __name__ == "__main__":
    main()
