#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def load(name): return json.loads((ROOT / "data" / name).read_text(encoding="utf-8"))
def require(value, message):
    if not value: raise AssertionError(message)

for path in ROOT.rglob("*.json"):
    json.loads(path.read_text(encoding="utf-8"))

identity = load("release_identity.json")
visual = load("m150_p1_regional_visual_acceptance.json")
ships = load("m150_master_ship_progression_guard.json")
types = load("admin_content_type_registry.json")
modules = load("m143_unified_admin_modules.json")
rbac = load("admin_rbac_contract.json")
preserve = load("m143_gameplay_visual_polish.json")["preserve"]
require(identity["client_version"] == "0.150.0" and identity["build_number"] == 150, "release identity not M150")
require(set(visual["regions"]) == {"crimson_sea","drowned_reach"}, "regional profiles incomplete")
materials = [path for row in visual["regions"].values() for path in row["materials"].values()]
require(len(materials) == 8 and all((ROOT / path.removeprefix("res://")).is_file() for path in materials), "material placeholders incomplete")
require((ROOT / visual["acceptance"]["qa_scene"].removeprefix("res://")).is_file(), "QA scene missing")
require(ships["starter_ships"]["count"] == 3 and ships["regular_ship_classes"]["count"] == 100 and ships["prestige_ship_classes"]["count"] == 5, "binding ship progression incomplete")
rules = " ".join(ships["design_rules"]).lower()
require("not one recolor chain" in rules and "hulls" in rules and "mast/sail" in rules, "silhouette diversity guard incomplete")
bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
world = (ROOT / "scripts/world/world_map_system.gd").read_text(encoding="utf-8")
dressing = (ROOT / "scripts/world/world_dressing_composer.gd").read_text(encoding="utf-8")
adapter = (ROOT / "scripts/visual/p1_regional_presentation_adapter.gd").read_text(encoding="utf-8")
water = (ROOT / "scripts/visual/water_surface.gd").read_text(encoding="utf-8")
overlay = (ROOT / "scripts/admin/admin_overlay.gd").read_text(encoding="utf-8")
require("P1RegionalVisualAcceptanceCatalog.new()" in bootstrap and "P1RegionalEnvironmentController.new()" in bootstrap, "M150 services not bootstrapped")
require("apply_region" in world and "apply_world_asset" in world and "apply_world_asset" in dressing, "regional world wiring incomplete")
require('get_meta("classification"' in adapter and "ORIGINAL_PLACEHOLDER_NOT_UNITY" in adapter, "replacement protection missing")
require("apply_region_profile" in water and "regional_water_surface" in water, "regional water wiring missing")
require("M150 ADMIN COMMAND" in overlay and "M150 Visuals" in overlay, "Admin M150 visibility missing")
require(len(types["content_types"]) == 27 and len(modules["modules"]) == 18 and len(rbac["permissions"]) == 59, "admin coverage regressed")
for key in ("cannons","ammo","cannonballs","ships","badges","logos","settings","mobile_controls","asset_slots"):
    require(key in preserve, f"preservation lock missing: {key}")
print("M150_CHECK_PASS")
print(f"json_files={sum(1 for _ in ROOT.rglob('*.json'))} regional_profiles=2 materials=8")
print(f"ship_direction=3_starters+100_regular+5_prestige content_types={len(types['content_types'])} admin_modules={len(modules['modules'])} rbac_permissions={len(rbac['permissions'])}")
