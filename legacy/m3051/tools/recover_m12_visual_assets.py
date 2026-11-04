#!/usr/bin/env python3
"""Extract original material-bound Clipper and coast resources for M12."""
import argparse
import hashlib
import json
from pathlib import Path
import UnityPy

ROOT = Path(__file__).resolve().parents[1]
TEXTURES = {"sharedassets1.assets": {653: "clipper_hull", 847: "clipper_sails", 524: "clipper_details"},
            "sharedassets2.assets": {270: "coast_foam"}}
MATERIALS = {"sharedassets1.assets": {344, 345, 346, 347}, "sharedassets2.assets": {53}}
MESHES = {944: "clipper_details", 1181: "clipper_flags"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    output = ROOT / "assets/recovered_test/m12"
    output.mkdir(parents=True, exist_ok=True)
    assets, materials, errors = [], [], []
    for filename, ids in TEXTURES.items():
        env = UnityPy.load(str(args.source / filename))
        for obj in env.objects:
            if obj.assets_file.name != filename:
                continue
            if obj.type.name == "Material" and obj.path_id in MATERIALS[filename]:
                materials.append({"source": filename, "path_id": obj.path_id, "fields": obj.read_typetree()})
            texture = obj.type.name == "Texture2D" and obj.path_id in ids
            mesh = filename == "sharedassets1.assets" and obj.type.name == "Mesh" and obj.path_id in MESHES
            if not texture and not mesh:
                continue
            try:
                data = obj.read()
                if texture:
                    path = output / (ids[obj.path_id] + ".png")
                    data.image.save(path, optimize=True)
                else:
                    path = output / (MESHES[obj.path_id] + ".obj")
                    path.write_text(data.export())
                assets.append({"source": filename, "path_id": obj.path_id, "name": data.m_Name,
                               "type": obj.type.name, "path": str(path.relative_to(ROOT)),
                               "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
            except Exception as exc:
                errors.append({"source": filename, "path_id": obj.path_id, "error": str(exc)})
    report = {"decoder": "UnityPy " + UnityPy.__version__, "assets": assets, "materials": materials, "errors": errors,
              "note": "Material references/properties recovered; Godot shader behavior remains a reimplementation."}
    (ROOT / "docs/m12_recovered_visual_assets.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"assets": assets, "errors": errors}, indent=2))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
