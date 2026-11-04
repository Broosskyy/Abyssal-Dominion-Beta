#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def load(name): return json.loads((ROOT / "data" / name).read_text(encoding="utf-8"))
def require(value, message):
    if not value: raise AssertionError(message)

for path in ROOT.rglob("*.json"): json.loads(path.read_text(encoding="utf-8"))
identity = load("release_identity.json")
architecture = load("m151_late_fleet_production_architecture.json")
guard = load("m150_master_ship_progression_guard.json")
types = load("admin_content_type_registry.json")
modules = load("m143_unified_admin_modules.json")
rbac = load("admin_rbac_contract.json")
preserve = load("m143_gameplay_visual_polish.json")["preserve"]
require(identity["client_version"] == "0.151.0" and identity["build_number"] == 151, "release identity not M151")
require(architecture["regular"]["range"] == [51,100] and architecture["regular"]["count"] == 50, "regular late fleet incomplete")
require(len(architecture["families"]) == 10 and all(f["range"][1]-f["range"][0] == 4 for f in architecture["families"]), "ten five-class families required")
require(len(architecture["prestige"]["classes"]) == 5 and [r["rank"] for r in architecture["prestige"]["classes"]] == ["P1","P2","P3","P4","P5"], "Prestige slots incomplete")
require(guard["starter_ships"]["count"] == 3 and guard["regular_ship_classes"]["count"] == 100, "binding progression regressed")
rules = " ".join(architecture["rules"]).lower()
require("separate from regular" in rules and "recolor-only" in rules and "never baked" in rules and "server authority" in rules, "production guardrails incomplete")
for wave in architecture["waves"]:
    require((ROOT / wave["root"].removeprefix("res://") / ".keep.md").is_file(), f"missing replacement root {wave['id']}")
require((ROOT / architecture["prestige"]["root"].removeprefix("res://") / ".keep.md").is_file(), "Prestige replacement root missing")
require((ROOT / architecture["qa_scene"].removeprefix("res://")).is_file(), "M151 QA scene missing")
bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
library = (ROOT / "scripts/visual/asset_visual_library.gd").read_text(encoding="utf-8")
fleet = (ROOT / "scripts/progression/main_progression_fleet.gd").read_text(encoding="utf-8")
overlay = (ROOT / "scripts/admin/admin_overlay.gd").read_text(encoding="utf-8")
require("ShipProductionArchitecture.new()" in bootstrap, "M151 catalog not bootstrapped")
require("LateFleetSilhouetteFactory.create" in library and "counts_as_final_glb" in library, "honest runtime fallback not wired")
require("ShipProductionArchitecture.progression_design" in fleet and "prestige_design" in fleet, "progression expansion not connected")
require("M151 ADMIN COMMAND" in overlay and "Prestige" in overlay and "Fallback" in overlay, "Admin production status missing")
ship_schema = types["content_types"]["ship"]
for field in ("asset_slot","lod0_path","lod1_path","lod2_path","silhouette_profile","production_priority","import_status"):
    require(field in ship_schema["fields"], f"Admin ship field missing: {field}")
require(len(types["content_types"]) == 27 and len(modules["modules"]) == 18 and len(rbac["permissions"]) == 59, "admin coverage regressed")
for key in ("cannons","ammo","cannonballs","ships","badges","logos","settings","mobile_controls","asset_slots"):
    require(key in preserve, f"preservation lock missing: {key}")
print("M151_CHECK_PASS")
print(f"json_files={sum(1 for _ in ROOT.rglob('*.json'))} regular_slots=50 prestige_slots=5 silhouette_families=10")
print(f"admin=27_types/18_modules/59_permissions global_locked={architecture['admin']['global_locked']}")
