"""Reproducibly bake Scout and Heavy NPC placeholder silhouettes into whole GLBs.

Each output has one node and one mesh. Shapes are placeholder geometry inside
the model, never runtime hull/mast modules or collision and gameplay changes.
"""

import hashlib
import json
from pathlib import Path
import struct

from m296_build_npc_glbs import _boxes, _morph


ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/production_placeholders/m297"
IDENTITIES = {
    "npc_scout_01": {
        "source_sha256": "736cfebb4ac521f3ae00c75e44f3930d2b2a48eab07f3724d388e8d92a1e8c00",
        "original_triangles": 1655,
        "shape": {"hull": (0.91, 0.96, 1.08), "wood": (0.95, 0.97, 1.07),
                  "deck": (0.96, 0.98, 1.07), "gold": (0.96, 0.98, 1.07),
                  "iron": (0.97, 0.98, 1.05), "red": (0.90, 0.94, 1.02)},
        "palette": {"hull": [0.09, 0.14, 0.17, 1], "wood": [0.29, 0.23, 0.17, 1],
                    "deck": [0.40, 0.34, 0.25, 1], "gold": [0.56, 0.49, 0.31, 1],
                    "iron": [0.12, 0.18, 0.20, 1], "red": [0.63, 0.64, 0.56, 1]},
        "details": {
            "wood": [((0, 0.87, 1.84), (0.98, 0.26, 0.67)),
                     ((0, 0.79, -1.96), (0.91, 0.23, 0.58)),
                     ((0, 0.79, 4.13), (0.16, 0.16, 1.18))],
            "red": [((0, 3.88, 0.3), (0.51, 0.24, 0.035))],
        },
    },
    "npc_heavy_01": {
        "source_sha256": "c46ff6c449cbd117b3f1c9f2cc8aa0c5a4de6df3cdfc92d3e44bf6c54d6d055d",
        "original_triangles": 2127,
        "shape": {"hull": (1.15, 1.08, 1.04), "wood": (1.12, 1.06, 1.04),
                  "deck": (1.13, 1.05, 1.03), "gold": (1.13, 1.05, 1.03),
                  "iron": (1.08, 1.03, 1.05), "red": (1.08, 1.00, 1.04)},
        "palette": {"hull": [0.070, 0.068, 0.064, 1], "wood": [0.23, 0.18, 0.14, 1],
                    "deck": [0.34, 0.29, 0.24, 1], "gold": [0.54, 0.43, 0.25, 1],
                    "iron": [0.12, 0.12, 0.13, 1], "red": [0.33, 0.28, 0.24, 1]},
        "details": {
            "wood": [((0, 0.90, -2.33), (2.22, 0.48, 0.94)),
                     ((0, 0.82, 2.18), (1.99, 0.39, 0.92)),
                     ((0, 1.37, -2.33), (1.69, 0.31, 0.81)),
                     ((0, 1.70, -2.49), (1.25, 0.20, 0.38))],
            "iron": [((side * 1.35, 0.84, 0), (0.13, 0.25, 3.30)) for side in (-1, 1)],
            "red": [((0, 4.27, 0.30), (0.63, 0.25, 0.035))],
        },
    },
}


def build(name, identity):
    source = ROOT / "assets/production_placeholders/p0" / (name + ".glb")
    original = source.read_bytes()
    assert hashlib.sha256(original).hexdigest() == identity["source_sha256"]
    assert struct.unpack_from("<4sII", original) == (b"glTF", 2, len(original))
    json_len, kind = struct.unpack_from("<I4s", original, 12)
    assert kind == b"JSON"
    document = json.loads(original[20:20 + json_len])
    bin_len, kind = struct.unpack_from("<I4s", original, 20 + json_len)
    assert kind == b"BIN\x00" and 28 + json_len + bin_len == len(original)
    assert len(document["nodes"]) == len(document["meshes"]) == 1
    buffer = bytearray(original[28 + json_len:])
    document["nodes"][0]["name"] = "M297_" + name + "_Complete_Ship"
    document["meshes"][0]["name"] = "M297_" + name + "_Baked_Mesh"
    materials = {m["name"]: i for i, m in enumerate(document["materials"])}
    for primitive in document["meshes"][0]["primitives"]:
        surface = document["materials"][primitive["material"]]["name"]
        document["materials"][primitive["material"]]["pbrMetallicRoughness"]["baseColorFactor"] = identity["palette"][surface]
        _morph(document, buffer, primitive, identity["shape"][surface])
    for surface, boxes in identity["details"].items():
        _boxes(document, buffer, materials[surface], boxes)
    document["buffers"][0]["byteLength"] = len(buffer)
    encoded = json.dumps(document, separators=(",", ":"), ensure_ascii=True).encode()
    encoded += b" " * (-len(encoded) % 4)
    buffer += b"\x00" * (-len(buffer) % 4)
    raw = (struct.pack("<4sII", b"glTF", 2, 28 + len(encoded) + len(buffer)) +
           struct.pack("<I4s", len(encoded), b"JSON") + encoded +
           struct.pack("<I4s", len(buffer), b"BIN\x00") + buffer)
    DEST.mkdir(parents=True, exist_ok=True)
    output = DEST / (name + ".glb")
    output.write_bytes(raw)
    return {"id": name, "path": "res://" + str(output.relative_to(ROOT)),
            "sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw),
            "surfaces": len(document["meshes"][0]["primitives"]),
            "triangles": identity["original_triangles"] + sum(len(v)*12 for v in identity["details"].values())}


if __name__ == "__main__":
    print(json.dumps([build(name, identity) for name, identity in IDENTITIES.items()], indent=2))
