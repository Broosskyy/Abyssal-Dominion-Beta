#!/usr/bin/env python3
"""Relax strict := inference failures by switching affected lines to = assignment."""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "tools/godot-4.7.2/Godot_v4.7.2-stable_win64.exe"
PATTERN = re.compile(r"at: GDScript::reload \((res://[^:]+):(\d+)\)")
INFER_PATTERN = re.compile(r"Cannot infer the type of \"([^\"]+)\"")
VARIANT_PATTERN = re.compile(r"The variable type is being inferred from a Variant value")


def run_godot() -> str:
    proc = subprocess.run(
        [str(GODOT), "--headless", "--path", str(ROOT), "--quit-after", "1"],
        text=True,
        capture_output=True,
        timeout=120,
    )
    return proc.stdout + proc.stderr


def collect_errors(output: str) -> list[tuple[str, int, str]]:
    lines = output.splitlines()
    errors: list[tuple[str, int, str]] = []
    for index, line in enumerate(lines):
        match = PATTERN.search(line)
        if not match:
            continue
        path = match.group(1).removeprefix("res://")
        line_no = int(match.group(2))
        if line_no <= 0:
            continue
        message = ""
        for back in range(index - 1, max(index - 4, -1), -1):
            if "Parse Error:" in lines[back]:
                message = lines[back]
                break
        if INFER_PATTERN.search(message) or VARIANT_PATTERN.search(message):
            errors.append((path, line_no, message))
    # preserve order but dedupe
    seen: set[tuple[str, int]] = set()
    unique: list[tuple[str, int, str]] = []
    for item in errors:
        key = (item[0], item[1])
        if key in seen:
            continue
        seen.add(key)
        unique.append(item)
    return unique


def fix_line(source_line: str) -> str | None:
    if ":=" not in source_line:
        return None
    return source_line.replace(":=", "=", 1)


def main() -> None:
    if not GODOT.is_file():
        raise SystemExit(f"Godot missing: {GODOT}")
    total = 0
    for _ in range(200):
        errors = collect_errors(run_godot())
        if not errors:
            print(f"done; fixed {total} lines")
            return
        path, line_no, message = errors[0]
        file_path = ROOT / path
        lines = file_path.read_text(encoding="utf-8").splitlines(keepends=True)
        if line_no < 1 or line_no > len(lines):
            raise SystemExit(f"Line out of range: {path}:{line_no} ({message})")
        original = lines[line_no - 1]
        fixed = fix_line(original)
        if fixed is None:
            raise SystemExit(f"No := on {path}:{line_no}: {original.strip()} ({message})")
        lines[line_no - 1] = fixed
        file_path.write_text("".join(lines), encoding="utf-8", newline="\n")
        total += 1
        print(f"fixed {path}:{line_no}")
    raise SystemExit("fix loop exceeded 200 iterations")


if __name__ == "__main__":
    main()
