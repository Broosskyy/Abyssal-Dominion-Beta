"""Build two distinct complete, replaceable M296 NPC placeholder ships.

The source is the existing whole scout mesh. Shape/material edits and simple
authored placeholder details are baked into one mesh in each exported GLB;
there are no runtime ship-part nodes, physics shapes or gameplay metadata.
"""

import hashlib
import json
import math
from pathlib import Path
import struct


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/production_placeholders/p0/npc_scout_01.glb"
SOURCE_SHA256 = "736cfebb4ac521f3ae00c75e44f3930d2b2a48eab07f3724d388e8d92a1e8c00"
DEST = ROOT / "assets/production_placeholders/m296"

IDENTITIES = {
    "npc_friendly_coastal_sloop": {
        "scale": {"hull": (0.83, 0.88, 0.84), "wood": (0.89, 0.88, 0.86),
                  "iron": (0.92, 0.91, 0.87), "red": (0.93, 0.89, 0.85)},
        "colors": {"hull": [0.11, 0.19, 0.23, 1], "wood": [0.39, 0.31, 0.20, 1],
                   "deck": [0.57, 0.47, 0.31, 1], "gold": [0.62, 0.58, 0.38, 1],
                   "iron": [0.20, 0.29, 0.29, 1], "red": [0.79, 0.76, 0.63, 1]},
        "details": {"wood": [((0, 0.82, -1.7), (1.20, 0.28, 0.75))]},
    },
    "npc_gunship_01": {
        "scale": {"hull": (1.45, 1.10, 0.98), "wood": (1.32, 1.08, 0.99),
                  "deck": (1.34, 1.06, 0.99), "gold": (1.36, 1.08, 0.99),
                  "iron": (1.20, 1.00, 1.02), "red": (1.12, 0.92, 1.05)},
        "colors": {"hull": [0.095, 0.092, 0.080, 1], "wood": [0.26, 0.20, 0.15, 1],
                   "deck": [0.36, 0.29, 0.22, 1], "gold": [0.57, 0.43, 0.24, 1],
                   "iron": [0.085, 0.105, 0.115, 1], "red": [0.26, 0.23, 0.18, 1]},
        "details": {
            "wood": [((0, 0.83, -0.1), (2.45, 0.18, 3.1)),
                     ((0, 1.08, -2.1), (1.75, 0.36, 0.52))],
            "iron": [((side * 1.36, 0.89, 0), (0.18, 0.43, 3.5))
                     for side in (-1, 1)] +
                    [((side * 1.48, 0.81, z), (0.30, 0.18, 0.48))
                     for side in (-1, 1) for z in (-1.05, 0, 1.05)],
        },
    },
}


def _source():
    raw = SOURCE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == SOURCE_SHA256
    assert struct.unpack_from("<4sII", raw) == (b"glTF", 2, len(raw))
    json_len, kind = struct.unpack_from("<I4s", raw, 12)
    assert kind == b"JSON"
    document = json.loads(raw[20:20 + json_len])
    bin_len, bin_kind = struct.unpack_from("<I4s", raw, 20 + json_len)
    assert bin_kind == b"BIN\x00" and 28 + json_len + bin_len == len(raw)
    assert len(document["nodes"]) == len(document["meshes"]) == 1
    return document, bytearray(raw[28 + json_len:])


def _morph(doc, buffer, primitive, scale):
    for attribute, is_normal in (("POSITION", False), ("NORMAL", True)):
        accessor = doc["accessors"][primitive["attributes"][attribute]]
        view = doc["bufferViews"][accessor["bufferView"]]
        assert accessor["type"] == "VEC3" and accessor["componentType"] == 5126
        assert "byteStride" not in view
        offset = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
        values = []
        for index in range(accessor["count"]):
            at = offset + 12 * index
            xyz = struct.unpack_from("<fff", buffer, at)
            xyz = [xyz[axis] / scale[axis] if is_normal else xyz[axis] * scale[axis]
                   for axis in range(3)]
            if is_normal:
                length = math.sqrt(sum(component * component for component in xyz))
                xyz = [component / length for component in xyz]
            struct.pack_into("<fff", buffer, at, *xyz)
            values.append(xyz)
        if not is_normal:
            accessor["min"] = [min(v[axis] for v in values) for axis in range(3)]
            accessor["max"] = [max(v[axis] for v in values) for axis in range(3)]


def _boxes(doc, buffer, material_id, boxes):
    # Per-face vertices preserve hard-edged normals on baked hull detail.
    positions, normals, indices = [], [], []
    faces = [((0, 0, 1), (0, 1, 2, 3)), ((0, 0, -1), (4, 7, 6, 5)),
             ((1, 0, 0), (1, 5, 6, 2)), ((-1, 0, 0), (4, 0, 3, 7)),
             ((0, 1, 0), (3, 2, 6, 7)), ((0, -1, 0), (4, 5, 1, 0))]
    for center, size in boxes:
        cx, cy, cz = center
        sx, sy, sz = (v / 2 for v in size)
        corners = [(cx - sx, cy - sy, cz + sz), (cx + sx, cy - sy, cz + sz),
                   (cx + sx, cy + sy, cz + sz), (cx - sx, cy + sy, cz + sz),
                   (cx - sx, cy - sy, cz - sz), (cx + sx, cy - sy, cz - sz),
                   (cx + sx, cy + sy, cz - sz), (cx - sx, cy + sy, cz - sz)]
        for normal, corner_ids in faces:
            start = len(positions)
            positions.extend(corners[i] for i in corner_ids)
            normals.extend([normal] * 4)
            indices.extend(start + i for i in (0, 1, 2, 0, 2, 3))
    assert len(positions) < 65536

    def accessor(values, fmt, component_type, kind, bounds=False):
        buffer.extend(b"\x00" * (-len(buffer) % 4))
        start = len(buffer)
        for row in values:
            buffer.extend(struct.pack(fmt, *row))
        view_id = len(doc["bufferViews"])
        doc["bufferViews"].append({"buffer": 0, "byteOffset": start,
                                    "byteLength": len(buffer) - start})
        result = {"bufferView": view_id, "componentType": component_type,
                  "count": len(values), "type": kind}
        if bounds:
            result["min"] = [min(v[axis] for v in values) for axis in range(3)]
            result["max"] = [max(v[axis] for v in values) for axis in range(3)]
        doc["accessors"].append(result)
        return len(doc["accessors"]) - 1

    pos = accessor(positions, "<fff", 5126, "VEC3", bounds=True)
    nor = accessor(normals, "<fff", 5126, "VEC3")
    idx = accessor([(v,) for v in indices], "<H", 5123, "SCALAR")
    doc["meshes"][0]["primitives"].append({"attributes": {"POSITION": pos, "NORMAL": nor},
                                           "indices": idx, "material": material_id, "mode": 4})


def build(name, identity):
    document, binary = _source()
    document["nodes"][0]["name"] = "M296_" + name + "_Complete_Ship"
    document["meshes"][0]["name"] = "M296_" + name + "_Baked_Mesh"
    materials = {m["name"]: i for i, m in enumerate(document["materials"])}
    for primitive in document["meshes"][0]["primitives"]:
        surface = document["materials"][primitive["material"]]["name"]
        document["materials"][primitive["material"]]["pbrMetallicRoughness"]["baseColorFactor"] = identity["colors"][surface]
        _morph(document, binary, primitive, identity["scale"].get(surface, (1, 1, 1)))
    for surface, boxes in identity["details"].items():
        _boxes(document, binary, materials[surface], boxes)
    document["buffers"][0]["byteLength"] = len(binary)
    encoded = json.dumps(document, separators=(",", ":"), ensure_ascii=True).encode()
    encoded += b" " * (-len(encoded) % 4)
    binary += b"\x00" * (-len(binary) % 4)
    raw = (struct.pack("<4sII", b"glTF", 2, 28 + len(encoded) + len(binary)) +
           struct.pack("<I4s", len(encoded), b"JSON") + encoded +
           struct.pack("<I4s", len(binary), b"BIN\x00") + binary)
    DEST.mkdir(parents=True, exist_ok=True)
    target = DEST / (name + ".glb")
    target.write_bytes(raw)
    return {"id": name, "path": "res://" + str(target.relative_to(ROOT)),
            "sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw),
            "surfaces": len(document["meshes"][0]["primitives"]),
            "triangles": 1655 + sum(len(boxes) * 12 for boxes in identity["details"].values())}


if __name__ == "__main__":
    print(json.dumps([build(name, identity) for name, identity in IDENTITIES.items()], indent=2))
