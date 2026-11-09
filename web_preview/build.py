"""Build an immutable browser-preview from the tested GitHub Actions release.

A fresh web export is produced by .github/workflows/browser-preview.yml.
This Vercel static frontend does not run the multiplayer backend.
"""
from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path
import re
import time
from urllib.request import Request, urlopen
from zipfile import ZipFile

REPOSITORY = "Broosskyy/Abyssal-Dominion-Beta"
RELEASES = f"https://api.github.com/repos/{REPOSITORY}/releases?per_page=30"
DEST = Path(__file__).resolve().parent / "dist"
EXPECTED = {"index.html", "index.js", "index.pck", "index.wasm"}


def response(url: str) -> bytes:
    req = Request(url, headers={"User-Agent": "AbyssalBrowserPreview/1.0", "Accept": "application/vnd.github+json"})
    last_error = None
    for attempt in range(4):
        try:
            with urlopen(req, timeout=180) as stream:
                return stream.read()
        except Exception as error:
            last_error = error
            time.sleep(2 * (attempt + 1))
    raise RuntimeError(f"Could not fetch public test release: {type(last_error).__name__}") from last_error


def main() -> None:
    versions = json.loads(response(RELEASES))
    candidates = []
    for release in versions:
        match = re.fullmatch(r"browser-test-(\d+)", str(release.get("tag_name", "")))
        if match is None or release.get("draft", False):
            continue
        for asset in release.get("assets", []):
            if re.fullmatch(r"ABYSSAL_BROWSER_\d+\.zip", str(asset.get("name", ""))):
                candidates.append((int(match.group(1)), release, asset))
    if not candidates:
        raise RuntimeError("No verified HTML5 browser prerelease found; run GitHub Actions Browser preview first")
    _, release, asset = max(candidates, key=lambda entry: entry[0])
    zipped = response(asset["browser_download_url"])
    digest = str(asset.get("digest", ""))
    if digest.startswith("sha256:"):
        actual = hashlib.sha256(zipped).hexdigest()
        if actual.lower() != digest[7:].lower():
            raise RuntimeError("GitHub browser asset checksum mismatch")
    import io
    DEST.mkdir(parents=True, exist_ok=True)
    with ZipFile(io.BytesIO(zipped)) as archive:
        for name in archive.namelist():
            path = Path(name)
            if path.is_absolute() or ".." in path.parts:
                raise RuntimeError("Unsafe browser release archive path")
            if path.suffix not in {".html", ".js", ".pck", ".wasm", ".png", ".ico", ".svg", ".json", ".webp"}:
                continue
            destination = DEST / path
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(archive.read(name))
    if any(not (DEST / name).is_file() or (DEST / name).stat().st_size == 0 for name in EXPECTED):
        raise RuntimeError("Browser release is incomplete")
    metadata = {
        "scope": "public-browser-test",
        "release": release["tag_name"],
        "source": release.get("target_commitish", ""),
        "account_server": "external-https-wss-configuration-required",
        "live_combat": False,
    }
    (DEST / "preview.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print(f"Prepared {release['tag_name']} from {REPOSITORY}, {len(list(DEST.iterdir()))} files")


if __name__ == "__main__":
    main()
