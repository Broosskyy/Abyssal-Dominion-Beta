#!/usr/bin/env python3
"""Inventory Unity serialized files without altering the source build.

Produces a machine-readable JSON catalog and a compact CSV suitable for
planning the Godot reconstruction. External .resS/.resource files are resolved
by UnityPy when they sit next to their serialized asset file.
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter
from pathlib import Path
from typing import Any

import UnityPy


SERIALIZED_NAMES = {
    "globalgamemanagers",
    "globalgamemanagers.assets",
    "resources.assets",
    "sharedassets0.assets",
    "sharedassets1.assets",
    "sharedassets2.assets",
    "level0",
    "level1",
    "level2",
}


def asset_files(root: Path) -> list[Path]:
    return sorted(
        path
        for path in root.rglob("*")
        if path.is_file() and path.name in SERIALIZED_NAMES
    )


def safe_name(obj: Any) -> str:
    try:
        value = obj.peek_name()
        if value:
            return str(value)
    except Exception:
        pass
    try:
        data = obj.read()
        return str(getattr(data, "m_Name", "") or "")
    except Exception:
        return ""


def details(obj: Any) -> dict[str, Any]:
    output: dict[str, Any] = {}
    type_name = obj.type.name
    if type_name not in {"Texture2D", "Mesh", "AudioClip", "Sprite", "TextAsset"}:
        return output
    try:
        data = obj.read()
        if type_name == "Texture2D":
            output.update(width=int(data.m_Width), height=int(data.m_Height), format=str(data.m_TextureFormat))
        elif type_name == "Mesh":
            output.update(vertex_count=int(getattr(data, "m_VertexCount", 0)), submesh_count=len(getattr(data, "m_SubMeshes", [])))
        elif type_name == "AudioClip":
            output.update(length_seconds=float(getattr(data, "m_Length", 0.0)), channels=int(getattr(data, "m_Channels", 0)))
        elif type_name == "Sprite":
            rect = getattr(data, "m_Rect", None)
            if rect:
                output.update(width=float(rect.width), height=float(rect.height))
        elif type_name == "TextAsset":
            script = getattr(data, "m_Script", b"")
            output.update(byte_count=len(script))
    except Exception as exc:
        output["detail_error"] = f"{type(exc).__name__}: {exc}"
    return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("--json", dest="json_path", type=Path, required=True)
    parser.add_argument("--csv", dest="csv_path", type=Path, required=True)
    args = parser.parse_args()

    records: list[dict[str, Any]] = []
    errors: list[dict[str, str]] = []
    versions: Counter[str] = Counter()
    for path in asset_files(args.root):
        try:
            env = UnityPy.load(str(path))
            for unity_file in env.files.values():
                version = str(getattr(unity_file, "unity_version", "unknown"))
                versions[version] += 1
            for obj in env.objects:
                record = {
                    "source": str(path.relative_to(args.root)),
                    "type": obj.type.name,
                    "path_id": int(obj.path_id),
                    "name": safe_name(obj),
                    "serialized_byte_size": int(getattr(obj, "byte_size", 0)),
                }
                record.update(details(obj))
                records.append(record)
        except Exception as exc:
            errors.append({"source": str(path.relative_to(args.root)), "error": f"{type(exc).__name__}: {exc}"})

    type_counts = Counter(record["type"] for record in records)
    source_counts = Counter(record["source"] for record in records)
    payload = {
        "schema": 1,
        "root": str(args.root),
        "unity_versions": dict(versions),
        "object_count": len(records),
        "type_counts": dict(type_counts.most_common()),
        "source_counts": dict(source_counts.most_common()),
        "errors": errors,
        "objects": records,
    }
    args.json_path.parent.mkdir(parents=True, exist_ok=True)
    args.json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    fields = ["source", "type", "path_id", "name", "serialized_byte_size", "width", "height", "format", "vertex_count", "submesh_count", "length_seconds", "channels", "byte_count", "detail_error"]
    args.csv_path.parent.mkdir(parents=True, exist_ok=True)
    with args.csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(records)

    print(json.dumps({"objects": len(records), "types": dict(type_counts.most_common(20)), "errors": errors}, ensure_ascii=False, indent=2))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
