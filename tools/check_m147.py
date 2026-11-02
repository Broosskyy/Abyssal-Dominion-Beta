#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def data(name):
    return json.loads((ROOT / "data" / name).read_text(encoding="utf-8"))

def require(value, message):
    if not value:
        raise AssertionError(message)

for path in ROOT.rglob("*.json"):
    json.loads(path.read_text(encoding="utf-8"))

identity = data("release_identity.json")
waves = data("m147_p1_p4_production_waves.json")
p0 = data("m146_p0_asset_swap_manifest.json")
types = data("admin_content_type_registry.json")
modules = data("m143_unified_admin_modules.json")
rbac = data("admin_rbac_contract.json")
preserve = data("m143_gameplay_visual_polish.json")["preserve"]

require(identity["client_version"] == "0.147.0" and identity["build_number"] == 147, "release identity not M147")
require(waves["master"] == "V3.7", "master alignment missing")
expected = {"P1": (1,10), "P2": (11,30), "P3": (31,40), "P4": (41,50)}
covered = set()
for wave, bounds in expected.items():
    require(tuple(waves["waves"][wave]["main_ship_range"]) == bounds, f"wrong {wave} range")
    covered.update(range(bounds[0], bounds[1] + 1))
require(covered == set(range(1,51)), "P1-P4 must cover all 50 main designs exactly")
require(waves["waves"]["P4"]["master_priority"] == "P3", "P4 must remain a technical P3 endgame subwave")
require(len(waves["active_glb_slots"]) == 10, "first P1 batch must contain ten GLBs")
require(len({row["id"] for row in waves["active_glb_slots"]}) == 10, "P1 IDs must be unique")
require(len(p0["slots"]) == 14, "P0 must remain intact")

root = ROOT / "assets/production_placeholders/p1"
for row in waves["active_glb_slots"]:
    path = root / row["file"]
    require(path.is_file() and path.read_bytes()[:4] == b"glTF", f"invalid P1 GLB: {row['id']}")
for folder in ("p2", "p3", "p4", "p_event"):
    require((ROOT / "assets/production_placeholders" / folder).is_dir(), f"missing reserved folder: {folder}")

rules = " ".join(waves["global_rules"])
require("Ship Mastery" in rules and "no baked water" in rules and "Mobile oblique top-down" in rules, "production rules incomplete")
require(waves["parallel_event_wave"]["id"] == "P-EVENT", "event wave must stay separate")
require(len(types["content_types"]) == 27 and len(modules["modules"]) == 18 and len(rbac["permissions"]) == 59, "admin coverage regressed")
for key in ("cannons", "ammo", "cannonballs", "ships", "badges", "logos", "settings", "mobile_controls", "asset_slots"):
    require(key in preserve, f"preservation lock missing: {key}")

project = (ROOT / "project.godot").read_text(encoding="utf-8")
exports = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
visuals = (ROOT / "scripts/visual/asset_visual_library.gd").read_text(encoding="utf-8")
overlay = (ROOT / "scripts/admin/admin_overlay.gd").read_text(encoding="utf-8")
require('config/version="0.147.0"' in project and "version/code=147" in exports, "platform versions not M147")
require("ProductionWaveCatalog.new()" in bootstrap, "production catalog not bootstrapped")
require("ProductionWaveCatalog.entry" in visuals, "P1 slot fallback not connected")
require("P1–P4 PRODUCTION WAVES · M147" in overlay, "admin production status missing")

print("M147_CHECK_PASS")
print(f"json_files={sum(1 for _ in ROOT.rglob('*.json'))}")
print("p0_glb=14")
print("p1_glb=10")
print("p2_p4_reserved=40")
print(f"content_types={len(types['content_types'])}")
print(f"admin_modules={len(modules['modules'])}")
print(f"rbac_permissions={len(rbac['permissions'])}")
