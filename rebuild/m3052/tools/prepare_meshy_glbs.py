#!/usr/bin/env python3
"""Prepare Meshy GLBs for Abyssal Dominion without modifying their geometry.

Pass the directory containing the nine original uploaded Meshy GLBs, and the
destination 'rebuild/m3052/assets/npc/meshy/models' directory.
Only embedded PBR image bufferViews are recompressed. Vertex positions,
normals, triangle indices, UVs and other non-image buffers remain bit-identical.
Requires Pillow: python -m pip install Pillow.
"""
from pathlib import Path
from PIL import Image
from io import BytesIO
import hashlib
import json
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
if len(sys.argv) < 2:
    raise SystemExit(
        "Usage: python rebuild/m3052/tools/prepare_meshy_glbs.py "
        "<directory-with-original-meshy-GLBs> [output-model-directory]"
    )
INPUT = Path(sys.argv[1])
OUTPUT = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "assets/npc/meshy/models"
OUTPUT.mkdir(parents=True, exist_ok=True)

NAMES = {
    "old_harbor_trader": "Meshy_AI_Old_Harbor_Trader_1105202956_texture.glb",
    "merchant_brig_3002": "Meshy_AI_Weathered_Merchant_Br_1105203002_texture.glb",
    "merchant_brig_2921": "Meshy_AI_Weathered_Merchant_Br_1105202921_texture.glb",
    "merchant_brig_2912": "Meshy_AI_Weathered_Merchant_Br_1105202912_texture.glb",
    "weathered_voyager": "Meshy_AI_Weathered_Voyager_1105202906_texture.glb",
    "weathered_junk": "Meshy_AI_Weathered_Junk_Ship_1105202938_texture.glb",
    "emerald_voyager": "Meshy_AI_Emerald_Voyager_1105202952_texture.glb",
    "midnight_mariner": "Meshy_AI_Midnight_Mariner_1105202902_texture.glb",
    "crimson_tide_galley": "Meshy_AI_Crimson_Tide_Galley_1105202947_texture.glb",
}

def unpack(raw):
    if raw[:4] != b"glTF" or struct.unpack_from("<I", raw, 4)[0] != 2:
        raise ValueError("GLB v2 required")
    if struct.unpack_from("<I", raw, 8)[0] != len(raw):
        raise ValueError("GLB length mismatch")
    jlen, jtyp = struct.unpack_from("<II", raw, 12)
    if jtyp != 0x4e4f534a:
        raise ValueError("Missing JSON chunk")
    doc = json.loads(raw[20:20+jlen])
    pos = 20+jlen
    blen, btyp = struct.unpack_from("<II", raw, pos)
    if btyp != 0x004e4942:
        raise ValueError("Missing BIN chunk")
    return doc, raw[pos+8:pos+8+blen]

def align4(data, fill=b"\0"):
    return data + fill * ((-len(data)) % 4)

def build(doc, binary):
    doc["buffers"][0]["byteLength"] = len(binary)
    data = align4(json.dumps(doc, separators=(",", ":"), ensure_ascii=False).encode(), b" ")
    binary = align4(binary)
    header = b"glTF" + struct.pack("<II", 2, 12+8+len(data)+8+len(binary))
    return (header + struct.pack("<II", len(data), 0x4e4f534a) + data
            + struct.pack("<II", len(binary), 0x004e4942) + binary)

def signature(doc, binary):
    image_ids = {x["bufferView"] for x in doc.get("images", []) if "bufferView" in x}
    hashed = hashlib.sha256()
    for i, view in enumerate(doc["bufferViews"]):
        if i in image_ids:
            continue
        offset = view.get("byteOffset", 0)
        hashed.update(binary[offset:offset+view["byteLength"]])
    triangles = sum(
        doc["accessors"][p["indices"]]["count"] // 3
        for mesh in doc["meshes"]
        for p in mesh["primitives"]
        if "indices" in p
    )
    return hashed.hexdigest(), triangles

def optimize(source, destination):
    raw = source.read_bytes()
    doc, binary = unpack(raw)
    before_hash, triangles = signature(doc, binary)
    if triangles < 28000:
        raise ValueError(f"Geometry already reduced or damaged: {source.name}, {triangles} triangles")
    images = {
        image["bufferView"]: image for image in doc.get("images", [])
        if "bufferView" in image
    }
    rewritten = bytearray()
    textures = []
    for i, view in enumerate(doc["bufferViews"]):
        offset = view.get("byteOffset", 0)
        data = binary[offset:offset+view["byteLength"]]
        if i in images:
            image = images[i]
            name = image.get("name", "").lower()
            picture = Image.open(BytesIO(data))
            if "normal" in name:
                target, fmt, mode = 768, "PNG", "normal"
            elif "roughness" in name or "metallic" in name:
                target, fmt, mode = 512, "PNG", "pbr"
            else:
                target, fmt, mode = 1024, "JPEG", "albedo"
            # Retain texture alpha instead of flattening cut-outs and rigging.
            if "A" in picture.getbands():
                fmt = "PNG"
                picture = picture.convert("RGBA")
            else:
                picture = picture.convert("RGB")
            if max(picture.size) > target:
                picture.thumbnail((target, target), Image.Resampling.LANCZOS)
            output = BytesIO()
            if fmt == "PNG":
                picture.save(output, format=fmt, optimize=True, compress_level=7)
            else:
                picture.save(output, format=fmt, quality=94, subsampling=0, optimize=True)
            data = output.getvalue()
            image["mimeType"] = "image/png" if fmt == "PNG" else "image/jpeg"
            textures.append({"slot": mode, "size": list(picture.size), "bytes": len(data)})
        rewritten.extend(bytes((-len(rewritten)) % 4))
        view["byteOffset"] = len(rewritten)
        view["byteLength"] = len(data)
        rewritten.extend(data)
    result = build(doc, rewritten)
    rebuilt_doc, rebuilt_binary = unpack(result)
    after_hash, after_triangles = signature(rebuilt_doc, rebuilt_binary)
    if (before_hash, triangles) != (after_hash, after_triangles):
        raise AssertionError(f"Model geometry changed: {source.name}")
    destination.write_bytes(result)
    return {
        "file": destination.name,
        "original": source.name,
        "triangles": triangles,
        "geometry_sha256": before_hash,
        "bytes_before": len(raw),
        "bytes_after": len(result),
        "textures": textures,
    }

manifest = {"schema": 2, "geometry_preserved": True, "mesh_decimation": False, "models": []}
for key, filename in NAMES.items():
    original = INPUT / filename
    if not original.is_file():
        raise FileNotFoundError(original)
    manifest["models"].append(optimize(original, OUTPUT / (key + ".glb")))
(OUTPUT.parent / "geometry_validation.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(json.dumps({
    "count": len(manifest["models"]),
    "source_mb": round(sum(x["bytes_before"] for x in manifest["models"]) / 1e6, 2),
    "output_mb": round(sum(x["bytes_after"] for x in manifest["models"]) / 1e6, 2),
    "triangles": [x["triangles"] for x in manifest["models"]],
}, indent=2))
