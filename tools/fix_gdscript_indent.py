#!/usr/bin/env python3
"""Convert leading space indentation to tabs in GDScript files."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fix_line(line: str) -> str:
    if not line or line[0] != " ":
        return line
    stripped = line.lstrip(" ")
    spaces = len(line) - len(stripped)
    return "\t" * spaces + stripped


def fix_file(path: Path) -> bool:
    original = path.read_text(encoding="utf-8")
    lines = original.splitlines(keepends=True)
    fixed = [fix_line(line) if line and line[0] == " " else line for line in lines]
    updated = "".join(fixed)
    if updated != original:
        path.write_text(updated, encoding="utf-8", newline="\n")
        return True
    return False


def main() -> None:
    changed = 0
    for path in sorted(ROOT.rglob("*.gd")):
        if path.is_file() and fix_file(path):
            changed += 1
            print(path.relative_to(ROOT))
    print(f"fixed {changed} files")


if __name__ == "__main__":
    main()
