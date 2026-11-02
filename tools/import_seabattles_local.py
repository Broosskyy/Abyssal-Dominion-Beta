#!/usr/bin/env python3
"""LOCAL ONLY: inventory selected Unity Texture2D graphics from user-owned .apks.

Usage:
  python -m pip install UnityPy Pillow
  python tools/import_seabattles_local.py "SeaBattles (1.24.0).apks"

No client is launched, no Internet is accessed, and no input is written to GitHub.
Resulting images are gitignored; check rights before any redistribution.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

DEST = Path(__file__).resolve().parent.parent / "assets/classic/private_seabattles"

# Only exact known names are auto-mapped into the playable M303.5 slots.
SHIP_NAMES = {
    "elite8": "ships/elite8.png",
    "warship": "ships/warship.png",
    "pinnace": "ships/pinnace.png",
    "flyingdutchman": "ships/flyingdutchman.png",
}
MONSTER_NAMES = {
    "mobydick": "monsters/mobydick.png",
    "tiamat": "monsters/tiamat.png",
    "glasciadon": "monsters/glasciadon.png",
}
SURFACE_NAMES = {"water": "ocean/water.png", "ocean": "ocean/water.png", "seawater": "ocean/water.png"}
UI_NAMES = {"topbar": "ui/topbar.png", "hudframe": "ui/hudframe.png", "minimapframe": "ui/minimapframe.png"}
ISLAND_RULES = {
    "snow": "islands/snow.png",
    "tropical": "islands/tropical.png",
    "rock": "islands/rock.png",
}
# Only accept likely island names, not unrelated UI pictures.
ISLAND_TOKENS = ("island", "isle", "landmass", "iceberg", "island_")
MAX_TEXTURES = 200000

def asset_key(raw_name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", raw_name.casefold())

def destination_for(name: str) -> str | None:
    key = asset_key(name)
    if key in SHIP_NAMES:
        return SHIP_NAMES[key]
    if key in MONSTER_NAMES:
        return MONSTER_NAMES[key]
    if key in SURFACE_NAMES:
        return SURFACE_NAMES[key]
    if key in UI_NAMES:
        return UI_NAMES[key]
    lowered = name.casefold()
    if any(token in lowered for token in ISLAND_TOKENS):
        for token, output in ISLAND_RULES.items():
            if token in lowered:
                return output
    return None

def safely_copy_zip_members(zf: zipfile.ZipFile, target: Path) -> int:
    count = 0
    for item in zf.infolist():
        if item.is_dir():
            continue
        parts = PurePosixPath(item.filename).parts
        if not parts or ".." in parts or parts[0].startswith("/"):
            continue
        candidate = item.filename.casefold()
        # Unity's streamed .resS must remain next to its matching .assets files.
        if not (candidate.startswith("assets/bin/data/") or
                candidate.startswith("assets/streamingassets/") or
                candidate.startswith("assets/aa/")):
            continue
        output = target.joinpath(*parts)
        output.parent.mkdir(parents=True, exist_ok=True)
        with zf.open(item, "r") as src, open(output, "wb") as dst:
            shutil.copyfileobj(src, dst, 1024 * 1024)
        count += 1
    return count

def candidate_asset(filename: str) -> bool:
    name = Path(filename).name.lower()
    return (name.endswith((".assets", ".bundle", ".unity3d", ".assetbundle")) or
            name in ("globalgamemanagers", "data.unity3d"))

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("apk_collection", type=Path)
    parser.add_argument("--all", action="store_true", help="Export and audit every Texture2D and Sprite")
    parser.add_argument("--output", type=Path, default=DEST, help="Local-only graphics/report directory")
    args = parser.parse_args()
    if not args.apk_collection.is_file():
        parser.error("APK collection is missing")
    if args.all:
        from unity_graphics_audit import extract_all
        return extract_all(args.apk_collection, args.output)
    try:
        import UnityPy
    except ImportError:
        parser.error("Install decoder first: python -m pip install UnityPy Pillow")
    DEST.mkdir(parents=True, exist_ok=True)
    report = {
        "source": args.apk_collection.name,
        "mode": "offline_static_analysis",
        "selected": {},
        "texture2d_names": [],
        "warnings": [],
    }
    selected_pixels: dict[str, int] = {}
    seen: set[tuple[str, int]] = set()
    with tempfile.TemporaryDirectory(prefix="seabattles_offline_") as tempdir:
        root = Path(tempdir)
        apk_paths = []
        with zipfile.ZipFile(args.apk_collection) as outer:
            for item in outer.infolist():
                if item.filename.lower().endswith(".apk"):
                    dest = root / ("part_" + str(len(apk_paths)) + ".apk")
                    with outer.open(item) as inp, dest.open("wb") as out:
                        shutil.copyfileobj(inp, out, 1024 * 1024)
                    apk_paths.append(dest)
        if not apk_paths:
            # The supplied archive might itself be a normal APK.
            apk_paths.append(args.apk_collection)
        for index, package in enumerate(apk_paths):
            extracted = root / f"resources_{index}"
            extracted.mkdir()
            try:
                with zipfile.ZipFile(package) as apk:
                    file_count = safely_copy_zip_members(apk, extracted)
            except (OSError, zipfile.BadZipFile) as exc:
                report["warnings"].append(f"APK part {index}: {exc}")
                continue
            if file_count == 0:
                continue
            paths = [p for p in extracted.rglob("*") if p.is_file() and candidate_asset(p.name)]
            for asset_path in paths:
                try:
                    env = UnityPy.load(str(asset_path))
                    for obj in env.objects:
                        if getattr(obj.type, "name", "") != "Texture2D":
                            continue
                        data = obj.read()
                        name = str(getattr(data, "m_Name", getattr(data, "name", "")))
                        label = (name, int(getattr(obj, "path_id", 0)))
                        if label in seen:
                            continue
                        seen.add(label)
                        if len(report["texture2d_names"]) < MAX_TEXTURES:
                            report["texture2d_names"].append(name)
                        relative = destination_for(name)
                        if relative is None:
                            continue
                        try:
                            picture = data.image
                            if picture is None:
                                raise ValueError("UnityPy decoder returned no image")
                            picture = picture.convert("RGBA")
                            area = picture.width * picture.height
                            if area <= selected_pixels.get(relative, 0):
                                continue
                            out = DEST / relative
                            out.parent.mkdir(parents=True, exist_ok=True)
                            picture.save(out)
                            selected_pixels[relative] = area
                            report["selected"][relative] = {
                                "unity_asset": name,
                                "width": picture.width,
                                "height": picture.height,
                                "pixel_format": "RGBA PNG",
                            }
                        except Exception as exc:
                            report["warnings"].append(f"{name} texture decoding: {exc}")
                except Exception as exc:
                    # A file may use an unrecognized Unity resource variant.
                    report["warnings"].append(f"{asset_path.name}: {exc}")
    (DEST / "scan_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Found {len(report['texture2d_names'])} named Texture2D assets.")
    print(f"Exported {len(report['selected'])} selected local PNGs into {DEST}")
    print("Please inspect scan_report.json and the images visually.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
