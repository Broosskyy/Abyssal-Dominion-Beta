"""Build finalized source + optional historical references, then CRC verify both."""
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
    destination.mkdir(parents=True, exist_ok=True)
    report = json.loads((ROOT / 'docs/m30_current_validation.json').read_text())
    assert report['passed'] and report['source_sha256'] == fingerprint(ROOT), 'Run fresh M30 checks first'
    groups = {'Source': [], 'References': []}
    exclude = {'.godot', '.git', '__pycache__', '.pytest_cache', 'node_modules', '.tools', 'builds'}
    for path in sorted(ROOT.rglob('*')):
        relative = path.relative_to(ROOT)
        if not path.is_file() or any(part in exclude for part in relative.parts): continue
        if path.suffix in {'.pyc', '.pyo', '.keystore', '.jks', '.p12', '.mobileprovision'}: continue
        if path.name == '.env' or relative.as_posix() == 'tools/local_config.json': continue
        reference = relative.parts[:2] == ('assets', 'reference_only') or (relative.parts[0] == 'docs' and path.stat().st_size > 1024 * 1024)
        groups['References' if reference else 'Source'].append((path, relative.as_posix()))
    result = []
    for group, entries in groups.items():
        output = destination / f'SeeFight_3D_M30_{group}.zip'
        with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for path, relative in entries: archive.write(path, relative)
        with zipfile.ZipFile(output) as archive:
            assert archive.testzip() is None
            if group == 'Source':
                for required in ['project.godot', 'scripts/ui/command_deck.gd', 'scripts/visual/asset_visual_library.gd', 'assets/placeholder_pack/manifest.json', 'docs/m30_current_validation.json']:
                    assert required in archive.namelist(), required
            count = len(archive.namelist())
        result.append({'path': str(output), 'files': count, 'bytes': output.stat().st_size, 'sha256': hashlib.sha256(output.read_bytes()).hexdigest()})
    print(json.dumps(result, indent=2))

if __name__ == '__main__': main()
