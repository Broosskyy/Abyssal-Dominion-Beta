"""Build three visual-only complete Halloween ship placeholder GLBs.

Original game's complete Raider mesh is reused as the structural source;
different whole-mesh proportions/material palettes produce independently
replaceable ships, never runtime modular hull/sail attachments.
"""
import hashlib
import json
import math
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/production_placeholders/m295/npc_raider_01.glb"
SOURCE_SHA256 = "ce638fe7c8819a9417ae3b1ffe62274c8305b57321c65dd94e82fd50c2e85157"
OUT = ROOT / "assets/production_placeholders/m301"
PALETTES = {
    "event_halloween_npc_sloop_01": {
        "shape": (0.87, 1.08, 0.95),
        "colors": {"deck": (0.22, 0.28, 0.23), "gold": (0.84, 0.43, 0.11), "hull": (0.05, 0.13, 0.13), "iron": (0.1, 0.13, 0.12), "red": (0.27, 0.39, 0.24), "wood": (0.12, 0.23, 0.19)},
    },
    "event_halloween_npc_raider_01": {
        "shape": (1.18, 0.94, 1.08),
        "colors": {"deck": (0.25, 0.16, 0.17), "gold": (0.87, 0.34, 0.07), "hull": (0.12, 0.055, 0.07), "iron": (0.15, 0.10, 0.11), "red": (0.50, 0.15, 0.07), "wood": (0.24, 0.09, 0.08)},
    },
    "event_halloween_ship_design_01": {
        "shape": (1.25, 1.14, 1.16),
        "colors": {"deck": (0.24, 0.21, 0.17), "gold": (0.93, 0.51, 0.10), "hull": (0.07, 0.09, 0.085), "iron": (0.15, 0.18, 0.14), "red": (0.62, 0.28, 0.07), "wood": (0.15, 0.16, 0.12)},
    },
}


def build():
    raw = SOURCE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == SOURCE_SHA256
    magic, version, size = struct.unpack_from("<4sII", raw)
    assert (magic, version, size) == (b"glTF", 2, len(raw))
    length, marker = struct.unpack_from("<I4s", raw, 12)
    assert marker == b"JSON"
    original = json.loads(raw[20:20 + length])
    binary_header = 20 + length
    binary_size, binary_marker = struct.unpack_from("<I4s", raw, binary_header)
    assert binary_marker == b"BIN\x00" and binary_header + 8 + binary_size == len(raw)
    assert len(original["nodes"]) == len(original["meshes"]) == 1
    results = {}
    for ship_id, profile in PALETTES.items():
        document = json.loads(json.dumps(original))
        binary = bytearray(raw[binary_header + 8:])
        document["nodes"][0]["name"] = ship_id + "_Complete"
        document["meshes"][0]["name"] = ship_id + "_Mesh"
        scale = profile["shape"]

        def scale_attribute(accessor_id, normals=False):
            accessor = document["accessors"][accessor_id]
            view = document["bufferViews"][accessor["bufferView"]]
            assert accessor["type"] == "VEC3" and accessor["componentType"] == 5126
            assert "byteStride" not in view
            base = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
            points = []
            for index in range(accessor["count"]):
                offset = base + index * 12
                values = struct.unpack_from("<fff", binary, offset)
                if normals:
                    values = tuple(values[axis] / scale[axis] for axis in range(3))
                    magnitude = math.sqrt(sum(value * value for value in values))
                    values = tuple(value / magnitude for value in values)
                else:
                    values = tuple(values[axis] * scale[axis] for axis in range(3))
                struct.pack_into("<fff", binary, offset, *values)
                points.append(values)
            if not normals:
                accessor["min"] = [min(point[axis] for point in points) for axis in range(3)]
                accessor["max"] = [max(point[axis] for point in points) for axis in range(3)]

        for primitive in document["meshes"][0]["primitives"]:
            surface = document["materials"][primitive["material"]]
            color = profile["colors"][surface["name"]]
            surface["pbrMetallicRoughness"]["baseColorFactor"] = [*color, 1.0]
            scale_attribute(primitive["attributes"]["POSITION"])
            scale_attribute(primitive["attributes"]["NORMAL"], normals=True)

        document_bytes = json.dumps(document, separators=(",", ":"), ensure_ascii=True).encode()
        document_bytes += b" " * (-len(document_bytes) % 4)
        binary += b"\x00" * (-len(binary) % 4)
        contents = (struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(document_bytes) + 8 + len(binary))
                    + struct.pack("<I4s", len(document_bytes), b"JSON") + document_bytes
                    + struct.pack("<I4s", len(binary), b"BIN\x00") + binary)
        OUT.mkdir(parents=True, exist_ok=True)
        path = OUT / (ship_id + ".glb")
        path.write_bytes(contents)
        results[ship_id] = {"path":"res://" + str(path.relative_to(ROOT)), "bytes":len(contents),
                            "sha256":hashlib.sha256(contents).hexdigest(), "meshes":1,"nodes":1}
    return results


if __name__ == "__main__":
    print(json.dumps(build(), sort_keys=True, indent=2))
