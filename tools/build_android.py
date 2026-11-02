#!/usr/bin/env python3
"""Export and verify the current ARM64 Android test APK with Godot 4.7.2."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from build_m3035_android import set_editor_paths, editor_settings_default


def run_logged(command, path, env):
    result = subprocess.run(command, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    path.write_text(result.stdout, encoding='utf-8')
    if result.returncode or any(s in result.stdout for s in ('SCRIPT ERROR:', 'Parse Error:', 'ERROR: Failed to load script')):
        print(result.stdout[-12000:])
        raise RuntimeError(f'Godot failed; see {path}')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    p.add_argument('--android-sdk', type=Path, default=Path(os.environ['ANDROID_HOME']) if os.environ.get('ANDROID_HOME') else None)
    p.add_argument('--java-home', type=Path, default=Path(os.environ['JAVA_HOME']) if os.environ.get('JAVA_HOME') else None)
    p.add_argument('--debug-keystore', type=Path, required=True)
    p.add_argument('--output', type=Path, default=ROOT / 'builds/android/ABYSSAL_DOMINION_M3051_ARM64_TEST.apk')
    args = p.parse_args()
    version = subprocess.check_output([args.godot, '--version'], text=True).strip()
    if not version.startswith('4.7.2.stable'):
        raise RuntimeError(f'Godot 4.7.2 required, found {version}')
    if not args.android_sdk or not args.java_home or not args.debug_keystore.is_file():
        raise RuntimeError('Android SDK, JDK and an existing debug keystore are required')
    pack_root = ROOT / 'assets/classic/private_seabattles'
    pack = json.loads((pack_root / 'pack.json').read_text())
    graphics = []
    for item in pack['selected']:
        f = pack_root / item['slot']
        digest = hashlib.sha256(f.read_bytes()).hexdigest()
        if digest != item.get('sha256', item.get('source_sha256')):
            raise RuntimeError(f'Artwork checksum mismatch: {item["slot"]}')
        graphics.append({'path': f.relative_to(ROOT).as_posix(), 'sha256': digest})
    set_editor_paths(editor_settings_default(), {
        'export/android/android_sdk_path': args.android_sdk.resolve(),
        'export/android/java_sdk_path': args.java_home.resolve(),
        'export/android/debug_keystore': args.debug_keystore.resolve(),
        'export/android/debug_keystore_user': 'androiddebugkey',
        'export/android/debug_keystore_pass': 'android',
    })
    env = dict(os.environ, JAVA_HOME=str(args.java_home.resolve()), ANDROID_HOME=str(args.android_sdk.resolve()))
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    run_logged([args.godot, '--headless', '--path', str(ROOT), '--editor', '--import', '--quit'], output.with_suffix('.import.log'), env)
    run_logged([args.godot, '--headless', '--path', str(ROOT), '--script', 'res://tests/m3051_complete_reference_fleet_smoke.gd'], output.with_suffix('.fleet-test.log'), env)
    run_logged([args.godot, '--headless', '--path', str(ROOT), '--export-debug', 'Android', str(output)], output.with_suffix('.export.log'), env)
    with zipfile.ZipFile(output) as z:
        if z.testzip():
            raise RuntimeError('APK archive integrity failed')
        names = z.namelist()
        if 'lib/arm64-v8a/libgodot_android.so' not in names:
            raise RuntimeError('Missing ARM64 engine')
        for rel in [x['path'] for x in graphics] + ['assets/classic/private_seabattles/pack.json']:
            if rel.endswith('.png'):
                # Godot exports the PNG's .import file plus its compiled texture.
                key = 'assets/' + rel + '.import'
                if key not in names:
                    raise RuntimeError(f'Missing exported image mapping: {rel}')
                mapping = z.read(key).decode('utf-8')
                targets = re.findall(r'"res://([^"\n]+\.ctex)"', mapping)
                if not targets or not any('assets/' + t in names and z.getinfo('assets/' + t).file_size > 0 for t in targets):
                    raise RuntimeError(f'Missing compiled texture: {rel}')
            elif 'assets/' + rel not in names:
                raise RuntimeError(f'Missing graphics resource in APK: {rel}')
        if json.loads(z.read('assets/assets/classic/private_seabattles/pack.json')) != pack:
            raise RuntimeError('Exported reference configuration differs from source')
    bt = args.android_sdk / 'build-tools/35.0.1'
    sig = subprocess.check_output([str(args.java_home/'bin/java'), '-jar', str(bt/'lib/apksigner.jar'), 'verify', '--verbose', '--print-certs', str(output)], text=True)
    output.with_suffix('.signature.txt').write_text(sig)
    subprocess.run([str(bt/'zipalign'), '-c', '-P', '16', '4', str(output)], check=True)
    badging = subprocess.check_output([str(bt/'aapt'), 'dump', 'badging', str(output)], text=True)
    output.with_suffix('.manifest.txt').write_text(badging)
    if "package: name='com.abyssaldominion.mobile' versionCode='305101' versionName='0.305.1-test.1'" not in badging:
        raise RuntimeError('Unexpected APK identity or version')
    result = {
        'engine': version, 'apk': output.name, 'package': 'com.abyssaldominion.mobile',
        'version_code': 305101, 'version_name': '0.305.1-test.1', 'architecture': 'arm64-v8a',
        'size_bytes': output.stat().st_size, 'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
        'reference_graphics': graphics, 'signature': 'PASS', 'alignment_16k': 'PASS',
        'archive_integrity': 'PASS', 'device_installation': 'NOT_TESTED',
        'online_service': 'NO_PUBLIC_SERVER_CONFIGURED',
    }
    output.with_suffix('.build.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
