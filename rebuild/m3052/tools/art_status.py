#!/usr/bin/env python3
"""Report which runtime images are temporary test graphics and which are our own.

Temporary test graphics (extracted from third-party games or taken from
reference collections) may only be used for internal testing until they are
replaced by original art. Writes docs/ART_REPLACEMENT.md (repository root)
and prints a short summary. Use --check to fail when an image has no
provenance entry, so new files cannot slip in unclassified.
"""
import json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
IMAGE_SUFFIXES = {'.png', '.jpg', '.jpeg', '.webp', '.svg'}

def classify(entry: dict) -> str:
    text = ' '.join(str(entry.get(k, '')) for k in ('source_archive', 'source', 'reference', 'source_image')).lower()
    if 'seabattles' in text or 'seafight' in text or entry.get('source_bundle'):
        return 'placeholder-third-party'
    if any(k in text for k in ('generation', 'image editing', 'handwritten', 'original painted', 'original fire-button', 'original seamless', 'rendered procedurally')):
        return 'own'
    return 'placeholder-reference'

LABELS = {
    'placeholder-third-party': 'Testgrafik · aus fremdem Spiel extrahiert',
    'placeholder-reference': 'Testgrafik · aus Referenzsammlung, Herkunft prüfen',
    'own': 'Eigen',
    'unlisted': 'Ohne Herkunftsnachweis',
}

def main() -> int:
    data = json.loads((ROOT / 'assets/provenance.json').read_text())
    entries = {e['path']: e for e in data['files']}
    for e in data.get('vector_ui', []):
        entries.setdefault(e['path'], e)
    rows = []
    for path in sorted(p for p in (ROOT / 'assets').rglob('*') if p.suffix.lower() in IMAGE_SUFFIXES):
        rel = str(path.relative_to(ROOT))
        entry = entries.get(rel)
        kind = classify(entry) if entry else 'unlisted'
        name = (entry or {}).get('source_name') or (entry or {}).get('asset_id') or ''
        rows.append((kind, rel, name))
    counts = {k: sum(1 for r in rows if r[0] == k) for k in LABELS}
    out = ['# Grafiken: Testgrafiken und eigene Designs', '',
           'Automatisch erzeugt von `rebuild/m3052/tools/art_status.py`. Testgrafiken sind nur zum internen Testen eingebunden, bis eigene Designs sie ersetzen. Eigene Designs dürfen nicht nach Testgrafiken nachgezeichnet werden.', '',
           '| Kategorie | Anzahl |', '| --- | ---: |']
    out += ['| %s | %d |' % (LABELS[k], counts[k]) for k in LABELS]
    for kind in LABELS:
        sel = [r for r in rows if r[0] == kind]
        if not sel: continue
        out += ['', '## ' + LABELS[kind], '', '| Datei | Quelle/Name |', '| --- | --- |']
        out += ['| `%s` | %s |' % (r[1], r[2].replace('|', '/')) for r in sel]
    (REPO / 'docs/ART_REPLACEMENT.md').write_text('\n'.join(out) + '\n')
    print(json.dumps(counts))
    if '--check' in sys.argv and counts['unlisted']:
        print('Images without provenance:', *[r[1] for r in rows if r[0] == 'unlisted'], sep='\n  ')
        return 1
    return 0

if __name__ == '__main__':
    sys.exit(main())
