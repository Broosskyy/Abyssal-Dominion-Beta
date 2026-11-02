#!/usr/bin/env python3
"""Inspect original MeshFilter -> GameObject -> Renderer -> Material links."""
import argparse
import json
from pathlib import Path
import UnityPy


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("asset_file", type=Path)
    parser.add_argument("--scene", action="store_true", help="Read cross-file scene renderer links")
    args = parser.parse_args()
    env = UnityPy.load(str(args.asset_file))
    objects = list(env.objects)
    targets = {}
    for obj in objects:
        if obj.type.name == "Mesh":
            name = obj.read().m_Name
            if any(word in name.lower() for word in ["coast", "level2", "leve2", "cannons_left_side_lod3", "lighthouse"]):
                targets[obj.path_id] = name
    if args.scene:
        targets = {945: "Clipper_Leve2_Lod3", 956: "Sails_Level2_Lod2-4", 1031: "island_01_coast5", 1044: "island_04_coast", 966: "snow_island_02_coast"}
    records = []
    for obj in objects:
        if obj.type.name != "MeshFilter":
            continue
        data = obj.read()
        if data.m_Mesh.path_id not in targets:
            continue
        if data.m_Mesh.deref_parse_as_object().m_Name != targets[data.m_Mesh.path_id]:
            continue
        game_object = data.m_GameObject.deref_parse_as_object()
        for component in game_object.m_Component:
            reader = component.component.deref()
            if reader.type.name != "MeshRenderer":
                continue
            renderer = reader.read()
            materials = []
            for pointer in renderer.m_Materials:
                material = pointer.deref()
                tree = material.read_typetree()
                textures = []
                for key, value in tree.get("m_SavedProperties", {}).get("m_TexEnvs", []):
                    ref = value["m_Texture"]
                    if not ref["m_PathID"]:
                        continue
                    textures.append({"property": key, "texture": ref, "scale": value.get("m_Scale"), "offset": value.get("m_Offset")})
                materials.append({"source": material.assets_file.name, "path_id": material.path_id, "name": tree.get("m_Name"), "textures": textures})
            records.append({"game_object": game_object.m_Name, "mesh_path_id": data.m_Mesh.path_id,
                            "mesh": targets[data.m_Mesh.path_id], "materials": materials})
    name = "m12_scene_material_links.json" if args.scene else "m12_original_material_links.json"
    output = Path(__file__).resolve().parents[1] / "docs" / name
    output.write_text(json.dumps(records, indent=2) + "\n")
    print(json.dumps({"records": len(records), "output": str(output)}))


if __name__ == "__main__":
    main()
