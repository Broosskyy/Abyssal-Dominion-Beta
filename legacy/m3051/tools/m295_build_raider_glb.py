"""Reproducibly create one complete, visual-only M295 Raider GLB placeholder.

The P0 scout is intentionally left untouched. This is a distinct morph/material
variant of a *whole* ship mesh, not runtime hull/sail modules or final art.
"""

import hashlib
import json
import math
from pathlib import Path
import struct


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/production_placeholders/p0/npc_scout_01.glb"
OUTPUT = ROOT / "assets/production_placeholders/m295/npc_raider_01.glb"
EXPECTED_SOURCE_SHA256 = "736cfebb4ac521f3ae00c75e44f3930d2b2a48eab07f3724d388e8d92a1e8c00"

# x, y, z of the complete mesh, per existing material surface. Positions and
# normals change together; hull collisions and combat stats are not in this GLB.
SHAPE = {
    "deck": (1.18, 1.04, 0.94),
    "gold": (1.19, 1.02, 0.94),
    "hull": (1.18, 1.04, 0.94),
    "iron": (1.22, 0.92, 0.96),
    "red": (1.28, 0.91, 1.07),
    "wood": (1.18, 1.02, 0.94),
}
PALETTE = {
    "deck": [0.32, 0.23, 0.19, 1.0],
    "gold": [0.62, 0.39, 0.16, 1.0],
    "hull": [0.105, 0.066, 0.066, 1.0],
    "iron": [0.065, 0.075, 0.083, 1.0],
    "red": [0.37, 0.055, 0.075, 1.0],
    "wood": [0.25, 0.145, 0.105, 1.0],
}


def create() -> dict:
    original = SOURCE.read_bytes()
    assert hashlib.sha256(original).hexdigest() == EXPECTED_SOURCE_SHA256
    magic, version, total_length = struct.unpack_from("<4sII", original)
    assert (magic, version, total_length) == (b"glTF", 2, len(original))
    json_size, json_kind = struct.unpack_from("<I4s", original, 12)
    assert json_kind == b"JSON"
    document = json.loads(original[20:20 + json_size])
    bin_header = 20 + json_size
    bin_size, bin_kind = struct.unpack_from("<I4s", original, bin_header)
    assert bin_kind == b"BIN\x00" and bin_header + 8 + bin_size == len(original)
    binary = bytearray(original[bin_header + 8:])
    assert len(document["nodes"]) == len(document["meshes"]) == 1
    document["nodes"][0]["name"] = "M295_Raider_Complete_Ship_Placeholder"
    document["meshes"][0]["name"] = "M295_Raider_Complete_Mesh"

    def mutate(attribute: int, scale: tuple[float, float, float], normals: bool) -> None:
        accessor = document["accessors"][attribute]
        view = document["bufferViews"][accessor["bufferView"]]
        assert accessor["componentType"] == 5126 and accessor["type"] == "VEC3"
        assert "byteStride" not in view
        base = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
        points = []
        for index in range(accessor["count"]):
            offset = base + index * 12
            x, y, z = struct.unpack_from("<fff", binary, offset)
            if normals:
                x, y, z = x / scale[0], y / scale[1], z / scale[2]
                length = math.sqrt(x*x + y*y + z*z)
                x, y, z = x / length, y / length, z / length
            else:
                x, y, z = x * scale[0], y * scale[1], z * scale[2]
            struct.pack_into("<fff", binary, offset, x, y, z)
            points.append((x, y, z))
        if not normals:
            accessor["min"] = [min(point[axis] for point in points) for axis in range(3)]
            accessor["max"] = [max(point[axis] for point in points) for axis in range(3)]

    for primitive in document["meshes"][0]["primitives"]:
        material = document["materials"][primitive["material"]]
        surface = material["name"]
        scale = SHAPE[surface]
        material["pbrMetallicRoughness"]["baseColorFactor"] = PALETTE[surface]
        mutate(primitive["attributes"]["POSITION"], scale, normals=False)
        mutate(primitive["attributes"]["NORMAL"], scale, normals=True)

    json_bytes = json.dumps(document, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
    json_bytes += b" " * (-len(json_bytes) % 4)
    binary += b"\x00" * (-len(binary) % 4)
    package = (
        struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(json_bytes) + 8 + len(binary))
        + struct.pack("<I4s", len(json_bytes), b"JSON") + json_bytes
        + struct.pack("<I4s", len(binary), b"BIN\x00") + binary
    )
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(package)
    return {"path": str(OUTPUT.relative_to(ROOT)), "bytes": len(package), "sha256": hashlib.sha256(package).hexdigest(), "mesh_count": len(document["meshes"]), "node_count": len(document["nodes"])}


if __name__ == "__main__":
    print(json.dumps(create(), sort_keys=True))
