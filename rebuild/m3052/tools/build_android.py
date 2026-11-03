#!/usr/bin/env python3
"""Test, export, and independently verify the isolated M3052 build."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def checked(command, log, env=None):
    result = subprocess.run(command, env=env, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=1200)
    log.write_text(result.stdout, encoding='utf-8')
    if result.returncode or any(s in result.stdout for s in
                              ('SCRIPT ERROR:', 'Parse Error:', 'Failed to load script')):
        lines = result.stdout.splitlines()
        errors = []
        for i, line in enumerate(lines):
            if any(s in line for s in ('ERROR:', 'Parse Error:', 'Error at', 'SCRIPT ERROR:')):
                errors.extend(lines[max(0, i-1):i+4])
        raise RuntimeError('\n'.join(errors) + '\n' + result.stdout[-8000:])
    return result.stdout


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--godot', required=True)
    p.add_argument('--keystore', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    args = p.parse_args()
    engine = str(Path(args.godot).resolve())
    version = subprocess.check_output([engine, '--version'], text=True).strip()
    if not version.startswith('4.7.2.stable'):
        raise RuntimeError('Godot 4.7.2 required')
    sdk = Path(os.environ['ANDROID_HOME'])
    java = Path(os.environ['JAVA_HOME'])
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    assets = json.loads((ROOT/'assets/provenance.json').read_text())['files']
    for row in assets:
        if hashlib.sha256((ROOT/row['path']).read_bytes()).hexdigest() != row['sha256']:
            raise RuntimeError('Artwork changed: '+row['path'])
    settings = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home()/'.config')))/'godot/editor_settings-4.7.tres'
    settings.parent.mkdir(parents=True, exist_ok=True)
    text = settings.read_text() if settings.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    values = {'export/android/android_sdk_path': str(sdk), 'export/android/java_sdk_path': str(java),
              'export/android/debug_keystore': str(args.keystore.resolve()),
              'export/android/debug_keystore_user': 'androiddebugkey',
              'export/android/debug_keystore_pass': 'android'}
    for key, value in values.items():
        line = key+' = '+json.dumps(value)
        pattern = re.compile('^'+re.escape(key)+r'\s*=.*$', re.MULTILINE)
        text = pattern.sub(lambda _: line, text) if pattern.search(text) else text+'\n'+line+'\n'
    settings.write_text(text)
    for script in ['content.gd', 'simulation.gd', 'ship_visuals.gd', 'updater/update_model.gd', 'updater/update_controller.gd', 'updater/launcher.gd']:
        checked([engine, '--headless', '--path', str(ROOT), '--check-only', '--script', script], output.with_suffix('.'+script.replace('/', '_')+'.check.log'))
    checked([engine, '--headless', '--path', str(ROOT), '--editor', '--import', '--quit'], output.with_suffix('.import.log'))
    results = []
    for name in ['simulation_test', 'progression_test', 'ship_visual_test', 'ui_test', 'updater_test']:
        with tempfile.TemporaryDirectory() as user_data:
            env = dict(os.environ, XDG_DATA_HOME=user_data)
            log = checked([engine, '--headless', '--path', str(ROOT), '--quit-after', '120',
                           '--script', 'tests/'+name+'.gd'], output.with_suffix('.'+name+'.log'), env)
            rows = [json.loads(line) for line in log.splitlines() if line.startswith('{')]
            if not rows or rows[-1].get('status') != 'PASS':
                raise RuntimeError('Missing successful test result: '+name)
            results.append(dict(test=name, **rows[-1]))
    checked([engine, '--headless', '--path', str(ROOT), '--export-debug', 'Android', str(output)], output.with_suffix('.export.log'))
    with zipfile.ZipFile(output) as z:
        if z.testzip() or 'lib/arm64-v8a/libgodot_android.so' not in z.namelist():
            raise RuntimeError('APK integrity or ARM64 engine missing')
        dex = b''.join(z.read(n) for n in z.namelist() if re.fullmatch(r'classes\d*\.dex', n))
        for symbol in [b'AbyssalApkInstaller', b'enqueueBackgroundApk', b'queryBackgroundApk', b'installValidatedApk', b'android/app/DownloadManager']:
            if symbol not in dex: raise RuntimeError('Native updater absent from APK: '+str(symbol))
        if z.read('assets/updater/config.json') != (ROOT/'updater/config.json').read_bytes():
            raise RuntimeError('Updater configuration missing or changed')
        geometry_path = 'assets/assets/visuals/ship_frames.json'
        if geometry_path not in z.namelist() or z.read(geometry_path) != (ROOT/'assets/visuals/ship_frames.json').read_bytes():
            raise RuntimeError('Measured sprite geometry missing or different in APK')
        for row in assets:
            mapping = 'assets/'+row['path']+'.import'
            if mapping not in z.namelist():
                raise RuntimeError('Missing exported artwork: '+row['path'])
            compiled = re.findall(r'"res://([^"\n]+\.ctex)"', z.read(mapping).decode())
            if not compiled or not any('assets/'+name in z.namelist() for name in compiled):
                raise RuntimeError('Missing compiled texture: '+row['path'])
    bt = sdk/'build-tools/35.0.1'
    sig = subprocess.check_output([str(java/'bin/java'), '-jar', str(bt/'lib/apksigner.jar'),
                                   'verify', '--verbose', '--print-certs', str(output)], text=True)
    output.with_suffix('.signature.txt').write_text(sig)
    certificate = '278a2899340d58b3db0aced5e0f306ebb121550bc34dc1e6948783424652fe3b'
    if 'certificate SHA-256 digest: '+certificate not in sig:
        raise RuntimeError('Signing certificate differs from installed M3056; refusing incompatible update')
    xml = subprocess.check_output([str(bt/'aapt'), 'dump', 'xmltree', str(output), 'AndroidManifest.xml'], text=True)
    for token in ['android.permission.INTERNET', 'android.permission.REQUEST_INSTALL_PACKAGES', 'org.godotengine.plugin.v2.AbyssalApkInstaller', 'com.abyssal.updater.AbyssalFileProvider', 'com.abyssaldominion.rebuild.abyssalupdater.files']:
        if token not in xml: raise RuntimeError('Updater manifest entry missing: '+token)
    output.with_suffix('.android-xml.txt').write_text(xml)
    subprocess.run([str(bt/'zipalign'), '-c', '-P', '16', '4', str(output)], check=True)
    manifest = subprocess.check_output([str(bt/'aapt'), 'dump', 'badging', str(output)], text=True)
    output.with_suffix('.manifest.txt').write_text(manifest)
    if "name='com.abyssaldominion.rebuild' versionCode='305701' versionName='0.305.7-test.1'" not in manifest:
        raise RuntimeError('Unexpected Android identity')
    report = {'engine': version, 'apk': output.name, 'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
              'bytes': output.stat().st_size, 'tests': results, 'audited_pngs': len(assets),
              'signature': 'PASS', 'certificate_sha256': certificate, 'version_code': 305701, 'package': 'com.abyssaldominion.rebuild', 'updater_native': True, 'update_distribution': 'GITHUB_RELEASES_MANIFEST_PUBLISHED_LAST', 'alignment_16k': 'PASS', 'physical_android_test': 'NOT_PERFORMED',
              'mode': 'LOCAL_GUEST_SEA_CHART', 'public_server': False, 'milestone': 'M3057',
              'regions': 3, 'quest_chain': 7, 'equipment_categories': 4, 'equipment_tiers': 3,
              'source_commit': os.environ.get('GITHUB_SHA', 'local'),
              'measured_ship_sources': 28, 'measured_ship_frames': 90, 'eight_direction_designs': 1, 'starter_states': ['intact','damaged'], 'starter_damage_hp_ratio': 0.35}
    output.with_suffix('.build.json').write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
