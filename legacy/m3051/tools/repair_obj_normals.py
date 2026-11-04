#!/usr/bin/env python3
"""Strip dangling normal references only from OBJ files with zero normal rows.

The Unity export emitted v/vt/vn faces even when no vn data existed. Vertices,
UVs, face order and geometry remain unchanged; Godot generates missing normals.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    changed = []
    for path in sorted((ROOT / "assets").rglob("*.obj")):
        text = path.read_text()
        lines = text.splitlines(keepends=True)
        if any(line.startswith("vn ") for line in lines):
            continue
        result = []
        fixed = False
        for line in lines:
            if line.startswith("f "):
                tokens = line.split()[1:]
                if any(len(token.split("/")) == 3 for token in tokens):
                    tokens = ["/".join(token.split("/")[:2]).rstrip("/") for token in tokens]
                    line = "f " + " ".join(tokens) + "\n"
                    fixed = True
            result.append(line)
        if fixed:
            path.write_text("".join(result))
            changed.append(str(path.relative_to(ROOT)))
    print("Repaired dangling normal references in %d OBJ files" % len(changed))
    for path in changed:
        print(path)


if __name__ == "__main__":
    main()
