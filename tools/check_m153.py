#!/usr/bin/env python3
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def load(name):
    return json.loads((ROOT / "data" / name).read_text(encoding="utf-8"))

def require(value, message):
    if not value:
        raise AssertionError(message)

for path in ROOT.rglob("*.json"):
    json.loads(path.read_text(encoding="utf-8"))

identity = load("release_identity.json")
batch = load("m153_w5_lod_batch.json")
guard = load("m150_master_ship_progression_guard.json")
types = load("admin_content_type_registry.json")

require(identity["milestone"] == "M153" and identity["client_version"] == "0.153.0" and identity["build_number"] == 153, "release identity not M153")
require(identity["master_concept"] == "V3.8", "master concept regressed")
require(batch["range"] == [51,60] and len(batch["ships"]) == 10, "W5 range incomplete")
require(len(batch["socket_contract"]) >= 10, "socket contract incomplete")
require(guard["starter_ships"]["count"] == 3 and guard["regular_ship_classes"]["count"] == 100, "binding progression regressed")
require(len(types["content_types"]) == 30, "Admin content coverage regressed")

hashes = set(); total_bytes = 0
for row in batch["ships"]:
    ship_id = row["id"]
    paths = [
        ROOT / "assets/production_placeholders/late_fleet/w5" / f"{ship_id}.glb",
        ROOT / "assets/production_placeholders/late_fleet/w5" / f"{ship_id}_lod1.glb",
        ROOT / "assets/production_placeholders/late_fleet/w5" / f"{ship_id}_lod2.glb",
    ]
    for path in paths:
        raw = path.read_bytes()
        magic, version, length = struct.unpack("<4sII", raw[:12])
        require(magic == b"glTF" and version == 2 and length == len(raw), f"invalid GLB: {path.name}")
        hashes.add(hashlib.sha256(raw).hexdigest()); total_bytes += len(raw)
require(len(hashes) == 30, "LOD/class files are byte duplicates")

architecture = (ROOT / "scripts/visual/ship_production_architecture.gd").read_text(encoding="utf-8")
library = (ROOT / "scripts/visual/asset_visual_library.gd").read_text(encoding="utf-8")
bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
overlay = (ROOT / "scripts/admin/admin_overlay.gd").read_text(encoding="utf-8")
require("W5ProductionBatch.entry" in architecture and "production_glb_placeholders" in architecture, "W5 architecture merge missing")
require("M153_W5_CLEAN_ROOM_GLB_PLACEHOLDER" in library and "counts_as_final_glb" in library, "honest placeholder classification missing")
require("W5ProductionBatch.new()" in bootstrap, "W5 batch not bootstrapped")
require("M153 W5" in overlay and "LOD-Sets" in overlay, "Admin W5 status missing")
require((ROOT / "scenes/qa/m153_w5_lod_qa.tscn").is_file(), "M153 QA scene missing")

print("M153_CHECK_PASS")
print(f"w5_ships=10 glbs=30 unique_hashes={len(hashes)} bytes={total_bytes} sockets={len(batch['socket_contract'])}")
print("classification=clean_room_placeholder_not_final_art ship_direction=3/100/P1-P5")
