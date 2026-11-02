#!/usr/bin/env python3
"""Decode selected original Texture2D objects without repainting/resampling.

Requires UnityPy 1.25.3. Supply the extracted SeeFight 3D_Data directory.
Object identifiers come from docs/unity_asset_catalog.csv. Chain Shot has no
verified icon mapping and intentionally remains text-only in the test arsenal.
"""
import argparse
import hashlib
import json
from pathlib import Path

import UnityPy

ROOT = Path(__file__).resolve().parents[1]
TARGETS = {237: "iron", 261: "explosive", 723: "repair", 392: "boost",
           732: "cannon", 346: "deck", 660: "shield"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    source = args.source / "sharedassets2.assets"
    environment = UnityPy.load(str(source))
    output = ROOT / "assets/recovered_test/m11/ui"
    output.mkdir(parents=True, exist_ok=True)
    assets, errors = [], []
    for obj in environment.objects:
        if obj.assets_file.name != source.name or obj.path_id not in TARGETS:
            continue
        if obj.type.name != "Texture2D":
            continue
        try:
            data = obj.read()
            picture = data.image
            destination = output / (TARGETS[obj.path_id] + ".png")
            picture.save(destination, optimize=True)
            assets.append({"source": source.name, "path_id": obj.path_id,
                           "type": obj.type.name, "original_name": data.m_Name,
                           "path": str(destination.relative_to(ROOT)),
                           "width": picture.width, "height": picture.height,
                           "sha256": hashlib.sha256(destination.read_bytes()).hexdigest()})
        except Exception as exc:
            errors.append({"path_id": obj.path_id, "error": str(exc)})
    # sharedassets2/841 Black_Gunpowder has no image data. Use a separate,
    # valid original Gunpowder image, keeping its distinct identity explicit.
    alternate = UnityPy.load(str(args.source / "resources.assets"))
    for obj in alternate.objects:
        if obj.assets_file.name == "resources.assets" and obj.path_id == 399 and obj.type.name == "Texture2D":
            data = obj.read()
            picture = data.image
            destination = output / "gunpowder.png"
            picture.save(destination, optimize=True)
            assets.append({"source": "resources.assets", "path_id": 399,
                           "type": obj.type.name, "original_name": data.m_Name,
                           "path": str(destination.relative_to(ROOT)),
                           "width": picture.width, "height": picture.height,
                           "sha256": hashlib.sha256(destination.read_bytes()).hexdigest()})
    report = {"decoder": "UnityPy " + UnityPy.__version__, "assets": assets, "errors": errors,
              "unavailable": [{"source": "sharedassets2.assets", "path_id": 841,
                               "original_name": "Black_Gunpowder", "reason": "Texture2D has no image data"}],
              "note": "Original pixels decoded to PNG; no gameplay values recovered from these images."}
    (ROOT / "docs/m11_recovered_icons.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return 0 if len(assets) == len(TARGETS) + 1 and not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
