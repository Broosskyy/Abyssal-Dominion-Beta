#!/usr/bin/env python3
"""Read-only GLB integrity check for full Meshy ship geometry.

Do not 'repair' GLB triangle indices: earlier UV decimation produced fractured
hulls and deleting spike triangles only made the missing faces worse.
"""
import json
import struct
import sys
from pathlib import Path

MODELS = Path(__file__).resolve().parents[1] / "assets/npc/meshy/models"
WARN_ONLY = "--warn-only" in sys.argv


def inspect(path: Path):
    raw = path.read_bytes()
    if raw[:4] != b"glTF" or struct.unpack_from("<I", raw, 4)[0] != 2:
        raise ValueError("not a glTF 2.0 GLB")
    if struct.unpack_from("<I", raw, 8)[0] != len(raw):
        raise ValueError("truncated GLB")
    json_size, chunk_type = struct.unpack_from("<II", raw, 12)
    if chunk_type != 0x4E4F534A:
        raise ValueError("missing JSON chunk")
    doc = json.loads(raw[20:20 + json_size])
    faces = sum(
        doc["accessors"][primitive["indices"]]["count"] // 3
        for mesh in doc["meshes"]
        for primitive in mesh["primitives"]
        if "indices" in primitive
    )
    bounds = [
        doc["accessors"][primitive["attributes"]["POSITION"]]
        for mesh in doc["meshes"]
        for primitive in mesh["primitives"]
    ]
    if not bounds or not all("min" in acc and "max" in acc for acc in bounds):
        raise ValueError("missing POSITION bounds")
    minima = [min(acc["min"][axis] for acc in bounds) for axis in range(3)]
    maxima = [max(acc["max"][axis] for acc in bounds) for axis in range(3)]
    spans = [maxima[axis] - minima[axis] for axis in range(3)]
    if faces < 28000:
        raise ValueError(f"damaged or over-decimated geometry: {faces} faces, expected >= 28000")
    if spans[1] < spans[2] * 1.1 or spans[0] < spans[2] * 1.6:
        raise ValueError(f"wrong ship axes/bounds {spans}; source GLBs are Y-up, X-long")
    return {"triangles": faces, "bounds_xyz": spans, "bytes": len(raw)}


def main():
    ships = sorted(MODELS.glob("*.glb"))
    errors = []
    if len(ships) != 9:
        errors.append(f"Expected exactly nine GLB models, got {len(ships)}")
    for ship in ships:
        try:
            print(json.dumps({"model": ship.name, **inspect(ship)}, ensure_ascii=False))
        except (ValueError, KeyError, IndexError, struct.error) as err:
            errors.append(f"{ship.name}: {err}")
    for err in errors:
        print("GLB INTEGRITY WARNING: " + err, file=sys.stderr)
    if errors and not WARN_ONLY:
        sys.exit(1)
    print(f"Validated {len(ships)} GLBs, integrity warnings: {len(errors)}")


if __name__ == "__main__":
    main()
