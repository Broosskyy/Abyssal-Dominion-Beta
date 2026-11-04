#!/usr/bin/env python3
"""Build a separately installable, locally signed M304.8 ARM64 test APK.

Requires Godot 4.7.2, its Android debug template, JDK 17 and Android SDK tools.
No artifact, signing key, private pack, or screenshot is pushed to GitHub.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parent.parent


def editor_settings_default():
    if sys.platform == "win32":
        return Path(os.environ["APPDATA"]) / "Godot/editor_settings-4.7.tres"
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support/Godot/editor_settings-4.7.tres"
    return Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "godot/editor_settings-4.7.tres"


def set_editor_paths(path, updates):
    # Preserve unrelated editor preferences. Do not log settings or credentials.
    if not path.is_file():
        path.parent.mkdir(parents=True, exist_ok=True)
        text = '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    else:
        text = path.read_text(encoding="utf-8")
    for key, value in updates.items():
        line = key + " = " + json.dumps(str(value))
        pattern = re.compile(r"^" + re.escape(key) + r"\s*=.*$", re.MULTILINE)
        if pattern.search(text):
            text = pattern.sub(lambda _: line, text)
        else:
            text += "\n" + line + "\n"
    path.write_text(text, encoding="utf-8")


def verify_private_sources():
    base = ROOT / "assets/classic"
    for folder in ["private_seabattles", "private_seaofbones"]:
        root = base / folder
        config = root / "pack.json"
        if not config.is_file():
            raise RuntimeError(f"Missing local artwork: {folder}/pack.json. Install the private pack or use --allow-placeholders.")
        pack = json.loads(config.read_text())
        for row in pack.get("selected", []):
            image = root / row["slot"]
            if not image.is_file() or hashlib.file_digest(image.open("rb"), "sha256").hexdigest() != row["source_sha256"]:
                raise RuntimeError(f"Missing/changed audited PNG: {folder}/{row['slot']}")
        for actor in pack.get("actors", {}).values():
            if not (root / actor["path"]).is_file():
                raise RuntimeError(f"Missing actor image in {folder}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"))
    parser.add_argument("--android-sdk", type=Path, default=Path(os.environ["ANDROID_HOME"]) if os.environ.get("ANDROID_HOME") else None)
    parser.add_argument("--java-home", type=Path)
    parser.add_argument("--debug-keystore", type=Path)
    parser.add_argument("--editor-settings", type=Path, default=editor_settings_default())
    parser.add_argument("--output", type=Path, default=ROOT / "builds/android/ABYSSAL_DOMINION_M3049_ART_ZIP_IMPORT.apk")
    parser.add_argument("--allow-placeholders", action="store_true")
    args = parser.parse_args()
    version = subprocess.check_output([args.godot, "--version"], text=True).strip()
    if not version.startswith("4.7.2.stable"):
        raise RuntimeError(f"Godot 4.7.2 required; got {version}")
    if args.android_sdk is None:
        raise RuntimeError("Pass --android-sdk or set ANDROID_HOME so APK signing can be verified")
    if not args.allow_placeholders:
        verify_private_sources()
    updates = {}
    if args.android_sdk:
        updates["export/android/android_sdk_path"] = args.android_sdk.resolve().as_posix()
    if args.java_home:
        updates["export/android/java_sdk_path"] = args.java_home.resolve().as_posix()
    if args.debug_keystore:
        updates["export/android/debug_keystore"] = args.debug_keystore.resolve().as_posix()
    if updates:
        set_editor_paths(args.editor_settings, updates)
    env = os.environ.copy()
    if args.java_home:
        env["JAVA_HOME"] = str(args.java_home.resolve())
        env["PATH"] = str(args.java_home.resolve() / "bin") + os.pathsep + env.get("PATH", "")
    if args.android_sdk:
        env["ANDROID_HOME"] = str(args.android_sdk.resolve())
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([args.godot, "--headless", "--path", str(ROOT), "--export-debug", "Android M304 Local Test", str(output)], env=env, check=True)
    with zipfile.ZipFile(output) as archive:
        if archive.testzip() is not None:
            raise RuntimeError("APK ZIP integrity failed")
        names = archive.namelist()
        if "lib/arm64-v8a/libgodot_android.so" not in names:
            raise RuntimeError("ARM64 Godot library missing")
        if not args.allow_placeholders:
            for folder in ["private_seabattles", "private_seaofbones"]:
                matches = [n for n in names if n.endswith(f"assets/classic/{folder}/pack.json")]
                if len(matches) != 1:
                    raise RuntimeError(f"Pack configuration was not included in APK: {folder}")
                if json.loads(archive.read(matches[0])) != json.loads((ROOT / "assets/classic" / folder / "pack.json").read_text()):
                    raise RuntimeError("Exported pack configuration differs from local source")
        if any("/models/" in n and "/private_seaofbones/" in n for n in names):
            raise RuntimeError("Offline source meshes should not ship in the APK")
    # Godot can return success with an unsigned APK and an export warning.
    # Treat a failed external signature/alignment check as a failed build.
    versions = sorted((args.android_sdk / "build-tools").iterdir(), key=lambda p: [int(n) for n in p.name.split(".") if n.isdigit()])
    build_tools = versions[-1]
    java = str(args.java_home / "bin" / ("java.exe" if os.name == "nt" else "java")) if args.java_home else shutil.which("java")
    signature = subprocess.run([java, "-jar", str(build_tools / "lib/apksigner.jar"), "verify", "--verbose", "--print-certs", str(output)],
                               env=env, text=True, capture_output=True, check=True)
    output.with_suffix(".signature.txt").write_text(signature.stdout)
    zipalign = build_tools / ("zipalign.exe" if os.name == "nt" else "zipalign")
    subprocess.run([str(zipalign), "-c", "-P", "16", "4", str(output)], env=env, check=True)
    result = {"engine": version, "apk": output.name, "size_bytes": output.stat().st_size,
              "sha256": hashlib.file_digest(output.open("rb"), "sha256").hexdigest(),
              "package": "com.abyssaldominion.m3035test", "version_name": "0.304.8-test.1",
              "architecture": "arm64-v8a", "private_graphics_included": not args.allow_placeholders,
              "zip_integrity": "PASS", "signature_verification": "PASS", "alignment_16k": "PASS",
              "device_installation": "NOT_TESTED"}
    output.with_suffix(".build.json").write_text(json.dumps(result, indent=2))
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
