#!/usr/bin/env python3
"""Fetch matching single-thread official Godot 4.7.2 Web templates (remotezip required)."""
from pathlib import Path
from remotezip import RemoteZip

URL = "https://godot-releases.nbg1.your-objectstorage.com/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
destination = Path.home() / ".local/share/godot/export_templates/4.7.2.stable"
destination.mkdir(parents=True, exist_ok=True)
with RemoteZip(URL) as archive:
    for name in ["web_nothreads_debug.zip", "web_nothreads_release.zip", "version.txt"]:
        member = next(n for n in archive.namelist() if n.endswith("/" + name))
        (destination / name).write_bytes(archive.read(member))
        print("Installed", name, flush=True)
