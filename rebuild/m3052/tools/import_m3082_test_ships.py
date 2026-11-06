#!/usr/bin/env python3
"""Import two user-uploaded M3082 ZIPs: full 3D GLBs + original-GLB 2D views.

Only processes the fixed, signed-off archive paths and checksums. Never
decimates geometry; never replaces the existing nine NPC GLBs.
"""
from __future__ import annotations

import hashlib
import json
import pathlib
import struct
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[3]
OUTPUT = ROOT / "rebuild/m3052/assets/player/test_ships"
PARTS = [ROOT / f"Abyssal_Dominion_M3082_Testschiffe_Teil_{i}_von_2.zip" for i in (1, 2)]
PREFIX = "rebuild/m3052/assets/player/test_ships/"
SOURCE = {
    "crimson_voyager": ("9e07b8d95eed9381985ffea9e746575abee465461d114f124eae9e33ca3d3375", 29513),
    "test_ship_2": ("d4e8351735b777f35a2019dac1de519ab8b4fb70ee47bb4e626a8a923c2572db", 30724),
    "base_basic_pbr": ("bc672495d28a794617fb8270e4f4d4248c6cc15019e70e986720ad24970faf83", 30795),
}
SPRITE_HASH = {
    "crimson_voyager": "1c728d59b3b2c17d67dcc09ddb7d2b2ec00ce587d960abf8c359bb1fb057f9ac",
    "test_ship_2": "db35418ec754cec154a6e3cc03d0e945d7ee1ef508be3fc9b6316a459633c53d",
    "base_basic_pbr": "09b5c158db5291acf54f77f2c9870fabad149c80e167d409fbf39428ab137e28",
}
ALLOWED = {f"{key}{suffix}" for key in SOURCE for suffix in (".glb", "_eight.png", "_preview.png")}
ALLOWED.update(("ship_frames.json", "manifest.json"))


def analyze_glb(raw: bytes, expected_tris: int):
    if len(raw) < 64 or raw[:4] != b"glTF":
        raise RuntimeError("Missing GLB header")
    if struct.unpack_from("<I", raw, 4)[0] != 2 or struct.unpack_from("<I", raw, 8)[0] != len(raw):
        raise RuntimeError("Incorrect GLB version/length")
    length, chunk = struct.unpack_from("<II", raw, 12)
    if chunk != 0x4E4F534A:
        raise RuntimeError("GLB JSON chunk missing")
    doc = json.loads(raw[20:20 + length])
    tris = sum(doc["accessors"][primitive["indices"]]["count"] // 3
               for mesh in doc["meshes"] for primitive in mesh["primitives"]
               if "indices" in primitive)
    if tris != expected_tris:
        raise RuntimeError(f"GLB mesh mismatch: {tris} triangles expected {expected_tris}")


def main():
    if not all(p.exists() for p in PARTS):
        raise RuntimeError("Both uploads are required; run again after uploading both ZIP parts")
    buffers: dict[str, bytes] = {}
    for path in PARTS:
        if path.stat().st_size >= 25_000_000:
            raise RuntimeError(f"Archive exceeds the 25MB budget: {path.name}")
        with zipfile.ZipFile(path) as z:
            if z.testzip() is not None:
                raise RuntimeError(f"Bad ZIP CRC: {path.name}")
            for item in z.infolist():
                if item.is_dir():
                    continue
                if not item.filename.startswith(PREFIX):
                    raise RuntimeError(f"Unexpected path in archive: {item.filename}")
                name = item.filename[len(PREFIX):]
                if name not in ALLOWED or name in buffers or "/" in name or "\\" in name:
                    raise RuntimeError(f"Unexpected/duplicate asset: {name}")
                buffers[name] = z.read(item)
    if set(buffers) != ALLOWED:
        raise RuntimeError(f"Missing assets: {sorted(ALLOWED - set(buffers))}; extra: {sorted(set(buffers) - ALLOWED)}")
    manifest = json.loads(buffers["manifest.json"])
    frames = json.loads(buffers["ship_frames.json"])
    if set(manifest) != set(SOURCE):
        raise RuntimeError("Unexpected metadata ship keys")
    if set(frames["entries"]) != {f"assets/player/test_ships/{key}_eight.png" for key in SOURCE}:
        raise RuntimeError("Not every playable ship has a classic eight-direction sheet")
    for key, (sha, triangles) in SOURCE.items():
        glb = buffers[key + ".glb"]
        if hashlib.sha256(glb).hexdigest() != sha or sha != manifest[key]["glb_sha256"]:
            raise RuntimeError(f"Original GLB checksum mismatch: {key}")
        analyze_glb(glb, triangles)
        sprite = buffers[key + "_eight.png"]
        if hashlib.sha256(sprite).hexdigest() != SPRITE_HASH[key]:
            raise RuntimeError(f"Eight-angle sprite checksum mismatch: {key}")
        for name, size in ((key + "_eight.png", (2560, 320)), (key + "_preview.png", (510, 360))):
            raw = buffers[name]
            if raw[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack_from(">II", raw, 16) != size:
                raise RuntimeError(f"Invalid PNG dimensions: {name}")
        entries = frames["entries"][f"assets/player/test_ships/{key}_eight.png"]["frames"]
        if len(entries) != 8:
            raise RuntimeError(f"Not eight view frames: {key}")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, raw in buffers.items():
        (OUTPUT / name).write_bytes(raw)
    print("M3082_PLAYER_MODELS_IMPORTED", len(SOURCE), "full original GLBs and six rendered textures")
    print("M3082_PLAYER_MODEL_TOTAL_MB", round(sum(len(v) for v in buffers.values()) / 1_000_000, 2))


if __name__ == "__main__":
    main()
