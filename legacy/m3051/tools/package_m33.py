"""Finalize and CRC-verify the M33 source archive before upload."""
import hashlib
import json
from pathlib import Path
import sys
import zipfile
from preview import fingerprint

ROOT = Path(__file__).resolve().parents[1]

def main():
    destination = Path(sys.argv[1]).resolve()
    assert destination != ROOT and ROOT not in destination.parents
    report = json.loads((ROOT / 'docs/m33_current_validation.json').read_text())
    assert report['passed'] and report['source_sha256'] == fingerprint(ROOT), 'Run fresh M33 checks first'
    destination.mkdir(parents=True, exist_ok=True)
    output = destination / 'SeeFight_3D_M33_Source.zip'
    excluded = {'.godot', '.git', '__pycache__', '.pytest_cache', 'node_modules', '.tools', 'builds'}
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(ROOT.rglob('*')):
            relative = path.relative_to(ROOT)
            if not path.is_file() or any(part in excluded for part in relative.parts): continue
            if path.suffix in {'.pyc', '.pyo', '.keystore', '.jks', '.p12', '.mobileprovision'}: continue
            if path.name == '.env' or relative.as_posix() == 'tools/local_config.json': continue
            if relative.parts[:2] == ('assets', 'reference_only'): continue
            archive.write(path, relative.as_posix())
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        for name in ['project.godot', 'scripts/progression/voyage_progress.gd', 'tests/m33_runtime_test.gd', 'docs/m33_current_validation.json']:
            assert name in archive.namelist()
        count = len(archive.namelist())
    print(json.dumps({'path': str(output), 'bytes': output.stat().st_size, 'entries': count, 'sha256': hashlib.sha256(output.read_bytes()).hexdigest()}, indent=2))

if __name__ == '__main__': main()
