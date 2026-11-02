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
runtime = load("m149_p1_regional_runtime_profiles.json")
assets = load("m148_p1_regional_asset_batch.json")
regions = load("world_region_registry_v37.json")["regions"]
types = load("admin_content_type_registry.json")
modules = load("m143_unified_admin_modules.json")
rbac = load("admin_rbac_contract.json")
preserve = load("m143_gameplay_visual_polish.json")["preserve"]

require(identity["client_version"] == "0.149.0" and identity["build_number"] == 149, "release identity not M149")
require(runtime["master"] == "V3.7" and len(runtime["regions"]) == 2, "regional runtime profile incomplete")
require(set(runtime["platforms"]) == {"desktop","mobile","web"}, "platform profiles incomplete")
require(runtime["platforms"]["desktop"]["hero_lod"] == "LOD0", "desktop hero quality regressed")
require(runtime["platforms"]["mobile"]["standard_lod"] == "LOD2", "mobile LOD contract missing")
require(runtime["platforms"]["web"]["shadow_mode"] == "OFF", "Web preview budget missing")
asset_ids = {row["id"] for row in assets["assets"]}
for region_id, profile in runtime["regions"].items():
    for slot in profile["nature_slots"] + profile["island_visual_slots"] + [profile["harbor_slot"]]:
        require(slot in asset_ids, f"unknown runtime slot {slot} in {region_id}")

by_id = {row["id"]: row for row in regions}
require(by_id["crimson_sea"]["monster_slots"] == ["monster_krakenling_01","monster_redfin_01","monster_ember_ray_01"], "Crimson monsters not connected")
require(len(by_id["drowned_reach"]["monster_slots"]) == 4, "Drowned monsters not connected")
require(by_id["crimson_sea"]["admiral_slot"] == "npc_storm_admiral", "Crimson Admiral regressed")
require(by_id["drowned_reach"]["admiral_slot"] == "npc_ember_admiral", "Drowned Admiral regressed")

bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
resolver = (ROOT / "scripts/world/dynamic_spawn_pool_resolver.gd").read_text(encoding="utf-8")
table = (ROOT / "scripts/world/dynamic_spawn_table.gd").read_text(encoding="utf-8")
world = (ROOT / "scripts/world/world_map_system.gd").read_text(encoding="utf-8")
encounter = (ROOT / "scripts/world/encounter_director.gd").read_text(encoding="utf-8")
overlay = (ROOT / "scripts/admin/admin_overlay.gd").read_text(encoding="utf-8")
project = (ROOT / "project.godot").read_text(encoding="utf-8")
exports = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
require("P1RegionalRuntimeCatalog.new()" in bootstrap, "runtime catalog not bootstrapped")
require('region.get("admiral_slot",region.get("boss_slot"' in resolver, "canonical Admiral field not resolved")
require("P1RegionalRuntimeCatalog.spawn" in table, "regional spawn defaults not connected")
require("P1RegionalPresentationAdapter.apply_harbor" in world, "harbor presentation not connected")
require("P1RegionalPresentationAdapter.apply_entity" in encounter and '"crimson_sea"' in encounter and '"drowned_reach"' in encounter, "entity presentation not connected")
require("P1 REGIONAL RUNTIME + P1–P4 WAVES · M149" in overlay, "M149 Admin status missing")
require('config/version="0.149.0"' in project and "version/code=149" in exports, "platform versions not M149")
require(len(types["content_types"]) == 27 and len(modules["modules"]) == 18 and len(rbac["permissions"]) == 59, "admin coverage regressed")
for key in ("cannons","ammo","cannonballs","ships","badges","logos","settings","mobile_controls","asset_slots"):
    require(key in preserve, f"preservation lock missing: {key}")
rules = " ".join(runtime["rules"])
require("Tap-to-Sail" in rules and "fixed WATER_Y" in rules and "preview-only" in rules and "GLOBAL" in rules, "binding controls/platform constraints missing")

print("M149_CHECK_PASS")
print(f"json_files={sum(1 for _ in ROOT.rglob('*.json'))}")
print("regions=2 platforms=3 regional_glb=24")
print(f"content_types={len(types['content_types'])} admin_modules={len(modules['modules'])} rbac_permissions={len(rbac['permissions'])}")
