#!/usr/bin/env python3
import json
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
batch = load("m148_p1_regional_asset_batch.json")
waves = load("m147_p1_p4_production_waves.json")
types = load("admin_content_type_registry.json")
modules = load("m143_unified_admin_modules.json")
rbac = load("admin_rbac_contract.json")
preserve = load("m143_gameplay_visual_polish.json")["preserve"]

require(identity["client_version"] == "0.148.0" and identity["build_number"] == 148, "release identity not M148")
require(batch["master"] == "V3.7" and batch["production_wave"] == "W2_P1_REGIONAL", "master/wave mismatch")
require(batch["state"].endswith("NOT_LIVE"), "regional placeholders must not claim live art")
assets = batch["assets"]
require(len(assets) == 24, "M148 must contain 24 regional swap targets")
require(len({row["id"] for row in assets}) == len(assets), "runtime IDs must be unique")
require(len({row["master_slot"] for row in assets}) == len(assets), "master slots must be unique")
require(len({row["file"] for row in assets}) == len(assets), "GLB paths must be unique")

counts = {}
root = ROOT / "assets/production_placeholders/p1/regional"
for row in assets:
    counts[row["family"]] = counts.get(row["family"], 0) + 1
    path = root / row["file"]
    require(path.is_file() and path.read_bytes()[:4] == b"glTF", f"invalid regional GLB: {row['id']}")
require(counts == {"ship":9,"monster":7,"flora":4,"island_module":2,"harbor":2}, f"wrong family counts: {counts}")
require(batch["regions"]["crimson_sea"]["levels"] == [6,10], "Crimson level band regressed")
require(batch["regions"]["drowned_reach"]["levels"] == [11,15], "Drowned level band regressed")
rules = " ".join(batch["replacement_contract"]["rules"])
require("no baked water" in rules and "Godot effects" in rules and "not mean final art" in rules, "replacement boundary incomplete")
require(len(waves["active_glb_slots"]) == 10, "M147 main ship batch regressed")
require(len(types["content_types"]) == 27 and len(modules["modules"]) == 18 and len(rbac["permissions"]) == 59, "admin coverage regressed")
for key in ("cannons","ammo","cannonballs","ships","badges","logos","settings","mobile_controls","asset_slots"):
    require(key in preserve, f"preservation lock missing: {key}")

project = (ROOT / "project.godot").read_text(encoding="utf-8")
exports = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
visuals = (ROOT / "scripts/visual/asset_visual_library.gd").read_text(encoding="utf-8")
overlay = (ROOT / "scripts/admin/admin_overlay.gd").read_text(encoding="utf-8")
require('config/version="0.148.0"' in project and "version/code=148" in exports, "platform versions not M148")
require("P1RegionalAssetCatalog.new()" in bootstrap and "P1RegionalAssetCatalog.entry" in visuals, "regional lookup not connected")
require("P1 REGIONALBATCH + P1–P4 WAVES · M148" in overlay, "admin regional readiness missing")

print("M148_CHECK_PASS")
print(f"json_files={sum(1 for _ in ROOT.rglob('*.json'))}")
print("regional_glb=24 (ships=9 monsters=7 flora=4 islands=2 harbors=2)")
print(f"content_types={len(types['content_types'])} admin_modules={len(modules['modules'])} rbac_permissions={len(rbac['permissions'])}")
