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
RELEASES = f"https://api.github.com/repos/{REPOSITORY}/releases?per_page=100"
DEST = Path(__file__).resolve().parent / "dist"
EXPECTED = {"index.html", "index.js"}


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
    requested_sha = os.environ.get("VERCEL_GIT_COMMIT_SHA", "").strip()
    requested_branch = os.environ.get("VERCEL_GIT_COMMIT_REF", "main").strip()
    # Browser exports are intentionally built by GitHub Actions on main only.
    # Vercel also builds every feature branch: waiting for a matching release
    # from a branch that has no export workflow will *always* time out.
    # Serve the most recent verified main browser test as a visibly identified
    # baseline preview instead. Never pretend it contains feature-branch code.
    baseline_preview = bool(requested_sha and requested_branch != "main")
    source_sha = "" if baseline_preview else requested_sha
    wait_for_source = False
    if baseline_preview:
        print(
            f"Feature branch {requested_branch}: no Godot export for this SHA; "
            "using the latest published browser-test as a BASELINE ONLY",
            flush=True,
        )
    if source_sha:
        commit = json.loads(response(f"https://api.github.com/repos/{REPOSITORY}/commits/{source_sha}"))
        wait_for_source = "[skip ci]" not in commit.get("commit", {}).get("message", "") and any(
            entry.get("filename", "").startswith(("rebuild/m3052/", "server/")) or
            entry.get("filename") == ".github/workflows/browser-preview.yml"
            for entry in commit.get("files", [])
        )
        if not wait_for_source:
            # Signing-bot or hosting-only commits must still publish the
            # newest browser export, even when its CI has not finished yet.
            runs = json.loads(response(f"https://api.github.com/repos/{REPOSITORY}/actions/workflows/browser-preview.yml/runs?branch=main&per_page=1"))
            recent = runs.get("workflow_runs", [])
            if recent:
                run = recent[0]
                if run.get('status') == 'completed' and run.get('conclusion') != 'success':
                    raise RuntimeError('The latest browser export failed; keeping the previous deployment active')
                source_sha = str(run.get('head_sha', ''))
                wait_for_source = bool(source_sha)
    # Vercel starts at push time, before Godot finishes exporting. Never
    # silently publish test N-1 under the source SHA of browser test N.
    deadline = time.monotonic() + 600
    while True:
        versions = json.loads(response(RELEASES))
        if not wait_for_source or any(
            re.fullmatch(r"browser-test-\d+", str(item.get("tag_name", ""))) and
            item.get("target_commitish") == source_sha and item.get("assets")
            for item in versions
        ):
            break
        if time.monotonic() >= deadline:
            raise RuntimeError("The browser export for this commit is not ready; keeping the previous deployment active")
        print("Waiting for the matching Godot browser export …", flush=True)
        time.sleep(10)
    candidates = []
    for release in versions:
        match = re.fullmatch(r"browser-test-(\d+)", str(release.get("tag_name", "")))
        if match is None or release.get("draft", False):
            continue
        if wait_for_source and release.get("target_commitish") != source_sha:
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
            if path.suffix not in {".html", ".js", ".pck", ".wasm", ".png", ".ico", ".svg", ".json", ".webp", ".zip"}:
                continue
            destination = DEST / path
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(archive.read(name))
    delivery_path = DEST / 'delivery-report.json'
    delivery = json.loads(delivery_path.read_text()) if delivery_path.exists() else {}
    required = EXPECTED | set(delivery.get('start_files', ['index.pck', 'index.wasm']))
    required |= {pack['file'] for pack in delivery.get('packs', {}).values()}
    if any(not (DEST / name).is_file() or (DEST / name).stat().st_size == 0 for name in required):
        raise RuntimeError("Browser release is incomplete")
    exported_sha = str(release.get("target_commitish", ""))
    metadata = {
        "scope": "public-browser-test",
        "release": release["tag_name"],
        "source": exported_sha,
        "requested_commit": requested_sha,
        "requested_branch": requested_branch,
        "contains_requested_commit": bool(requested_sha and requested_sha == exported_sha),
        "preview_mode": "last-tested-main-baseline" if baseline_preview else "matched-godot-export",
        "preview_notice": (
            "Feature-branch HUD/controls are NOT yet contained in this baseline. "
            "Only a published Godot browser-test build can validate them."
            if baseline_preview else ""
        ),
        "account_server": "external-https-wss-configuration-required",
        "live_combat": False,
    }
    (DEST / "preview.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print(f"Prepared {release['tag_name']} from {REPOSITORY}, {len(list(DEST.iterdir()))} files")


if __name__ == "__main__":
    main()
