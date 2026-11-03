#!/usr/bin/env python3
"""Measure supplied sprite frames without modifying or inventing source artwork."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
from PIL import Image


def measure(root):
    entries = {}
    paths = sorted(p for p in (root / 'assets').rglob('*.png')
                   if '/fleet/' in p.as_posix() or '/reference/ships/' in p.as_posix()
                   or '/user/ships/' in p.as_posix())
    for path in paths:
        image = Image.open(path).convert('RGBA')
        directional = '/user/ships/' not in path.as_posix()
        frames = []
        for column in range(4 if directional else 1):
            cell = (column * image.width // 4, image.height // 2,
                    (column + 1) * image.width // 4, image.height) if directional else (0, 0, *image.size)
            crop = image.crop(cell)
            alpha = crop.getchannel('A')
            mask = alpha.point(lambda value: 255 if value >= 40 else 0)
            bounds = mask.getbbox()
            if not bounds:
                raise ValueError(f'Empty frame: {path} / {column}')
            left, top, right, bottom = bounds
            width, height = right - left, bottom - top
            pixels = mask.load()
            points = [(x, y) for y in range(top + int(height * .45), top + int(height * .88))
                      for x in range(left, right) if pixels[x, y]]
            ideal_x = statistics.median(x for x, _ in points)
            ideal_y = top + height * .74
            pivot_x, pivot_y = min(points, key=lambda xy: (xy[0] - ideal_x)**2 + 4 * (xy[1] - ideal_y)**2)
            frames.append({'rect': [cell[0] + left, cell[1] + top, width, height],
                           'pivot': [pivot_x - left, pivot_y - top], 'column': column,
                           'row': 1 if directional else 0})
        entries[path.relative_to(root).as_posix()] = {
            'size': list(image.size), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
            'kind': 'directional' if directional else 'single_view',
            'headings': ['NE', 'NW', 'SW', 'SE'] if directional else ['SOURCE_VIEW'], 'frames': frames}
    return {'version': 1, 'alpha_threshold': 40,
            'anchor_rule': 'Opaque hull point: lower 45-88% silhouette band median X, nearest to 74% silhouette Y. Measured per frame.',
            'entries': entries}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path)
    parser.add_argument('--verify', action='store_true')
    args = parser.parse_args()
    output = args.output or args.source_root / 'assets/visuals/ship_frames.json'
    result = measure(args.source_root)
    if args.verify:
        if result != json.loads(output.read_text()):
            raise SystemExit('Sprite measurements do not match source art')
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'ships': len(result['entries']), 'frames': sum(len(x['frames']) for x in result['entries'].values()), 'verified': args.verify}))


if __name__ == '__main__':
    main()
