#!/usr/bin/env python3
"""Godot web build + restricted local preview. Python 3.10+, no pip dependency."""
from __future__ import annotations

import argparse
import functools
import hashlib
import http.server
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.parse
import webbrowser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "builds/web"
STAMP = "preview-build.json"
SOURCE_DIRS = ("scripts", "scenes", "assets", "data", "web")
REQUIRED_ENGINE = "4.7.2.stable"


def validate_engine(version: str) -> None:
    if version != REQUIRED_ENGINE and not version.startswith(REQUIRED_ENGINE + "."):
        raise RuntimeError(f"This revision requires Godot {REQUIRED_ENGINE} and matching export templates; got {version}.")


def fingerprint(root: Path = ROOT) -> str:
    paths = [root / "project.godot", root / "export_presets.cfg"]
    for folder in SOURCE_DIRS:
        paths.extend((root / folder).rglob("*"))
    digest = hashlib.sha256()
    for path in sorted(paths):
        if not path.is_file() or path.suffix in {".import", ".uid"} or "reference_only" in path.parts:
            continue
        digest.update(path.relative_to(root).as_posix().encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def read_stamp(directory: Path = WEB) -> dict:
    try:
        value = json.loads((directory / STAMP).read_text())
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}


def find_godot(explicit: str | None = None) -> str:
    candidate = explicit or os.environ.get("GODOT_BIN")
    if candidate:
        resolved = shutil.which(candidate) or (str(Path(candidate).resolve()) if Path(candidate).is_file() else None)
        if not resolved:
            raise RuntimeError("Godot not found at the specified path. Check --godot / GODOT_BIN.")
        return resolved
    for name in ("godot", "godot4", "Godot"):
        if result := shutil.which(name):
            return result
    raise RuntimeError("Godot missing. Install Godot + matching Web export templates; set GODOT_BIN or pass --godot PATH. An unchanged bundled Web build can run without Godot.")


def engine_version(engine: str) -> str:
    return subprocess.check_output([engine, "--version"], text=True, timeout=15).strip()


def build_web(engine: str) -> dict:
    version = engine_version(engine)
    validate_engine(version)
    builds = ROOT / "builds"
    builds.mkdir(exist_ok=True)
    source_hash = fingerprint()
    # Staging prevents failed exports from replacing the last good preview.
    with tempfile.TemporaryDirectory(prefix="web-stage-", dir=builds) as temporary:
        stage = Path(temporary)
        for label, flags in (("import", ["--editor", "--import", "--quit"]),
                             ("export", ["--export-debug", "Web", str(stage / "index.html")])):
            result = subprocess.run([engine, "--headless", "--path", str(ROOT), *flags],
                                    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=300)
            log = result.stdout
            (builds / f"web-{label}.log").write_text(log)
            if result.returncode or re.search(r"(?:^|\n)(?:SCRIPT )?ERROR:", log):
                raise RuntimeError(f"Godot {label} failed. See builds/web-{label}.log. Install matching templates if missing.\n" + log[-2500:])
        for suffix in ("html", "js", "wasm", "pck"):
            if not (stage / f"index.{suffix}").is_file():
                raise RuntimeError("Incomplete web export: missing index." + suffix)
        if source_hash != fingerprint():
            raise RuntimeError("Sources changed during export. Retry to build one consistent revision.")
        stamp = {"schema": 1, "milestone": "M33", "engine": version, "source_sha256": source_hash,
                 "built_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                 "threaded": False, "multiplayer": "offline; transport probe separate"}
        (stage / STAMP).write_text(json.dumps(stamp, indent=2) + "\n")
        WEB.mkdir(exist_ok=True)
        for path in stage.iterdir():
            if path.is_file() and path.name != STAMP:
                os.replace(path, WEB / path.name)
        # Publish the stamp last; active clients reload only after all files exist.
        os.replace(stage / STAMP, WEB / STAMP)
    print(f"BUILD READY: {version} / {source_hash[:12]}", flush=True)
    return stamp


class PreviewHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      ".wasm": "application/wasm", ".pck": "application/octet-stream",
                      ".js": "text/javascript", ".json": "application/json"}

    def __init__(self, *args, directory=WEB, **kwargs):
        super().__init__(*args, directory=str(directory), **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        super().end_headers()

    def list_directory(self, path):
        self.send_error(404, "Directory listing disabled")
        return None

    def send_head(self):
        decoded = urllib.parse.unquote(urllib.parse.urlsplit(self.path).path)
        parts = decoded.replace("\\", "/").split("/")
        if any(part.startswith(".") for part in parts if part):
            self.send_error(404)
            return None
        target = Path(self.translate_path(self.path)).resolve()
        directory = Path(self.directory).resolve()
        if target != directory and directory not in target.parents:
            self.send_error(404)
            return None
        return super().send_head()

    def do_GET(self):
        if urllib.parse.urlsplit(self.path).path == "/__preview__/status":
            payload = json.dumps(read_stamp(Path(self.directory))).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        super().do_GET()


def watch_sources(engine: str, stop: threading.Event):
    previous = fingerprint()
    while not stop.wait(2):
        current = fingerprint()
        if current == previous:
            continue
        previous = current
        try:
            print("Source changed; rebuilding...", flush=True)
            build_web(engine)
        except (OSError, RuntimeError, subprocess.SubprocessError) as exc:
            print(f"BUILD FAILED; previous preview retained: {exc}", file=sys.stderr, flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", help="Godot executable (or set GODOT_BIN)")
    parser.add_argument("--port", type=int, default=8077)
    parser.add_argument("--lan", action="store_true", help="Expose exported game to the trusted local network")
    parser.add_argument("--watch", action="store_true", help="Rebuild on source changes, then reload browser")
    parser.add_argument("--rebuild", action="store_true")
    parser.add_argument("--build-only", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--open", action="store_true")
    args = parser.parse_args()
    if not 1 <= args.port <= 65535:
        parser.error("port must be between 1 and 65535")
    try:
        stamp = read_stamp()
        current = fingerprint()
        ready = all((WEB / f"index.{suffix}").is_file() for suffix in ("html", "js", "wasm", "pck"))
        ready = ready and stamp.get("source_sha256") == current
        if args.doctor:
            print(json.dumps({"python": sys.version.split()[0], "web_build_current": ready,
                              "build": stamp, "exports": ["Web", "Android", "iOS", "Windows Desktop", "macOS", "Linux"]}, indent=2))
            try:
                print("Godot:", engine_version(find_godot(args.godot)))
            except RuntimeError as exc:
                print(str(exc))
            return 0 if ready else 1
        engine = find_godot(args.godot) if args.watch or args.rebuild or not ready else None
        if args.rebuild or not ready:
            build_web(engine)
        if args.build_only:
            return 0
        host = "0.0.0.0" if args.lan else "127.0.0.1"
        server = http.server.ThreadingHTTPServer((host, args.port), PreviewHandler)
        stop = threading.Event()
        if args.watch:
            threading.Thread(target=watch_sources, args=(engine, stop), daemon=True).start()
        url = f"http://localhost:{args.port}/"
        print(f"PREVIEW READY: {url}\nOnly builds/web is served. Ctrl+C stops the server.", flush=True)
        if args.lan:
            addresses = sorted({item[4][0] for item in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET)})
            for address in addresses:
                print(f"LAN candidate: http://{address}:{args.port}/ (same Wi-Fi; check host firewall)", flush=True)
            print("LAN mode has no authentication. Do not expose this dev server publicly. Use an authenticated HTTPS proxy for remote access.", flush=True)
        if args.open:
            webbrowser.open(url)
        try:
            server.serve_forever(poll_interval=0.25)
        except KeyboardInterrupt:
            pass
        finally:
            stop.set()
            server.server_close()
        return 0
    except (OSError, RuntimeError, subprocess.SubprocessError) as exc:
        print(f"PREVIEW NOT STARTED: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
