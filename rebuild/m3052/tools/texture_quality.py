"""Keep source pixels lossless and build mipmaps for the native 2D renderer."""
from pathlib import Path


def prepare(root: Path) -> list[str]:
    changed = []
    for path in sorted((root / 'assets').rglob('*.png.import')):
        original = path.read_text()
        updated = original.replace('mipmaps/generate=false', 'mipmaps/generate=true')
        if updated != original:
            path.write_text(updated)
            changed.append(str(path.relative_to(root)))
    return changed


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    print(f'Prepared {len(prepare(root))} texture imports; run Godot editor import next.')
