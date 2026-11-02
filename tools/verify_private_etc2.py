"""Compare every ETC2_RGBA8 source texture with native Godot decompression."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

import numpy as np
from PIL import Image
import UnityPy


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source_directory", type=Path)
    parser.add_argument("audit_directory", type=Path)
    parser.add_argument("work_directory", type=Path)
    parser.add_argument("godot", type=Path)
    args = parser.parse_args()
    report = json.loads((args.audit_directory / "scan_report.json").read_text())
    textures = [x for x in report["resources"] if x.get("format") == "ETC2_RGBA8"]
    wanted = {x["id"]: x for x in textures}
    paths = []
    for name in sorted({x["serialized_file"] for x in textures}):
        choices = list(args.source_directory.rglob(name)) or list(args.source_directory.rglob(name + ".split0"))
        if len(choices) != 1:
            raise ValueError(f"Ambiguous/missing serialized file: {name}")
        paths.append(str(choices[0]))
    env = UnityPy.load(*paths)
    args.work_directory.mkdir(parents=True, exist_ok=True)
    entries = []
    for obj in env.objects:
        key = f"{obj.assets_file.name}:{obj.path_id}"
        if obj.type.name != "Texture2D" or key not in wanted:
            continue
        row = wanted[key]
        data = obj.read()
        size = ((row["width"] + 3) // 4) * ((row["height"] + 3) // 4) * 16
        payload = data.get_image_data()[:size]
        if len(payload) != size:
            raise ValueError(f"Truncated ETC2 payload: {key}")
        stem = hashlib.sha256(key.encode()).hexdigest()[:16]
        (args.work_directory / (stem + ".bin")).write_bytes(payload)
        entries.append({"id": key, "name": row["name"], "width": row["width"], "height": row["height"],
                        "png": row["png"], "payload": stem + ".bin", "native_rgba": stem + ".rgba"})
    if len(entries) != len(textures):
        raise ValueError("Not every source ETC2 object was found")
    (args.work_directory / "manifest.json").write_text(json.dumps(entries, indent=2))
    project = Path(__file__).resolve().parent.parent
    process_env = os.environ.copy()
    process_env["ETC2_AUDIT_DIR"] = str(args.work_directory.resolve())
    subprocess.run([str(args.godot.resolve()), "--headless", "--path", str(project),
                    "--script", "res://tools/verify_etc2_native.gd"], env=process_env, check=True)
    results = []
    for row in entries:
        with Image.open(args.audit_directory / row["png"]) as image:
            original = np.array(image.convert("RGBA"))
        native = np.fromfile(args.work_directory / row["native_rgba"], dtype=np.uint8).reshape(original.shape)
        delta = np.abs(original.astype(np.int16) - native.astype(np.int16))
        results.append({"id": row["id"], "name": row["name"], "rgb_max_delta": int(delta[:, :, :3].max()),
                        "alpha_max_delta": int(delta[:, :, 3].max()), "different_channels": int(np.count_nonzero(delta)),
                        "pass": bool(delta.max() == 0)})
    final = {"scope": "Every ETC2_RGBA8 Texture2D in supplied SeaBattles 1.24.0 package",
             "python_decoder": "UnityPy 1.25.4 / texture2ddecoder 1.0.6",
             "independent_decoder": subprocess.check_output([str(args.godot.resolve()), "--version"], text=True).strip(),
             "orientation": "Native Unity bottom-up scanlines flipped exactly once to match PNG",
             "checked": len(results), "exact_matches": sum(x["pass"] for x in results), "results": results,
             "status": "PASS" if all(x["pass"] for x in results) else "FAIL"}
    (args.audit_directory / "etc2_verification.json").write_text(json.dumps(final, ensure_ascii=False, indent=2))
    print("ETC2 crosscheck", final["status"], final["exact_matches"], "/", final["checked"], flush=True)
    if final["status"] != "PASS":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
