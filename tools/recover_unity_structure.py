#!/usr/bin/env python3
"""Recover scene structure and raw MonoBehaviour headers from Unity files."""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path
from typing import Any

import UnityPy

from inventory_unity_build import asset_files


def vector(value: Any) -> dict[str, float] | None:
    if value is None:
        return None
    return {key: float(getattr(value, key)) for key in ("x", "y", "z") if hasattr(value, key)}


def pointer(value: Any) -> dict[str, int]:
    return {"file_id": int(getattr(value, "file_id", 0)), "path_id": int(getattr(value, "path_id", 0))}


def script_row(data: Any) -> dict[str, str]:
    return {
        "name": str(getattr(data, "m_Name", "") or ""),
        "class": str(getattr(data, "m_ClassName", "") or ""),
        "namespace": str(getattr(data, "m_Namespace", "") or ""),
        "assembly": str(getattr(data, "m_AssemblyName", "") or ""),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    sources: dict[str, tuple[Path, Any]] = {}
    script_map: dict[tuple[str, int], dict[str, str]] = {}
    for path in asset_files(args.root):
        env = UnityPy.load(str(path))
        serialized = next(iter(env.files.values()))
        sources[path.name] = (path, serialized)
        for obj in env.objects:
            if obj.type.name == "MonoScript":
                try:
                    script_map[(path.name, int(obj.path_id))] = script_row(obj.read())
                except Exception:
                    pass

    scene_objects: list[dict[str, Any]] = []
    behaviours: list[dict[str, Any]] = []
    for source_name, (path, serialized) in sources.items():
        external = {index: item.name for index, item in enumerate(serialized.externals, 1)}
        env = UnityPy.load(str(path))
        for obj in env.objects:
            kind = obj.type.name
            if kind == "GameObject":
                try:
                    data = obj.read()
                    scene_objects.append({
                        "source": source_name,
                        "type": kind,
                        "path_id": int(obj.path_id),
                        "name": str(data.m_Name),
                        "layer": int(getattr(data, "m_Layer", 0)),
                        "active": bool(getattr(data, "m_IsActive", True)),
                        "components": [pointer(getattr(item, "component", item)) for item in getattr(data, "m_Component", [])],
                    })
                except Exception:
                    pass
            elif kind in {"Transform", "RectTransform"}:
                try:
                    data = obj.read()
                    scene_objects.append({
                        "source": source_name,
                        "type": kind,
                        "path_id": int(obj.path_id),
                        "game_object": pointer(data.m_GameObject),
                        "father": pointer(data.m_Father),
                        "children": [pointer(item) for item in data.m_Children],
                        "local_position": vector(getattr(data, "m_LocalPosition", None)),
                        "local_scale": vector(getattr(data, "m_LocalScale", None)),
                    })
                except Exception:
                    pass
            elif kind == "MonoBehaviour":
                raw = obj.get_raw_data()
                if len(raw) < 28:
                    continue
                game_file, game_path = struct.unpack_from("<iq", raw, 0)
                enabled = bool(raw[12])
                script_file, script_path = struct.unpack_from("<iq", raw, 16)
                script_source = source_name if script_file == 0 else external.get(script_file, f"external_{script_file}")
                behaviours.append({
                    "source": source_name,
                    "path_id": int(obj.path_id),
                    "byte_size": len(raw),
                    "sha256": __import__("hashlib").sha256(raw).hexdigest(),
                    "enabled": enabled,
                    "game_object": {"file_id": game_file, "path_id": game_path},
                    "script_pointer": {"file_id": script_file, "path_id": script_path, "source": script_source},
                    "script": script_map.get((script_source, script_path)),
                })

    (args.output / "scene_structure.json").write_text(json.dumps(scene_objects, ensure_ascii=False, indent=2), encoding="utf-8")
    (args.output / "mono_behaviour_headers.json").write_text(json.dumps(behaviours, ensure_ascii=False, indent=2), encoding="utf-8")
    (args.output / "script_types.json").write_text(json.dumps(list(script_map.values()), ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"scene_records": len(scene_objects), "behaviour_headers": len(behaviours), "script_types": len(script_map)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
