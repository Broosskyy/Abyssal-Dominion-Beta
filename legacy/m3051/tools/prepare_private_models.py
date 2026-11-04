"""Export selected source meshes for transparent offline Godot rasterization.

Input is the safely unpacked Unity resource directory. Output must stay private.
No thumbnails or UV layouts are represented as multidirectional ship sprites.
"""
import argparse
import json
from pathlib import Path

import UnityPy
from unity_graphics_audit import save_png_atomic

PAIRS = {
    "elite_8": ("elite_8_textura", "ships/sob_elite8.png"),
    "elite_2": ("elite_2_textura", "ships/sob_elite2.png"),
    "elite_6": ("elite_6_textura", "ships/sob_elite6.png"),
    "12_kraken": ("12_kraken_textura", "monsters/kraken.png"),
    "island": ("island_texture", "islands/tropical.png"),
    "isla_invierno_01": ("isla_invierno_01_textura", "islands/snow.png"),
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source_directory", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    paths = [p for p in args.source_directory.rglob("*.unity3d") if not p.name.startswith(".")]
    env = UnityPy.load(*(str(p) for p in paths))
    textures, meshes = {}, {}
    for obj in env.objects:
        if obj.type.name not in ("Mesh", "Texture2D"):
            continue
        data = obj.read()
        name = str(getattr(data, "m_Name", "")).casefold()
        if obj.type.name == "Mesh" and name in PAIRS:
            meshes[name] = data
        elif obj.type.name == "Texture2D" and name in {v[0] for v in PAIRS.values()}:
            textures[name] = data
    args.output.mkdir(parents=True, exist_ok=True)
    result = []
    for name, (texture, slot) in PAIRS.items():
        if name not in meshes or texture not in textures:
            result.append({"name": name, "status": "missing", "mesh": name in meshes, "texture": texture in textures})
            continue
        obj = meshes[name].export()
        if not obj:
            result.append({"name": name, "status": "failed", "reason": "empty OBJ"})
            continue
        (args.output / f"{name}.obj").write_text(obj, encoding="utf-8")
        save_png_atomic(textures[texture].image.convert("RGBA"), args.output / f"{name}.png")
        result.append({"name": name, "status": "ready", "mesh": f"{name}.obj", "albedo": f"{name}.png", "slot": slot,
                       "frames": 8 if slot.startswith("ships/") else 1,
                       "texture_mapping": "explicit source name pair; not full Unity material recreation"})
    (args.output / "models.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result), flush=True)


if __name__ == "__main__":
    main()
