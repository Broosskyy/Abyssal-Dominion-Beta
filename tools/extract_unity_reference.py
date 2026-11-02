#!/usr/bin/env python3
"""Extract Godot-readable reference assets from a supplied Unity build.

The output is intentionally reference-only. It is not copied into release
exports and keeps source/path identifiers for traceability.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import re
from pathlib import Path
from typing import Any

import UnityPy

from inventory_unity_build import asset_files


def clean(value: str, fallback: str) -> str:
    value = re.sub(r"[^A-Za-z0-9._-]+", "_", value.strip()).strip("._")
    return value[:100] or fallback


def write_unique(folder: Path, stem: str, suffix: str, payload: bytes, path_id: int) -> tuple[Path, str]:
    digest = hashlib.sha256(payload).hexdigest()
    folder.mkdir(parents=True, exist_ok=True)
    candidate = folder / f"{clean(stem, 'unnamed')}__{path_id}{suffix}"
    candidate.write_bytes(payload)
    return candidate, digest


def json_safe(value: Any, depth: int = 0) -> Any:
    if depth > 12:
        return "<depth-limit>"
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, bytes):
        return {"byte_count": len(value), "sha256": hashlib.sha256(value).hexdigest()}
    if isinstance(value, dict):
        return {str(k): json_safe(v, depth + 1) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [json_safe(v, depth + 1) for v in value]
    if hasattr(value, "path_id"):
        return {"path_id": int(getattr(value, "path_id", 0)), "file_id": int(getattr(value, "file_id", 0))}
    if hasattr(value, "__dict__"):
        return {str(k): json_safe(v, depth + 1) for k, v in vars(value).items() if not str(k).startswith("_")}
    return str(value)


def script_identity(data: Any) -> dict[str, str]:
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

    manifest: list[dict[str, Any]] = []
    scripts: list[dict[str, Any]] = []
    behaviours: list[dict[str, Any]] = []
    errors: list[dict[str, Any]] = []

    for source in asset_files(args.root):
        relative_source = str(source.relative_to(args.root))
        try:
            env = UnityPy.load(str(source))
        except Exception as exc:
            errors.append({"source": relative_source, "error": f"load: {type(exc).__name__}: {exc}"})
            continue

        for obj in env.objects:
            type_name = obj.type.name
            if type_name not in {"Texture2D", "Sprite", "Mesh", "AudioClip", "TextAsset", "MonoScript", "MonoBehaviour", "Material", "AnimationClip"}:
                continue
            try:
                data = obj.read()
                name = str(getattr(data, "m_Name", "") or type_name)
                base = {"source": relative_source, "type": type_name, "path_id": int(obj.path_id), "name": name}

                if type_name in {"Texture2D", "Sprite"}:
                    image = data.image
                    buffer = io.BytesIO()
                    image.save(buffer, format="PNG", optimize=True)
                    path, digest = write_unique(args.output / "textures" / type_name.lower(), name, ".png", buffer.getvalue(), obj.path_id)
                    base.update(path=str(path.relative_to(args.output)), sha256=digest, width=image.width, height=image.height)
                    manifest.append(base)
                elif type_name == "Mesh":
                    exported = data.export()
                    payload = exported.encode("utf-8") if isinstance(exported, str) else bytes(exported)
                    path, digest = write_unique(args.output / "meshes", name, ".obj", payload, obj.path_id)
                    base.update(path=str(path.relative_to(args.output)), sha256=digest)
                    manifest.append(base)
                elif type_name == "AudioClip":
                    for sample_name, payload in data.samples.items():
                        suffix = Path(sample_name).suffix or ".wav"
                        stem = Path(sample_name).stem or name
                        path, digest = write_unique(args.output / "audio", stem, suffix, payload, obj.path_id)
                        item = dict(base)
                        item.update(path=str(path.relative_to(args.output)), sha256=digest)
                        manifest.append(item)
                elif type_name == "TextAsset":
                    payload = data.m_Script if isinstance(data.m_Script, bytes) else str(data.m_Script).encode("utf-8")
                    path, digest = write_unique(args.output / "text", name, ".txt", payload, obj.path_id)
                    base.update(path=str(path.relative_to(args.output)), sha256=digest)
                    manifest.append(base)
                elif type_name == "MonoScript":
                    item = dict(base)
                    item.update(script_identity(data))
                    scripts.append(item)
                elif type_name == "MonoBehaviour":
                    item = dict(base)
                    try:
                        script = data.m_Script.get_obj().read()
                        item["script"] = script_identity(script)
                    except Exception:
                        item["script"] = None
                    try:
                        item["fields"] = json_safe(obj.read_typetree())
                    except Exception as exc:
                        item["fields_error"] = f"{type(exc).__name__}: {exc}"
                    behaviours.append(item)
                else:
                    try:
                        tree = json_safe(obj.read_typetree())
                    except Exception:
                        tree = json_safe(vars(data))
                    folder = "materials" if type_name == "Material" else "animations"
                    payload = json.dumps(tree, ensure_ascii=False, indent=2).encode("utf-8")
                    path, digest = write_unique(args.output / folder, name, ".json", payload, obj.path_id)
                    base.update(path=str(path.relative_to(args.output)), sha256=digest)
                    manifest.append(base)
            except Exception as exc:
                errors.append({"source": relative_source, "type": type_name, "path_id": int(obj.path_id), "error": f"{type(exc).__name__}: {exc}"})

    (args.output / "manifest.json").write_text(json.dumps({"schema": 1, "assets": manifest, "errors": errors}, ensure_ascii=False, indent=2), encoding="utf-8")
    (args.output / "mono_scripts.json").write_text(json.dumps(scripts, ensure_ascii=False, indent=2), encoding="utf-8")
    (args.output / "mono_behaviours.json").write_text(json.dumps(behaviours, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"assets": len(manifest), "scripts": len(scripts), "behaviours": len(behaviours), "errors": len(errors)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
