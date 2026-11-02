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
wave = data("m146_p0_asset_swap_manifest.json")
polish = data("m146_visual_polish_profiles.json")
types = data("admin_content_type_registry.json")
modules = data("m143_unified_admin_modules.json")
rbac = data("admin_rbac_contract.json")
preserve = data("m143_gameplay_visual_polish.json")["preserve"]
visual_manifest = json.loads((ROOT / "assets/placeholder_pack/manifest.json").read_text(encoding="utf-8"))["assets"]

require(identity["client_version"] == "0.146.0" and identity["build_number"] == 146, "release identity not M146")
require(wave["master"] == "V3.7" and wave["production_wave"] == "P0_VERTICAL_SLICE", "wrong production wave")
require(len(wave["slots"]) == 14, "all fourteen P0 GLB slots are required")
require(len({row["master_slot"] for row in wave["slots"]}) == 14, "master slots must be unique")
require(len({row["runtime_id"] for row in wave["slots"]}) == 14, "runtime IDs must be unique")
require(len({row["file"] for row in wave["slots"]}) == 14, "each slot needs its own file")

root = wave["replacement_root"].replace("res://", "")
for row in wave["slots"]:
    path = ROOT / root / row["file"]
    require(path.is_file(), f"missing dedicated GLB: {row['runtime_id']}")
    require(path.read_bytes()[:4] == b"glTF", f"invalid GLB magic: {row['runtime_id']}")
    require(visual_manifest[row["runtime_id"]]["path"] == "res://" + str(path.relative_to(ROOT)).replace("\\", "/"), f"catalog mismatch: {row['runtime_id']}")

require(polish["mobile"]["lod_bias_cap"] < polish["desktop"]["lod_bias_cap"], "mobile LOD must be stricter")
require(polish["web_preview"]["vfx_density"] < polish["mobile"]["vfx_density"], "Web preview must be lighter than mobile")
require(len(types["content_types"]) == 27 and len(modules["modules"]) == 18 and len(rbac["permissions"]) == 59, "admin coverage regressed")
for key in ("cannons", "ammo", "cannonballs", "ships", "badges", "logos", "settings", "mobile_controls", "asset_slots"):
    require(key in preserve, f"preservation lock missing: {key}")

project = (ROOT / "project.godot").read_text(encoding="utf-8")
exports = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
library = (ROOT / "scripts/visual/asset_visual_library.gd").read_text(encoding="utf-8")
overlay = (ROOT / "scripts/admin/admin_overlay.gd").read_text(encoding="utf-8")
require('config/version="0.146.0"' in project and "version/code=146" in exports, "platform versions not M146")
require("P0AssetSwapService.new()" in bootstrap, "P0 asset service not bootstrapped")
require("P0VisualPolish.apply" in library, "runtime polish not applied")
require("P0 ASSET PRODUCTION · M146" in overlay, "admin P0 status missing")

print("M146_CHECK_PASS")
print(f"json_files={sum(1 for _ in ROOT.rglob('*.json'))}")
print("dedicated_p0_glb=14")
print(f"content_types={len(types['content_types'])}")
print(f"admin_modules={len(modules['modules'])}")
print(f"rbac_permissions={len(rbac['permissions'])}")
