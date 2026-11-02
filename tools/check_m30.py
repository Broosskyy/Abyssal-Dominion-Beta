"""Asset validation + explicitly labelled engine smoke tests. Not native visual QA."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import sys
from preview import fingerprint

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--engine', required=True)
    parser.add_argument('--supplementary', action='store_true')
    args = parser.parse_args()
    engine = str(Path(args.engine).resolve())
    version = subprocess.check_output([engine, '--version'], text=True).strip()
    target = version.startswith('4.7.2.stable')
    if not target and not args.supplementary:
        raise SystemExit('Target is 4.7.2.stable; use --supplementary to label a non-target smoke test.')
    manifest = json.loads((ROOT / 'assets/placeholder_pack/manifest.json').read_text())
    for key, entry in manifest['assets'].items():
        raw = (ROOT / entry['path'].removeprefix('res://')).read_bytes()
        magic, gltf_version, length = struct.unpack_from('<4sII', raw)
        assert magic == b'glTF' and gltf_version == 2 and length == len(raw), key
        assert hashlib.sha256(raw).hexdigest() == entry['sha256'], key
        assert len(raw) == entry['bytes'], key
    report = {'milestone': 'M30', 'engine': version, 'target_engine': '4.7.2.stable',
              'target_engine_verified': target, 'supplementary': not target,
              'source_sha256': fingerprint(ROOT), 'asset_count': len(manifest['assets']),
              'visual_verification': False, 'native_device_tests': False, 'release_approved': False,
              'stages': [], 'passed': True}
    for name, flags in [('import', ['--editor', '--import', '--quit']),
                        ('runtime', ['--script', 'res://tests/m30_runtime_test.gd'])]:
        result = subprocess.run([engine, '--headless', '--path', str(ROOT), *flags],
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120)
        log = result.stdout
        (ROOT / 'docs' / f'm30_{name}.log').write_text(log)
        passed = result.returncode == 0 and not re.search(r'(?:SCRIPT )?ERROR:|instances leaked', log)
        if name == 'runtime':
            summaries = [json.loads(line) for line in log.splitlines() if line.startswith('{') and '"suite"' in line]
            passed = passed and len(summaries) == 1 and summaries[0]['checks'] > 0 and not summaries[0]['failures']
            report['runtime'] = summaries[0] if summaries else None
        report['stages'].append({'name': name, 'passed': bool(passed), 'exit_code': result.returncode})
        report['passed'] &= bool(passed)
        if not passed:
            print(log[-6000:])
            break
    (ROOT / 'docs/m30_current_validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return 0 if report['passed'] else 1

if __name__ == '__main__':
    sys.exit(main())
